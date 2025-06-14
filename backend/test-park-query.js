const pool = require('./config/database');

async function testParkQuery() {
  const client = await pool.connect();
  
  try {
    console.log('=== Testing Park Queries ===\n');
    
    // Test 1: Simple query to get all parks
    console.log('1. Getting total park count...');
    const countResult = await client.query('SELECT COUNT(*) FROM dog_parks');
    console.log(`Total parks: ${countResult.rows[0].count}`);
    
    // Test 2: Get sample parks
    console.log('\n2. Getting sample parks...');
    const sampleResult = await client.query('SELECT id, name, latitude, longitude FROM dog_parks LIMIT 5');
    console.log('Sample parks:');
    sampleResult.rows.forEach(park => {
      console.log(`  - ${park.name}: (${park.latitude}, ${park.longitude})`);
    });
    
    // Test 3: Test the Haversine formula
    console.log('\n3. Testing Haversine distance calculation...');
    const lat = 40.7128; // NYC
    const lng = -74.0060;
    const radius = 10;
    
    const haversineQuery = `
      SELECT 
        id, name, latitude, longitude,
        (6371 * acos(
          LEAST(1.0, GREATEST(-1.0,
            cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2)) + 
            sin(radians($1)) * sin(radians(latitude))
          ))
        )) as distance_km
      FROM dog_parks 
      WHERE latitude IS NOT NULL AND longitude IS NOT NULL
      ORDER BY distance_km
      LIMIT 10
    `;
    
    try {
      const distanceResult = await client.query(haversineQuery, [lat, lng]);
      console.log('Nearest parks to NYC:');
      distanceResult.rows.forEach(park => {
        console.log(`  - ${park.name}: ${park.distance_km.toFixed(2)} km`);
      });
    } catch (error) {
      console.error('Haversine query error:', error.message);
      
      // Try simpler query
      console.log('\n4. Trying simpler distance calculation...');
      const simpleQuery = `
        SELECT 
          id, name, latitude, longitude
        FROM dog_parks 
        WHERE latitude IS NOT NULL 
          AND longitude IS NOT NULL
          AND latitude BETWEEN $1 - 1 AND $1 + 1
          AND longitude BETWEEN $2 - 1 AND $2 + 1
        LIMIT 10
      `;
      
      const simpleResult = await client.query(simpleQuery, [lat, lng]);
      console.log('Parks within rough area:');
      simpleResult.rows.forEach(park => {
        console.log(`  - ${park.name}: (${park.latitude}, ${park.longitude})`);
      });
    }
    
    // Test 5: Check for NULL values
    console.log('\n5. Checking for NULL coordinates...');
    const nullCheckResult = await client.query(`
      SELECT COUNT(*) as total,
             COUNT(latitude) as with_lat,
             COUNT(longitude) as with_lng
      FROM dog_parks
    `);
    const nullCheck = nullCheckResult.rows[0];
    console.log(`Total parks: ${nullCheck.total}`);
    console.log(`Parks with latitude: ${nullCheck.with_lat}`);
    console.log(`Parks with longitude: ${nullCheck.with_lng}`);
    console.log(`Parks missing coordinates: ${nullCheck.total - nullCheck.with_lat}`);
    
  } catch (error) {
    console.error('Test error:', error);
  } finally {
    client.release();
    process.exit(0);
  }
}

testParkQuery();