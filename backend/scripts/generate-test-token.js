require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('../config/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const TEST_USER = {
  firstName: 'Test',
  lastName: 'User',
  email: 'test@barkpark.com',
  password: 'BarkPark123!',
  phone: '555-123-4567'
};

async function generateTestToken() {
  try {
    // Check if user exists
    const existingUser = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [TEST_USER.email]
    );

    let userId;
    
    if (existingUser.rows.length === 0) {
      // Create test user
      console.log('Creating test user...');
      const hashedPassword = await bcrypt.hash(TEST_USER.password, 10);
      
      const result = await pool.query(
        `INSERT INTO users (first_name, last_name, email, password_hash, phone, is_searchable)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id`,
        [TEST_USER.firstName, TEST_USER.lastName, TEST_USER.email, hashedPassword, TEST_USER.phone, true]
      );
      
      userId = result.rows[0].id;
      console.log('Test user created with ID:', userId);
    } else {
      userId = existingUser.rows[0].id;
      console.log('Test user already exists with ID:', userId);
      
      // Update password to ensure it matches
      const hashedPassword = await bcrypt.hash(TEST_USER.password, 10);
      await pool.query(
        'UPDATE users SET password_hash = $1 WHERE id = $2',
        [hashedPassword, userId]
      );
      console.log('Updated test user password');
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: userId, email: TEST_USER.email },
      process.env.JWT_SECRET,
      { expiresIn: '365d' } // Long-lived token for testing
    );

    // Update .env.test file
    const envPath = path.join(__dirname, '../.env.test');
    let envContent = fs.readFileSync(envPath, 'utf8');
    
    // Update or add TEST_USER_TOKEN
    if (envContent.includes('TEST_USER_TOKEN=')) {
      envContent = envContent.replace(/TEST_USER_TOKEN=.*/, `TEST_USER_TOKEN=${token}`);
    } else {
      envContent += `\nTEST_USER_TOKEN=${token}`;
    }
    
    fs.writeFileSync(envPath, envContent);
    
    console.log('\n✅ Test token generated successfully!');
    console.log('Email:', TEST_USER.email);
    console.log('Password:', TEST_USER.password);
    console.log('User ID:', userId);
    console.log('\nToken saved to .env.test');
    console.log('\nYou can now use this token for API testing:');
    console.log(`export TEST_TOKEN="${token}"`);
    
    process.exit(0);
  } catch (error) {
    console.error('Error generating test token:', error);
    process.exit(1);
  }
}

generateTestToken();