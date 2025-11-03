-- Migration: Ensure dog_parks has legacy latitude/longitude columns
-- Rollback (manual):
--   ALTER TABLE dog_parks DROP COLUMN IF EXISTS latitude;
--   ALTER TABLE dog_parks DROP COLUMN IF EXISTS longitude;

ALTER TABLE dog_parks
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Backfill scalar columns from authoritative PostGIS geography data
UPDATE dog_parks
SET latitude = ST_Y(location::geometry),
    longitude = ST_X(location::geometry)
WHERE location IS NOT NULL
  AND (latitude IS NULL OR longitude IS NULL);

-- Keep scalar values in sync when new rows are inserted without them
UPDATE dog_parks
SET latitude = ST_Y(location::geometry),
    longitude = ST_X(location::geometry)
WHERE location IS NOT NULL
  AND (latitude IS DISTINCT FROM ST_Y(location::geometry)
    OR longitude IS DISTINCT FROM ST_X(location::geometry));
