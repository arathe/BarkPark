const pool = require('./config/database');
const bcrypt = require('bcrypt');

async function testUserCreation() {
  const client = await pool.connect();
  
  try {
    console.log('=== Testing User Creation ===\n');
    
    // Test data
    const email = `test_${Date.now()}@example.com`;
    const password = 'TestPassword123!';
    const firstName = 'Test';
    const lastName = 'User';
    
    console.log('1. Hashing password...');
    const hashedPassword = await bcrypt.hash(password, 10);
    console.log('Password hashed successfully');
    
    console.log('\n2. Attempting to insert user...');
    const query = `
      INSERT INTO users (email, password_hash, first_name, last_name)
      VALUES ($1, $2, $3, $4)
      RETURNING id, email, first_name, last_name, is_searchable, created_at
    `;
    
    const values = [email, hashedPassword, firstName, lastName];
    console.log('Query values:', [email, '[REDACTED]', firstName, lastName]);
    
    try {
      const result = await client.query(query, values);
      console.log('✅ User created successfully!');
      console.log('Result:', result.rows[0]);
    } catch (error) {
      console.error('❌ Database error:');
      console.error('  Message:', error.message);
      console.error('  Code:', error.code);
      console.error('  Detail:', error.detail);
      console.error('  Constraint:', error.constraint);
      console.error('  Stack:', error.stack);
    }
    
    // Check if table exists and has proper permissions
    console.log('\n3. Checking table permissions...');
    const permQuery = `
      SELECT has_table_privilege(current_user, 'users', 'INSERT') as can_insert,
             has_table_privilege(current_user, 'users', 'SELECT') as can_select
    `;
    const permResult = await client.query(permQuery);
    console.log('Permissions:', permResult.rows[0]);
    
  } catch (error) {
    console.error('Test error:', error);
  } finally {
    client.release();
    process.exit(0);
  }
}

testUserCreation();