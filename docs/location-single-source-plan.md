# Location Single-Source Migration Plan

This plan documents the steps required to make `dog_parks.location` (PostGIS geography) the sole authoritative source for park coordinates while still serving `latitude`/`longitude` to clients that expect them. It builds on the earlier stabilization work and is sequenced so future Codex sessions can execute and track progress.

## Goals
- Drop the stored scalar `latitude`/`longitude` columns in favor of values generated from `location`.
- Ensure every code path that writes parks (models, scripts, tests) sets `location` explicitly.
- Keep API responses backward-compatible for the iOS client by continuing to emit `latitude`/`longitude`.
- Preserve support for environments that currently run without PostGIS (setup scripts, local dev).

## Prerequisites
1. Confirm PostGIS is available for the target database (development, staging, production).
2. Identify any environments that still rely on the non-PostGIS schema (`backend/scripts/setup-local-db.sh`) and decide whether to:
   - Enable PostGIS there as well, **or**
   - Maintain a compatibility path (e.g., views) that exposes `latitude`/`longitude` from `location`.

## Work Breakdown

### 1. Database Migration (Generated Columns)
- Create migration `013_convert_dog_parks_lat_lng.sql` that:
  1. Drops the existing scalar columns (if present).
  2. Recreates them as stored generated columns:
     ```sql
     ALTER TABLE dog_parks
       ADD COLUMN latitude DOUBLE PRECISION
         GENERATED ALWAYS AS (ST_Y(location::geometry)) STORED,
       ADD COLUMN longitude DOUBLE PRECISION
         GENERATED ALWAYS AS (ST_X(location::geometry)) STORED;
     ```
  3. Validates the generated values with a quick `SELECT` in the migration notes.
- Document rollback steps (e.g., recreate real columns and backfill from `location`).

### 2. Update Park Creation/Update Code
- In `backend/models/DogPark.js` (and `DogParkCompat`), ensure inserts/updates only set `location` using `ST_MakePoint`. Remove direct column references to `latitude`/`longitude`.
- Adjust any raw SQL helpers or repositories that still specify the scalar columns.

### 3. Script & Seed Updates
- Audit scripts under `backend/scripts/` (imports, migrations, local setup) and change any `INSERT ... latitude, longitude ...` statements to use `ST_MakePoint`.
- If `setup-local-db.sh` continues to serve environments without PostGIS, either:
  - Enable PostGIS in that script; or
  - Replace the physical table in that script with a compat layer (table + view) that mimics generated columns.

### 4. Test Fixture Refactor
- Update tests that seed parks via raw SQL (e.g., `tests/models/checkin.test.js`, `tests/routes/checkins.test.js`, `tests/posts.test.js`) to call a helper that sets `location`.
- Introduce/expand a shared factory (e.g., in `tests/utils/testDataFactory`) for creating parks so future tests stay PostGIS-aware.

### 5. API Response Contract
- Verify the serializers (e.g., `DogPark.formatPark`, route responses) read `latitude`/`longitude` from the row returned by Postgres. With generated columns in place, the JSON should remain unchanged.
- Add regression tests if necessary to ensure the REST responses always include the scalar fields.

### 6. Clean-Up & Verification
- Run migrations on development and test databases (`npm run db:migrate`, followed by `DB_NAME=barkpark_test DB_PASSWORD=… npm run db:migrate`).
- Execute the full Jest suite to confirm park-related tests pass without the legacy columns.
- Smoke-test the iOS app (or curl the relevant endpoints) to confirm `latitude`/`longitude` still appear in responses.
- Update documentation (README or `POSTGIS_MIGRATION_GUIDE.md`) to reflect the new single-source-of-truth approach.

## Deliverables
- Migration file `013_convert_dog_parks_lat_lng.sql`.
- Updated backend models, scripts, and tests that no longer insert scalar coordinates directly.
- Passing Jest suite against both dev and test databases.
- Documentation updates describing the new column behavior and any environment-specific caveats.

## Follow-Up (Optional)
- Consider exposing GeoJSON in API responses (while keeping scalars) for future client work.
- Evaluate adding database constraints/tests that ensure all parks have valid coordinate data now that `location` is authoritative.
