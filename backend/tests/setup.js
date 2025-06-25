// Test setup configuration
const { Client } = require('pg');

// Mock AWS SDK for tests
jest.mock('aws-sdk', () => ({
  S3: jest.fn(() => ({
    upload: jest.fn(() => ({
      promise: jest.fn(() => Promise.resolve({
        Location: 'https://test-bucket.s3.amazonaws.com/test-image.jpg'
      }))
    })),
    deleteObject: jest.fn(() => ({
      promise: jest.fn(() => Promise.resolve())
    }))
  }))
}));

// Test database configuration
process.env.NODE_ENV = 'test';
process.env.DB_NAME = 'barkpark_test';
process.env.DB_USER = process.env.DB_USER || 'austinrathe';
process.env.DB_PASSWORD = process.env.DB_PASSWORD || '';
process.env.DB_HOST = 'localhost';
process.env.DB_PORT = '5432';
process.env.JWT_SECRET = 'test-jwt-secret-key';

// Setup test database before all tests
beforeAll(async () => {
  // Create test database if it doesn't exist
  const client = new Client({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: 'postgres', // Connect to default database first
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
  });

  try {
    await client.connect();
    
    // Check if test database exists
    const result = await client.query(
      "SELECT 1 FROM pg_database WHERE datname = $1", 
      [process.env.DB_NAME]
    );
    
    if (result.rows.length === 0) {
      await client.query(`CREATE DATABASE ${process.env.DB_NAME}`);
      console.log('Created test database');
    }
    
    await client.end();

    // Now initialize the schema in the test database
    const testClient = new Client({
      user: process.env.DB_USER,
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      password: process.env.DB_PASSWORD,
      port: process.env.DB_PORT,
    });

    try {
      await testClient.connect();
      
      // Initialize schema using the simple schema but add missing columns
      const fs = require('fs');
      const path = require('path');
      const schemaPath = path.join(__dirname, '..', 'scripts', 'init-db-simple.sql');
      const schema = fs.readFileSync(schemaPath, 'utf8');
      await testClient.query(schema);
      
      // Add missing columns that the production schema has
      try {
        await testClient.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS is_searchable BOOLEAN NOT NULL DEFAULT true');
        await testClient.query('ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS website VARCHAR(500)');
        await testClient.query('ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS phone VARCHAR(20)');
        await testClient.query('ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS rating DECIMAL(2,1)');
        await testClient.query('ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS review_count INTEGER');
        await testClient.query('ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS surface_type VARCHAR(50)');
        await testClient.query('ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS has_seating BOOLEAN');
        await testClient.query('ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS zipcode VARCHAR(10)');
        await testClient.query('ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS borough VARCHAR(20)');
        console.log('Added missing columns to test schema');
        
        // Add dogs extended fields from migration 002
        const dogsExtendedPath = path.join(__dirname, '..', 'migrations', '002_add_dogs_extended_fields.sql');
        const dogsExtendedSchema = fs.readFileSync(dogsExtendedPath, 'utf8');
        await testClient.query(dogsExtendedSchema);
        console.log('Added dogs extended fields to test schema');
        
        // Add social feed tables from migration 007
        const socialFeedPath = path.join(__dirname, '..', 'migrations', '007_add_social_feed.sql');
        const socialFeedSchema = fs.readFileSync(socialFeedPath, 'utf8');
        await testClient.query(socialFeedSchema);
        console.log('Added social feed tables to test schema');
      } catch (error) {
        console.warn('Warning adding missing columns:', error.message);
      }
      
      // Seed with park data
      const seedPath = path.join(__dirname, '..', 'scripts', 'seed-parks.sql');
      const seedData = fs.readFileSync(seedPath, 'utf8');
      await testClient.query(seedData);
      
      console.log('Initialized test database schema and seeded park data');
      await testClient.end();
    } catch (schemaError) {
      console.warn('Schema setup warning:', schemaError.message);
      try {
        await testClient.end();
      } catch (e) {}
    }
    
  } catch (error) {
    console.warn('Database setup warning:', error.message);
  }
});

// Clean up test data after each test
// Only clean up data for tests that don't manage their own test data
afterEach(async () => {
  // Check if this is a test file that manages its own cleanup
  const testFile = expect.getState().testPath;
  const selfManagedTests = [
    'posts.test.js',
    'posts-standalone.test.js', 
    'notifications.test.js',
    'dogs.test.js'
  ];
  
  // Skip cleanup for tests that manage their own data
  if (testFile && selfManagedTests.some(file => testFile.includes(file))) {
    return;
  }
  
  const pool = require('../config/database');
  try {
    // Clean up in order due to foreign key constraints
    await pool.query('DELETE FROM notifications');
    await pool.query('DELETE FROM post_comments');
    await pool.query('DELETE FROM post_likes');
    await pool.query('DELETE FROM post_media');
    await pool.query('DELETE FROM posts');
    await pool.query('DELETE FROM checkins');
    await pool.query('DELETE FROM dogs');
    await pool.query('DELETE FROM friendships');
    await pool.query('DELETE FROM users');
    // Note: We don't delete dog_parks as they're test fixtures
  } catch (error) {
    // Ignore cleanup errors in tests
  }
});