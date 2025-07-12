// Shared mock utilities for consistent test mocking

// Mock auth middleware that doesn't require database lookups
const mockAuthMiddleware = () => {
  const mockJwt = require('jsonwebtoken');
  return {
    verifyToken: (req, res, next) => {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Access token required' });
      }
      const token = authHeader.substring(7);
      try {
        const decoded = mockJwt.verify(token, process.env.JWT_SECRET || 'test-jwt-secret-key');
        req.user = { id: decoded.userId };
        next();
      } catch (error) {
        return res.status(401).json({ error: 'Invalid token' });
      }
    },
    generateToken: (userId) => {
      return mockJwt.sign({ userId }, process.env.JWT_SECRET || 'test-jwt-secret-key');
    },
    optionalAuth: (req, res, next) => {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        req.user = null;
        return next();
      }
      const token = authHeader.substring(7);
      try {
        const decoded = mockJwt.verify(token, process.env.JWT_SECRET || 'test-jwt-secret-key');
        req.user = { id: decoded.userId };
      } catch {
        req.user = null;
      }
      next();
    }
  };
};

// Mock email service
const mockEmailService = () => ({
  sendPasswordResetEmail: jest.fn().mockResolvedValue({
    success: true,
    messageId: 'test-message-id'
  }),
  sendWelcomeEmail: jest.fn().mockResolvedValue({
    success: true,
    messageId: 'test-message-id'
  }),
  sendNotificationEmail: jest.fn().mockResolvedValue({
    success: true,
    messageId: 'test-message-id'
  })
});

// Mock S3 upload
const mockS3Upload = () => {
  const mockUpload = jest.fn();
  const mockDeleteObject = jest.fn();
  
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
};

// Note: These must be called at the top of test files, not inside functions
// Example usage:
// jest.mock('../../middleware/auth', () => require('./utils/testMocks').mockAuthMiddleware());

module.exports = {
  mockAuthMiddleware,
  mockEmailService,
  mockS3Upload
};