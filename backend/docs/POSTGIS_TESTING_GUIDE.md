# PostGIS Testing Guide for BarkPark

## Overview

This guide documents the comprehensive PostGIS spatial query testing implementation for the BarkPark application. The tests ensure accurate distance calculations, proper spatial indexing, and edge case handling for the core park discovery features.

## Test Structure

### 1. Compatibility Testing (`tests/models/dogpark-spatial.test.js`)
- Tests spatial queries with both PostGIS and fallback Haversine formula
- Uses `DogParkCompat` model that automatically detects PostGIS availability
- Ensures the application works in both development (without PostGIS) and production (with PostGIS)

### 2. Production Testing (`tests/models/dogpark-postgis.test.js`)
- Tests the actual production `DogPark` model with PostGIS
- Verifies PostGIS-specific features like spatial indexes
- Skips all tests if PostGIS is not available

## Key Test Categories

### Distance Calculations
```javascript
// Tests verify accuracy of distance calculations
- Short distances (< 10km) - precision within 0.1km
- Medium distances (10-100km) - precision within 1km  
- Long distances (> 1000km) - precision within 100km
- Edge cases: International Date Line, polar regions
```

### Spatial Query Performance
```javascript
// Tests verify spatial index usage
- ST_DWithin queries use GIST index
- Bounding box queries use spatial operators
- Performance benchmarks for large radius queries
```

### Edge Cases Covered
1. **International Date Line**
   - Parks on opposite sides (179° and -179° longitude)
   - Proper distance calculation across the line

2. **Polar Regions**
   - High latitude calculations (near 90° and -90°)
   - Convergence of meridians handled correctly

3. **Invalid Coordinates**
   - Latitudes > 90° or < -90°
   - Longitudes > 180° or < -180°
   - NULL or missing coordinates

4. **Boundary Conditions**
   - Zero radius searches
   - Negative radius handling
   - Very large radius (global searches)

## Test Data Management

### Setup
```javascript
// Clean up any leftover test data
await pool.query("DELETE FROM dog_parks WHERE name LIKE '%Test Park%'...");

// Create known test parks with specific locations
testParks = [
  { name: 'Central Park Dog Run', latitude: 40.785091, longitude: -73.968285 },
  { name: 'Madison Square Dog Park', latitude: 40.742051, longitude: -73.987549 },
  // ... more test parks
];
```

### Teardown
```javascript
// Clean up all test data after tests
for (const park of testParks) {
  await pool.query('DELETE FROM dog_parks WHERE id = $1', [park.id]);
}
```

## Running the Tests

### Local Development (without PostGIS)
```bash
npm test -- tests/models/dogpark-spatial.test.js
```
- Uses Haversine formula for distance calculations
- Tests basic spatial functionality
- All tests should pass

### Production Environment (with PostGIS)
```bash
# First ensure PostGIS is installed
psql -d barkpark_test -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# Run all spatial tests
npm test -- tests/models/dogpark-spatial.test.js tests/models/dogpark-postgis.test.js
```

## Key Spatial Queries Tested

### 1. Find Nearby Parks
```sql
-- PostGIS version (accurate spherical calculations)
SELECT *, ST_Distance(location, ST_MakePoint(lng, lat)::geography) / 1000.0 as distance_km
FROM dog_parks 
WHERE ST_DWithin(location, ST_MakePoint(lng, lat)::geography, radius_meters)
ORDER BY distance_km;
```

### 2. Bounding Box Search
```sql
-- Find parks within rectangular bounds
SELECT * FROM dog_parks 
WHERE location && ST_MakeEnvelope(west, south, east, north, 4326)::geography;
```

### 3. Search with Distance Ordering
```sql
-- Text search ordered by distance from user
SELECT *, ST_Distance(...) as distance_km
FROM dog_parks 
WHERE name ILIKE '%search%'
ORDER BY 
  CASE WHEN name ILIKE '%search%' THEN 1 ELSE 2 END,
  distance_km;
```

## Common Issues and Solutions

### Issue: Tests fail with "column location does not exist"
**Solution**: The test database needs PostGIS enabled and migrations run:
```bash
psql -d barkpark_test -c "CREATE EXTENSION postgis;"
psql -d barkpark_test -c "ALTER TABLE dog_parks ADD COLUMN location GEOGRAPHY(POINT, 4326);"
```

### Issue: Distance calculations are slightly off
**Expected**: Different calculation methods have slight variations:
- PostGIS ST_Distance: Uses accurate spheroidal calculations
- Haversine formula: Assumes perfect sphere, ~0.5% error
- Both are acceptable for this use case

### Issue: Spatial index not being used
**Solution**: Create the GIST index:
```sql
CREATE INDEX dog_parks_location_idx ON dog_parks USING GIST (location);
```

## Test Coverage Metrics

### Covered Scenarios
- ✅ Basic distance calculations
- ✅ Ordering by distance
- ✅ Bounding box queries
- ✅ Edge cases (date line, poles)
- ✅ Invalid input handling
- ✅ Performance with spatial indexes
- ✅ NULL location handling
- ✅ Migration from lat/lng to PostGIS

### Not Yet Covered
- ⚠️ Concurrent location updates
- ⚠️ Polygon-based park boundaries
- ⚠️ Multi-point park locations
- ⚠️ Time-based spatial queries

## Best Practices

1. **Always Test Both Environments**
   - Run tests with and without PostGIS
   - Ensure fallback mechanisms work

2. **Use Realistic Test Data**
   - Real coordinates from actual parks
   - Known distances for verification
   - Edge cases from real-world scenarios

3. **Clean Up Test Data**
   - Delete all test parks after tests
   - Use unique names to avoid conflicts
   - Check for leftover data before tests

4. **Performance Considerations**
   - Test with realistic data volumes
   - Verify index usage with EXPLAIN
   - Set reasonable query timeouts

## Future Enhancements

1. **Polygon Support**
   - Test parks with boundary polygons
   - Point-in-polygon queries for user location

2. **Advanced Spatial Queries**
   - K-nearest neighbor searches
   - Clustering for map visualization
   - Route planning between parks

3. **Performance Testing**
   - Load testing with 10,000+ parks
   - Concurrent query stress testing
   - Index optimization validation

## References

- [PostGIS Documentation](https://postgis.net/documentation/)
- [PostgreSQL Earthdistance Extension](https://www.postgresql.org/docs/current/earthdistance.html)
- [Spatial Reference Systems](https://epsg.io/4326)
- [Haversine Formula](https://en.wikipedia.org/wiki/Haversine_formula)