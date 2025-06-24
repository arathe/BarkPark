const DogPark = require('../../models/DogPark');
const pool = require('../../config/database');

// This test file specifically tests the production DogPark model with PostGIS
// It will skip all tests if PostGIS is not available
describe('DogPark Model - Production PostGIS Tests', () => {
  let hasPostGIS = false;
  let testPark = null;

  beforeAll(async () => {
    // Check if PostGIS is available
    try {
      const result = await pool.query("SELECT PostGIS_Version()");
      hasPostGIS = true;
      console.log('PostGIS version:', result.rows[0].postgis_version);
      
      // Ensure the location column exists
      await pool.query(`
        ALTER TABLE dog_parks 
        ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326)
      `);
      
      // Update any parks that have lat/lng but no location
      await pool.query(`
        UPDATE dog_parks 
        SET location = ST_MakePoint(longitude, latitude)::geography
        WHERE location IS NULL AND longitude IS NOT NULL AND latitude IS NOT NULL
      `);
      
    } catch (error) {
      console.log('PostGIS not available, skipping production tests');
    }
  });

  beforeEach(async () => {
    if (!hasPostGIS) return;
    
    // Create a test park for each test
    testPark = await DogPark.create({
      name: 'PostGIS Test Park',
      address: 'Test Location',
      latitude: 40.7128,
      longitude: -74.0060,
      description: 'Park for testing PostGIS functionality',
      hoursOpen: '06:00',
      hoursClose: '22:00',
      rules: 'Test rules',
      surfaceType: 'grass',
      hasSeating: true,
      zipcode: '10001',
      borough: 'Test Borough',
      rating: 4.5,
      reviewCount: 10
    });
  });

  afterEach(async () => {
    if (!hasPostGIS || !testPark) return;
    
    // Clean up test park
    await pool.query('DELETE FROM dog_parks WHERE id = $1', [testPark.id]);
    testPark = null;
  });

  describe('PostGIS functionality', () => {
    test('should store and retrieve location correctly', async () => {
      if (!hasPostGIS) {
        console.log('Skipping test - PostGIS not available');
        return;
      }

      const retrieved = await DogPark.findById(testPark.id);
      
      expect(retrieved).toBeDefined();
      expect(retrieved.latitude).toBeCloseTo(40.7128, 4);
      expect(retrieved.longitude).toBeCloseTo(-74.0060, 4);
    });

    test('should calculate distances accurately with ST_Distance', async () => {
      if (!hasPostGIS) {
        console.log('Skipping test - PostGIS not available');
        return;
      }

      // Create a second park 10km away
      const park2 = await DogPark.create({
        name: 'PostGIS Test Park 2',
        address: 'Test Location 2',
        latitude: 40.7589,
        longitude: -73.9851, // Times Square
        description: 'Second test park',
        hoursOpen: '06:00',
        hoursClose: '22:00',
        borough: 'Manhattan'
      });

      try {
        // Find parks within 15km
        const nearby = await DogPark.findNearby(testPark.latitude, testPark.longitude, 15);
        
        const foundPark2 = nearby.find(p => p.id === park2.id);
        expect(foundPark2).toBeDefined();
        
        // Distance should be approximately 5.5km
        expect(foundPark2.distanceKm).toBeGreaterThan(5);
        expect(foundPark2.distanceKm).toBeLessThan(6);
      } finally {
        await pool.query('DELETE FROM dog_parks WHERE id = $1', [park2.id]);
      }
    });

    test('should use spatial index for performance', async () => {
      if (!hasPostGIS) {
        console.log('Skipping test - PostGIS not available');
        return;
      }

      // Create spatial index if it doesn't exist
      await pool.query(`
        CREATE INDEX IF NOT EXISTS dog_parks_location_idx 
        ON dog_parks USING GIST (location)
      `);

      // Verify index is used with EXPLAIN
      const explainResult = await pool.query(`
        EXPLAIN (FORMAT JSON)
        SELECT * FROM dog_parks 
        WHERE ST_DWithin(
          location::geography,
          ST_MakePoint($2, $1)::geography,
          $3::numeric * 1000
        )
      `, [40.7128, -74.0060, 10]);
      
      const plan = JSON.stringify(explainResult.rows[0]['QUERY PLAN']);
      
      // Should use index scan
      expect(plan).toMatch(/Index Scan|Bitmap Index Scan/);
    });

    test('should handle coordinate system transformations', async () => {
      if (!hasPostGIS) {
        console.log('Skipping test - PostGIS not available');
        return;
      }

      // Test that geography/geometry conversions work correctly
      const result = await pool.query(`
        SELECT 
          ST_X(location::geometry) as x,
          ST_Y(location::geometry) as y,
          ST_AsText(location) as wkt,
          ST_SRID(location::geometry) as srid
        FROM dog_parks 
        WHERE id = $1
      `, [testPark.id]);
      
      expect(result.rows[0].x).toBeCloseTo(-74.0060, 4);
      expect(result.rows[0].y).toBeCloseTo(40.7128, 4);
      expect(result.rows[0].srid).toBe(4326);
      expect(result.rows[0].wkt).toMatch(/POINT/);
    });

    test('should handle bounding box queries with ST_MakeEnvelope', async () => {
      if (!hasPostGIS) {
        console.log('Skipping test - PostGIS not available');
        return;
      }

      const bounds = {
        northEast: { latitude: 40.8, longitude: -73.9 },
        southWest: { latitude: 40.6, longitude: -74.1 }
      };
      
      const parksInBounds = await DogPark.findWithinBounds(bounds.northEast, bounds.southWest);
      
      // Test park should be within bounds
      const found = parksInBounds.find(p => p.id === testPark.id);
      expect(found).toBeDefined();
    });

    test('should calculate accurate distances for long distances', async () => {
      if (!hasPostGIS) {
        console.log('Skipping test - PostGIS not available');
        return;
      }

      // Create a park in London
      const londonPark = await DogPark.create({
        name: 'London PostGIS Test',
        address: 'London, UK',
        latitude: 51.5074,
        longitude: -0.1278,
        description: 'Test park in London',
        hoursOpen: '06:00',
        hoursClose: '22:00',
        borough: 'London'
      });

      try {
        // Query for distance
        const result = await pool.query(`
          SELECT ST_Distance(
            location::geography,
            ST_MakePoint($2, $1)::geography
          ) / 1000.0 as distance_km
          FROM dog_parks 
          WHERE id = $3
        `, [testPark.latitude, testPark.longitude, londonPark.id]);
        
        // NY to London is approximately 5570 km
        expect(result.rows[0].distance_km).toBeGreaterThan(5500);
        expect(result.rows[0].distance_km).toBeLessThan(5600);
      } finally {
        await pool.query('DELETE FROM dog_parks WHERE id = $1', [londonPark.id]);
      }
    });

    test('should handle NULL locations gracefully', async () => {
      if (!hasPostGIS) {
        console.log('Skipping test - PostGIS not available');
        return;
      }

      // Insert a park with NULL location directly
      const result = await pool.query(`
        INSERT INTO dog_parks (name, address, hours_open, hours_close, borough)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id
      `, ['NULL Location Park', 'No coords', '06:00', '18:00', 'Test']);
      
      const nullParkId = result.rows[0].id;

      try {
        // Should not crash when finding nearby parks
        const nearby = await DogPark.findNearby(40.7128, -74.0060, 10);
        
        // NULL location park should not be in results
        const foundNull = nearby.find(p => p.id === nullParkId);
        expect(foundNull).toBeUndefined();
      } finally {
        await pool.query('DELETE FROM dog_parks WHERE id = $1', [nullParkId]);
      }
    });
  });

  describe('PostGIS migration verification', () => {
    test('should have migrated all existing parks to PostGIS', async () => {
      if (!hasPostGIS) {
        console.log('Skipping test - PostGIS not available');
        return;
      }

      // Check for parks with lat/lng but no location
      const result = await pool.query(`
        SELECT COUNT(*) as count
        FROM dog_parks 
        WHERE latitude IS NOT NULL 
          AND longitude IS NOT NULL 
          AND location IS NULL
      `);
      
      expect(parseInt(result.rows[0].count)).toBe(0);
    });

    test('should maintain consistency between lat/lng and location columns', async () => {
      if (!hasPostGIS) {
        console.log('Skipping test - PostGIS not available');
        return;
      }

      // Update the park's latitude/longitude
      await DogPark.update(testPark.id, {
        latitude: 40.7589,
        longitude: -73.9851
      });

      // Verify the location column was updated
      const result = await pool.query(`
        SELECT 
          latitude, longitude,
          ST_Y(location::geometry) as loc_lat,
          ST_X(location::geometry) as loc_lng
        FROM dog_parks 
        WHERE id = $1
      `, [testPark.id]);
      
      expect(result.rows[0].loc_lat).toBeCloseTo(40.7589, 4);
      expect(result.rows[0].loc_lng).toBeCloseTo(-73.9851, 4);
    });
  });
});