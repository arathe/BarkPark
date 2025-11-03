#!/usr/bin/env bash

# BarkPark: Start local backend services (DB + API)
# - Ensures .env exists (defaults to PORT=4000)
# - Optionally starts a Postgres 17 + PostGIS 3.5 container if DB is unreachable
# - Runs DB migrations
# - Starts the API with nodemon

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${SCRIPT_DIR}/.."
cd "$BACKEND_DIR"

USE_DOCKER_DB=${USE_DOCKER_DB:-auto} # auto|true|false
# Docker image and platform settings (override via env)
DB_IMAGE=${DB_IMAGE:-postgis/postgis:17-3.5}
DB_IMAGE_PLATFORM=${DB_IMAGE_PLATFORM:-}
RUN_MIGRATIONS=${RUN_MIGRATIONS:-true}

log() { printf "\033[1;34m[local]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[err ]\033[0m %s\n" "$*"; }

if [[ ! -f .env ]]; then
  log "No .env found. Creating from .env.example"
  cp -n .env.example .env || true
  warn "Review backend/.env and set DB_PASSWORD, JWT_SECRET, etc."
fi

# Export env vars for child processes
set -a
source .env
set +a

# Defaults
PORT=${PORT:-4000}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-barkpark}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-}

# Ensure node modules are installed
if [[ ! -d node_modules ]]; then
  log "Installing backend dependencies (npm install)"
  npm install --silent
fi

check_db() {
  node -e '
    const { Client } = require("pg");
    const url = process.env.DATABASE_URL;
    const config = url ? { connectionString: url, ssl: false } : {
      host: process.env.DB_HOST || "localhost",
      port: +(process.env.DB_PORT || 5432),
      database: process.env.DB_NAME || "barkpark",
      user: process.env.DB_USER || "postgres",
      password: process.env.DB_PASSWORD || undefined,
    };
    const c = new Client(config);
    c.connect().then(() => c.query("select 1")).then(() => {
      console.log("ok");
      return c.end();
    }).catch(e => { console.error(e.message); process.exit(2); });
  ' >/dev/null 2>&1 && return 0 || return 1
}

is_port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"${port}" -sTCP:LISTEN -n -P >/dev/null 2>&1 && return 0 || return 1
  elif command -v netstat >/dev/null 2>&1; then
    netstat -an | grep -E "\.(${port})\s+.*LISTEN" >/dev/null 2>&1 && return 0 || return 1
  else
    # Fallback: try to open a socket with bash (best effort)
    (echo > /dev/tcp/127.0.0.1/${port}) >/dev/null 2>&1 && return 0 || return 1
  fi
}

find_free_port() {
  local start_port="$1"
  local max_delta=20
  local p
  for ((i=0; i<=max_delta; i++)); do
    p=$((start_port + i))
    if ! is_port_in_use "$p"; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

maybe_start_docker_db() {
  # Only start if docker is available and DB connection fails
  if ! command -v docker >/dev/null 2>&1; then
    warn "Docker not found; cannot auto-start Postgres container."
    return
  fi

  # If desired host port is busy, pick a free one and export DB_PORT accordingly
  if is_port_in_use "${DB_PORT}"; then
    local new_port
    new_port=$(find_free_port "${DB_PORT}") || {
      err "Could not find a free port starting from ${DB_PORT}"
      exit 1
    }
    if [[ "${new_port}" != "${DB_PORT}" ]]; then
      warn "Host port ${DB_PORT} in use; switching to ${new_port} for Docker Postgres"
      export DB_PORT="${new_port}"
    fi
  fi

  local container_name="barkpark-db-${DB_PORT}"
  local volume_name="barkpark-pgdata-${DB_PORT}"

  # Determine platform flag for Apple Silicon (arm64) if needed
  local DOCKER_PLATFORM_ARG=""
  local arch
  arch=$(uname -m || true)
  # Prefer Docker engine architecture when available
  local docker_arch
  docker_arch=$(docker version --format '{{.Server.Arch}}' 2>/dev/null || docker info --format '{{.Architecture}}' 2>/dev/null || echo "")
  if [[ -n "${DB_IMAGE_PLATFORM}" ]]; then
    DOCKER_PLATFORM_ARG="--platform ${DB_IMAGE_PLATFORM}"
  elif [[ "${docker_arch}" == "arm64" || "${docker_arch}" == "aarch64" || "${arch}" == "arm64" || "${arch}" == "aarch64" ]]; then
    # Many PostGIS tags lack native arm64 images; use amd64 emulation by default
    DOCKER_PLATFORM_ARG="--platform linux/amd64"
    warn "Detected Docker engine arch '${docker_arch:-$arch}'; using ${DOCKER_PLATFORM_ARG} for image compatibility."
    warn "You can override with DB_IMAGE_PLATFORM=linux/arm64 or DB_IMAGE to another multi-arch tag."
  fi

  if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
    log "Docker DB container already running: ${container_name}"
    return
  fi

  if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
    log "Starting existing Docker DB container: ${container_name}"
    docker start "${container_name}" >/dev/null
  else
    log "Creating Docker volume: ${volume_name}"
    docker volume create "${volume_name}" >/dev/null

    # Ensure the app uses the same password we pass to the container
    local CONT_DB_PASSWORD
    CONT_DB_PASSWORD="${DB_PASSWORD:-password}"
    export DB_PASSWORD="${CONT_DB_PASSWORD}"

    log "Starting Postgres container (${container_name}) with image ${DB_IMAGE} ${DOCKER_PLATFORM_ARG}"
    if ! docker run -d ${DOCKER_PLATFORM_ARG} \
      --name "${container_name}" \
      -e POSTGRES_USER="${DB_USER}" \
      -e POSTGRES_PASSWORD="${CONT_DB_PASSWORD}" \
      -e POSTGRES_DB="${DB_NAME}" \
      -p "${DB_PORT}:5432" \
      -v "${volume_name}:/var/lib/postgresql/data" \
      "${DB_IMAGE}" >/dev/null; then
      # Fallback: if platform flag didn't apply and we are on arm64, retry explicitly with linux/amd64
      if [[ -z "${DB_IMAGE_PLATFORM}" && ( "${docker_arch}" == "arm64" || "${docker_arch}" == "aarch64" || "${arch}" == "arm64" || "${arch}" == "aarch64" ) ]]; then
        warn "Initial docker run failed; retrying with --platform linux/amd64 explicitly."
        docker run -d --platform linux/amd64 \
          --name "${container_name}" \
          -e POSTGRES_USER="${DB_USER}" \
          -e POSTGRES_PASSWORD="${CONT_DB_PASSWORD}" \
          -e POSTGRES_DB="${DB_NAME}" \
          -p "${DB_PORT}:5432" \
          -v "${volume_name}:/var/lib/postgresql/data" \
          "${DB_IMAGE}" >/dev/null
      else
        err "Failed to start docker container ${container_name}. Try setting DB_IMAGE_PLATFORM=linux/amd64 or DB_IMAGE to a multi-arch PostGIS tag."
        exit 1
      fi
    fi
  fi

  log "Waiting for database to become ready..."
  for i in {1..60}; do
    if check_db; then
      log "Database is ready"
      return
    fi
    sleep 2
  done
  err "Database did not become ready in time"
  exit 1
}

log "Checking database connectivity (host=${DB_HOST} port=${DB_PORT} db=${DB_NAME})"
if check_db; then
  log "Database reachable"
else
  if [[ "${USE_DOCKER_DB}" == "true" || ( "${USE_DOCKER_DB}" == "auto" && "${DB_HOST}" == "localhost" ) ]]; then
    log "Database not reachable. Attempting to start Dockerized Postgres..."
    maybe_start_docker_db
  else
    err "Database not reachable and Docker autostart is disabled."
    echo "Hint: set USE_DOCKER_DB=true to auto-start a local container or fix DB settings in backend/.env"
    exit 2
  fi
fi

if [[ "${RUN_MIGRATIONS}" == "true" ]]; then
  log "Running database migrations"
  npm run db:migrate
else
  warn "Skipping migrations (RUN_MIGRATIONS=false)"
fi

log "Starting API on port ${PORT}"
exec npm run dev
