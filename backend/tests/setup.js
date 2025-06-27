// Test setup configuration
const { Client } = require('pg');

// Mock AWS SDK for tests
jest.mock('aws-sdk', () => {
  const mockUpload = jest.fn();
  const mockDeleteObject = jest.fn();
  
  // Create mock functions that can be controlled in tests
  mockUpload.mockReturnValue({
    promise: jest.fn().mockResolvedValue({
      Location: 'https://test-bucket.s3.amazonaws.com/test-image.jpg',
      ETag: '"test-etag"',
      Key: 'test-image.jpg'
    })
  });
  
  mockDeleteObject.mockReturnValue({
    promise: jest.fn().mockResolvedValue({})
  });
  
  return {
    S3: jest.fn(() => ({
      upload: mockUpload,
      deleteObject: mockDeleteObject
    }))
  };
});

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
  const { Client } = require('pg');
  const fs = require('fs');
  const path = require('path');
  
  // For tests, we expect the test database to already exist with proper schema
  // It should be created from the main barkpark database template
  const testClient = new Client({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
  });

  try {
    await testClient.connect();
    
    // Verify we have the correct schema by checking for key columns
    const friendshipCheck = await testClient.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'friendships' 
      AND column_name IN ('user_id', 'friend_id')
    `);
    
    if (friendshipCheck.rows.length !== 2) {
      console.error('ERROR: Test database schema is incorrect. Please recreate test database from main database.');
      process.exit(1);
    }
    
    // Clear all data except dog_parks (which are fixtures)
    await testClient.query('TRUNCATE TABLE notifications, post_comments, post_likes, post_media, posts, checkins, dogs, friendships, users RESTART IDENTITY CASCADE');
    
    console.log('Test database ready with correct schema');
    await testClient.end();
  } catch (error) {
    console.error('Test database setup error:', error.message);
    console.error('Please ensure barkpark_test database exists with correct schema');
    process.exit(1);
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