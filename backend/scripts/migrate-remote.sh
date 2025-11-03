#!/usr/bin/env bash
# Run unified migrations against a remote database using env vars from a file.
# Usage:
#   ./scripts/migrate-remote.sh [env-file] [--seed|--verify|--status|...]
# Defaults to using ../.env.staging if no env file is provided.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

# Determine env file path (default .env.staging relative to backend/)
ENV_FILE_RELATIVE=".env.staging"

if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
  ENV_FILE_RELATIVE="$1"
  shift
fi

ENV_FILE="$ENV_FILE_RELATIVE"
if [[ "$ENV_FILE" != /* ]]; then
  ENV_FILE="${PROJECT_ROOT}/${ENV_FILE_RELATIVE}"
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌  Env file not found: $ENV_FILE" >&2
  echo "    Create it (e.g., copy from backend/.env.staging.example) and add your remote DATABASE_URL." >&2
  exit 1
fi

echo "📄 Using environment file: $ENV_FILE"

# shellcheck disable=SC1090
set -a
source "$ENV_FILE"
set +a

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "❌  DATABASE_URL is not set after loading $ENV_FILE." >&2
  echo "    Add DATABASE_URL to the env file so the migration can connect to the remote DB." >&2
  exit 1
fi

echo "🚀 Running migrations via unified-migrate.js"
echo "   Target database: ${DATABASE_URL%%\?*}"

pushd "$PROJECT_ROOT" > /dev/null

node scripts/unified-migrate.js "$@"

echo ""
echo "🔍 Checking migration status"
node scripts/unified-migrate.js --status

popd > /dev/null

echo ""
echo "✅ Remote migration workflow complete"
