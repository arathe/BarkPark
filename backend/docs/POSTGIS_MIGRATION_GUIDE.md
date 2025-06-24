# PostGIS Migration Guide

This guide explains how to handle schema differences between PostGIS and traditional lat/lng implementations in the BarkPark application.

## Overview

BarkPark has migrated from using separate `latitude` and `longitude` columns to using PostGIS `GEOGRAPHY(POINT, 4326)` for better spatial query performance. However, you may encounter environments with different implementations.

## Schema Comparison Tools

### 1. Enhanced Schema Comparison API

The enhanced `/api/schema/compare` endpoint now detects and normalizes PostGIS differences:

```bash
# Compare current environment with production
curl http://localhost:3001/api/schema/compare

# Compare specific environments
curl -X POST http://localhost:3001/api/schema/compare/environments \
  -H "Content-Type: application/json" \
  -d '{
    "env1": {
      "name": "Local",
      "connectionString": "postgresql://localhost/barkpark_dev"
    },
    "env2": {
      "name": "Production",
      "connectionString": "postgresql://..."
    }
  }'
```

### 2. Schema Sync CLI Tool

The new `db:schema:sync` command compares schemas and generates migration SQL:

```bash
# Basic comparison (local vs production)
npm run db:schema:sync

# Verbose output with detailed differences
npm run db:schema:sync:verbose

# Compare different environments
npm run db:schema:sync -- --source=production --target=local

# Save migration SQL to file
npm run db:schema:sync -- --output=migrate-to-postgis.sql
```

## Understanding Location Column Differences

### PostGIS Implementation
- Single `location` column of type `GEOGRAPHY(POINT, 4326)`
- Stores longitude and latitude as a geographic point
- Enables spatial queries and indexes
- Better performance for location-based searches

### Traditional Implementation
- Separate `latitude` and `longitude` columns (DOUBLE PRECISION)
- Simple numeric storage
- Requires manual distance calculations
- Less efficient for spatial queries

## Migration Scenarios

### Scenario 1: Migrating from lat/lng to PostGIS

```sql
-- 1. Add PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Add location column
ALTER TABLE dog_parks ADD COLUMN location GEOGRAPHY(POINT, 4326);

-- 3. Populate location from existing lat/lng
UPDATE dog_parks 
SET location = ST_MakePoint(longitude, latitude)::geography 
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- 4. Create spatial index
CREATE INDEX idx_dog_parks_location ON dog_parks USING GIST(location);

-- 5. Verify data migration
SELECT id, name, 
       ST_Y(location::geometry) as new_lat,
       ST_X(location::geometry) as new_lng,
       latitude as old_lat,
       longitude as old_lng
FROM dog_parks
LIMIT 5;

-- 6. Drop old columns (after verification)
ALTER TABLE dog_parks DROP COLUMN latitude, DROP COLUMN longitude;
```

### Scenario 2: Supporting Both Implementations

If you need to support both PostGIS and non-PostGIS environments:

```sql
-- Add computed columns that work with both
CREATE OR REPLACE VIEW dog_parks_compatible AS
SELECT 
  id, name, description, address,
  COALESCE(ST_Y(location::geometry), latitude) as latitude,
  COALESCE(ST_X(location::geometry), longitude) as longitude,
  location,
  amenities, rules, hours_open, hours_close
FROM dog_parks;
```

## Application Code Compatibility

The BarkPark models already handle PostGIS compatibility by extracting lat/lng in queries:

```javascript
// DogPark.js model extracts coordinates
const query = `
  SELECT 
    id, name, description, address,
    ST_X(location::geometry) as longitude, 
    ST_Y(location::geometry) as latitude,
    ...
  FROM dog_parks
`;
```

This ensures the API returns consistent lat/lng fields regardless of the underlying storage.

## Common Issues and Solutions

### Issue: "column location does not exist"
**Cause**: Database doesn't have PostGIS migration applied  
**Solution**: Run the PostGIS migration or use lat/lng columns

### Issue: "function st_makepoint does not exist"
**Cause**: PostGIS extension not installed  
**Solution**: `CREATE EXTENSION IF NOT EXISTS postgis;`

### Issue: Schema comparison shows location type as "USER-DEFINED"
**Cause**: PostgreSQL reports PostGIS types as USER-DEFINED  
**Solution**: The enhanced schema tools now normalize this to "location"

## Best Practices

1. **Always use the migration system** - Don't manually alter production schemas
2. **Test migrations locally first** - Use `db:schema:sync` to preview changes
3. **Verify data integrity** - Compare extracted lat/lng values after migration
4. **Use spatial indexes** - GIST indexes dramatically improve query performance
5. **Keep models compatible** - Always extract lat/lng in queries for API consistency

## Environment Setup

### Local Development with PostGIS

```bash
# macOS with Homebrew
brew install postgresql@14
brew install postgis

# Ubuntu/Debian
sudo apt-get install postgresql-14-postgis-3

# Enable in database
psql -d barkpark_dev -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

### Checking PostGIS Availability

```sql
-- Check if PostGIS is installed
SELECT PostGIS_Version();

-- Check if extension is available
SELECT * FROM pg_available_extensions WHERE name = 'postgis';

-- Check current tables using PostGIS
SELECT f_table_name, f_geometry_column, srid, type
FROM geometry_columns;
```

## Rollback Procedures

If you need to rollback from PostGIS to lat/lng:

```sql
-- 1. Add back lat/lng columns
ALTER TABLE dog_parks ADD COLUMN latitude DOUBLE PRECISION;
ALTER TABLE dog_parks ADD COLUMN longitude DOUBLE PRECISION;

-- 2. Extract coordinates from location
UPDATE dog_parks 
SET latitude = ST_Y(location::geometry),
    longitude = ST_X(location::geometry)
WHERE location IS NOT NULL;

-- 3. Create indexes
CREATE INDEX idx_dog_parks_lat ON dog_parks(latitude);
CREATE INDEX idx_dog_parks_lng ON dog_parks(longitude);

-- 4. Update application code to use lat/lng columns

-- 5. Drop location column (after verification)
ALTER TABLE dog_parks DROP COLUMN location;
```

## Monitoring Schema Drift

Use the monitoring tools to catch schema differences early:

```bash
# One-time check
npm run db:schema:monitor

# Automated monitoring (add to CI/CD)
PRODUCTION_DATABASE_URL=... STAGING_DATABASE_URL=... npm run db:schema:monitor
```

## Summary

The PostGIS migration provides significant benefits for location-based queries, but requires careful handling of schema differences. Use the provided tools to:

1. Compare schemas across environments
2. Generate appropriate migration SQL
3. Monitor for schema drift
4. Maintain compatibility with both implementations

For questions or issues, check the migration logs and use `db:schema:sync:verbose` for detailed diagnostics.