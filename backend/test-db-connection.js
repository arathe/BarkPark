const pool = require('./config/database');

async function testConnection() {
  console.log('=== Testing Database Connection ===\n');
  
  console.log('1. Testing basic connection...');
  try {
    const client = await pool.connect();
    console.log('✅ Connected successfully');
    
    // Test a simple query
    const result = await client.query('SELECT NOW()');
    console.log(`Current time from DB: ${result.rows[0].now}`);
    
    client.release();
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
  }
  
  console.log('\n2. Testing pool stats...');
  console.log(`Total clients: ${pool.totalCount}`);
  console.log(`Idle clients: ${pool.idleCount}`);
  console.log(`Waiting clients: ${pool.waitingCount}`);
  
  console.log('\n3. Testing concurrent connections...');
  const promises = [];
  for (let i = 0; i < 5; i++) {
    promises.push(
      pool.query('SELECT pg_sleep(0.1), $1 as id', [i])
        .then(() => console.log(`  ✅ Query ${i} completed`))
        .catch(err => console.log(`  ❌ Query ${i} failed: ${err.message}`))
    );
  }
  
  await Promise.all(promises);
  
  console.log('\n4. Environment check...');
  console.log(`NODE_ENV: ${process.env.NODE_ENV}`);
  console.log(`DATABASE_URL exists: ${!!process.env.DATABASE_URL}`);
  console.log(`DB_HOST: ${process.env.DB_HOST || 'not set'}`);
  console.log(`DB_NAME: ${process.env.DB_NAME || 'not set'}`);
  
  // End pool
  await pool.end();
  console.log('\n✅ All tests complete');
}

testConnection().catch(console.error);