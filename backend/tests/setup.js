// Test setup configuration
const { Client } = require('pg');

// Mock AWS SDK for tests
jest.mock('aws-sdk', () => {
  const mockUpload = jest.fn();
  const mockDeleteObject = jest.fn();
  
  // Create mock functions that can be controlled in tests
  mockUpload.mockImplementation((params) => ({
    promise: jest.fn().mockResolvedValue({
      Location: `https://${params.Bucket}.s3.amazonaws.com/${params.Key}`,
      ETag: '"test-etag"',
      Key: params.Key
    })
  }));
  
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

// Mock nodemailer for tests
jest.mock('nodemailer', () => ({
  createTransport: jest.fn().mockReturnValue({
    sendMail: jest.fn().mockResolvedValue({
      messageId: 'test-message-id',
      response: '250 OK'
    }),
    verify: jest.fn().mockResolvedValue(true)
  })
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
    
    console.log('Test database ready with correct schema');
    await testClient.end();
  } catch (error) {
    console.error('Test database setup error:', error.message);
    console.error('Please ensure barkpark_test database exists with correct schema');
    process.exit(1);
  }
});

// Clean up ALL test data before each test to ensure complete isolation
beforeEach(async () => {
  const pool = require('../config/database');
  try {
    // Clear all data except dog_parks (which are fixtures)
    // Using TRUNCATE with RESTART IDENTITY to reset auto-increment sequences
    await pool.query('TRUNCATE TABLE notifications, post_comments, post_likes, post_media, posts, checkins, dogs, friendships, users RESTART IDENTITY CASCADE');
  } catch (error) {
    console.error('Error cleaning test database:', error.message);
    throw error;
  }
});

// Close database connections after all tests
afterAll(async () => {
  const pool = require('../config/database');
  try {
    // Give a small delay to allow any pending operations to complete
    await new Promise(resolve => setTimeout(resolve, 100));
    await pool.end();
  } catch (error) {
    console.error('Error closing database pool:', error.message);
  }
});

// Set test timeout
jest.setTimeout(30000);

// Prevent open handle warnings
process.on('unhandledRejection', (err) => {
  console.error('Unhandled promise rejection in tests:', err);
});