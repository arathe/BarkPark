// Test data factory for generating consistent test data
const crypto = require('crypto');

// Counter for ensuring unique IDs within a test run
let testCounter = 0;

// Generate unique test data with timestamps and random values
const testDataFactory = {
  // Create unique user data
  createUserData: () => {
    const timestamp = Date.now();
    const random = crypto.randomBytes(4).toString('hex');
    const counter = ++testCounter;
    return {
      email: `test_${timestamp}_${counter}_${random}@example.com`,
      password: 'testpass123',
      firstName: `Test_${timestamp}_${counter}`,
      lastName: 'User',
      phone: '+12125551234'
    };
  },

  // Create unique dog data
  createDogData: (userId) => {
    const timestamp = Date.now();
    const random = crypto.randomBytes(4).toString('hex');
    return {
      userId,
      name: `TestDog_${timestamp}_${random}`,
      breed: 'Test Breed',
      age: 3,
      gender: 'male',
      weight: 25,
      description: 'A test dog for unit tests',
      personality_traits: ['friendly', 'playful'],
      activity_level: 'moderate',
      good_with_dogs: true,
      good_with_children: true,
      vaccination_status: 'up_to_date',
      photo_url: 'https://test-bucket.s3.amazonaws.com/test-dog.jpg'
    };
  },

  // Create unique post data
  createPostData: (userId, checkInId = null) => {
    const timestamp = Date.now();
    const random = crypto.randomBytes(4).toString('hex');
    return {
      userId,
      content: `Test post content ${timestamp}_${random}`,
      visibility: 'public',
      checkInId
    };
  },

  // Create comment data
  createCommentData: (postId, userId, parentCommentId = null) => {
    const timestamp = Date.now();
    return {
      postId,
      userId,
      content: `Test comment ${timestamp}`,
      parentCommentId
    };
  },

  // Create check-in data
  createCheckInData: (userId, dogParkId, dogIds = []) => {
    return {
      userId,
      dogParkId,
      dogIds,
      duration: 30
    };
  },

  // Create notification data
  createNotificationData: (userId, type, data) => {
    return {
      userId,
      type,
      data: {
        message: 'Test notification',
        ...data
      }
    };
  },

  // Generate valid JWT token for testing
  generateTestToken: (userId) => {
    const jwt = require('jsonwebtoken');
    return jwt.sign({ userId }, process.env.JWT_SECRET || 'test-jwt-secret-key');
  },

  // Generate QR code data
  generateQRData: (userId) => {
    const timestamp = Date.now();
    const data = {
      userId,
      timestamp,
      type: 'friend_request'
    };
    return Buffer.from(JSON.stringify(data)).toString('base64');
  },

  // Create password reset token
  createResetToken: () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let token = '';
    for (let i = 0; i < 5; i++) {
      token += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return token;
  }
};

module.exports = testDataFactory;