const pool = require('./config/database');

async function testDogCreation() {
  const client = await pool.connect();
  
  try {
    console.log('=== Testing Dog Creation ===\n');
    
    // First, get a valid user ID
    console.log('1. Getting a user ID...');
    const userResult = await client.query('SELECT id FROM users LIMIT 1');
    if (userResult.rows.length === 0) {
      console.error('No users found in database!');
      return;
    }
    const userId = userResult.rows[0].id;
    console.log(`Using user ID: ${userId}`);
    
    // Test minimal dog creation
    console.log('\n2. Testing minimal dog creation...');
    const minimalQuery = `
      INSERT INTO dogs (user_id, name)
      VALUES ($1, $2)
      RETURNING *
    `;
    
    try {
      const result = await client.query(minimalQuery, [userId, 'MinimalDog']);
      console.log('✅ Minimal dog created successfully!');
      console.log('Result:', result.rows[0]);
    } catch (error) {
      console.error('❌ Minimal dog creation failed:');
      console.error('  Message:', error.message);
      console.error('  Code:', error.code);
      console.error('  Detail:', error.detail);
    }
    
    // Test full dog creation
    console.log('\n3. Testing full dog creation...');
    const fullQuery = `
      INSERT INTO dogs (
        user_id, name, breed, birthday, weight, gender, size_category,
        energy_level, friendliness_dogs, friendliness_people, training_level,
        favorite_activities, is_vaccinated, is_spayed_neutered, special_needs,
        bio, profile_image_url
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
      RETURNING *
    `;
    
    const values = [
      userId, 'FullDog', 'Golden Retriever', '2021-06-15', 65.5, 'male', 'large',
      'high', 5, 5, 'advanced',
      JSON.stringify(['fetch', 'swimming']), true, true, null,
      'A friendly dog', null
    ];
    
    try {
      const result = await client.query(fullQuery, values);
      console.log('✅ Full dog created successfully!');
      console.log('Result:', result.rows[0]);
    } catch (error) {
      console.error('❌ Full dog creation failed:');
      console.error('  Message:', error.message);
      console.error('  Code:', error.code);
      console.error('  Detail:', error.detail);
      console.error('  Constraint:', error.constraint);
    }
    
    // Check the actual table structure
    console.log('\n4. Checking for any issues with columns...');
    const checkQuery = `
      SELECT column_name, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'dogs' AND is_nullable = 'NO' AND column_default IS NULL
      ORDER BY ordinal_position;
    `;
    const checkResult = await client.query(checkQuery);
    console.log('Required columns without defaults:');
    checkResult.rows.forEach(col => {
      console.log(`  - ${col.column_name}`);
    });
    
  } catch (error) {
    console.error('Test error:', error);
  } finally {
    client.release();
    process.exit(0);
  }
}

testDogCreation();