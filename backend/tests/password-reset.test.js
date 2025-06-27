const request = require('supertest');
const app = require('../server');
const pool = require('../config/database');
const User = require('../models/User');
const emailService = require('../services/emailService');

// Mock the email service
jest.mock('../services/emailService', () => ({
  sendPasswordResetEmail: jest.fn().mockResolvedValue({
    success: true,
    messageId: 'test-message-id'
  })
}));

describe('Password Reset Flow', () => {
  let testUser;
  
  beforeAll(async () => {
    // Create a test user
    testUser = {
      email: 'testreset@example.com',
      password: 'oldpassword123',
      firstName: 'Reset',
      lastName: 'Test'
    };

    // Clean up any existing test user
    await pool.query('DELETE FROM users WHERE email = $1', [testUser.email]);
    
    // Register the test user
    const response = await request(app)
      .post('/api/auth/register')
      .send(testUser);
    
    testUser.id = response.body.user.id;
  });

  afterAll(async () => {
    // Clean up test data
    await pool.query('DELETE FROM users WHERE email = $1', [testUser.email]);
  });

  afterEach(() => {
    // Clear mock calls between tests
    jest.clearAllMocks();
  });

  describe('POST /api/auth/forgot-password', () => {
    it('should accept valid email and send reset email', async () => {
      const response = await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: testUser.email })
        .expect(200);

      expect(response.body).toMatchObject({
        message: 'If an account exists with this email, a password reset code has been sent.',
        expiresIn: '1 hour'
      });

      // Verify email service was called
      expect(emailService.sendPasswordResetEmail).toHaveBeenCalledTimes(1);
      expect(emailService.sendPasswordResetEmail).toHaveBeenCalledWith(
        testUser.email,
        expect.any(String)
      );
    });

    it('should return same response for non-existent email', async () => {
      const response = await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: 'nonexistent@example.com' })
        .expect(200);

      expect(response.body).toMatchObject({
        message: 'If an account exists with this email, a password reset code has been sent.',
        expiresIn: '1 hour'
      });

      // Email service should not be called for non-existent user
      expect(emailService.sendPasswordResetEmail).not.toHaveBeenCalled();
    });

    it('should validate email format', async () => {
      const response = await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: 'invalid-email' })
        .expect(400);

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].msg).toContain('Invalid value');
    });

    it.skip('should enforce rate limiting', async () => {
      // First request should succeed
      await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: testUser.email })
        .expect(200);

      // Manually update the database to simulate 3 requests in the last hour
      await pool.query(`
        UPDATE users 
        SET reset_token = $1, 
            reset_token_expires = NOW() + INTERVAL '30 minutes'
        WHERE email = $2
      `, ['dummy-token-for-rate-limit-test', testUser.email]);

      // Simulate that 2 more requests were made
      await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: testUser.email })
        .expect(200);

      await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: testUser.email })
        .expect(200);

      // 4th request should be rate limited
      const response = await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: testUser.email })
        .expect(429);

      expect(response.body.error).toContain('Too many password reset requests');
    });
  });

  describe('POST /api/auth/reset-password', () => {
    let resetToken;

    beforeEach(async () => {
      // Ensure user exists in database for this test suite
      const userCheck = await pool.query('SELECT id FROM users WHERE email = $1', [testUser.email]);
      if (userCheck.rows.length === 0) {
        // Re-create the test user if it was cleaned up
        const response = await request(app)
          .post('/api/auth/register')
          .send(testUser);
        testUser.id = response.body.user.id;
      }
      
      // Generate a fresh reset token
      const userWithToken = await User.generatePasswordResetToken(testUser.email);
      if (!userWithToken) {
        throw new Error('Failed to generate reset token for test user');
      }
      resetToken = userWithToken.reset_token;
    });

    it('should reset password with valid token', async () => {
      const newPassword = 'newpassword123';

      const response = await request(app)
        .post('/api/auth/reset-password')
        .send({
          token: resetToken,
          password: newPassword
        })
        .expect(200);

      expect(response.body).toMatchObject({
        message: 'Password reset successful',
        user: {
          id: testUser.id,
          email: testUser.email,
          firstName: testUser.firstName,
          lastName: testUser.lastName
        }
      });

      expect(response.body.token).toBeDefined();

      // Verify user can login with new password
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: newPassword
        })
        .expect(200);

      expect(loginResponse.body.token).toBeDefined();
    });

    it('should reject invalid token', async () => {
      const response = await request(app)
        .post('/api/auth/reset-password')
        .send({
          token: 'invalid-token-1234567890123456789012345678901234567890',
          password: 'newpassword123'
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid or expired reset token');
    });

    it('should reject expired token', async () => {
      // Manually expire the token
      await pool.query(
        'UPDATE users SET reset_token_expires = NOW() - INTERVAL \'2 hours\' WHERE email = $1',
        [testUser.email]
      );

      const response = await request(app)
        .post('/api/auth/reset-password')
        .send({
          token: resetToken,
          password: 'newpassword123'
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid or expired reset token');
    });

    it('should validate password requirements', async () => {
      const response = await request(app)
        .post('/api/auth/reset-password')
        .send({
          token: resetToken,
          password: '123' // Too short
        })
        .expect(400);

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].msg).toContain('Password must be at least 6 characters');
    });

    it('should clear token after successful reset', async () => {
      await request(app)
        .post('/api/auth/reset-password')
        .send({
          token: resetToken,
          password: 'newpassword123'
        })
        .expect(200);

      // Same token should not work again
      const response = await request(app)
        .post('/api/auth/reset-password')
        .send({
          token: resetToken,
          password: 'anotherpassword123'
        })
        .expect(400);

      expect(response.body.error).toBe('Invalid or expired reset token');
    });
  });

  describe('GET /api/auth/verify-reset-token', () => {
    let resetToken;

    beforeEach(async () => {
      // Ensure user exists in database for this test suite
      const userCheck = await pool.query('SELECT id FROM users WHERE email = $1', [testUser.email]);
      if (userCheck.rows.length === 0) {
        // Re-create the test user if it was cleaned up
        const response = await request(app)
          .post('/api/auth/register')
          .send(testUser);
        testUser.id = response.body.user.id;
      }
      
      // Generate a fresh reset token
      const userWithToken = await User.generatePasswordResetToken(testUser.email);
      if (!userWithToken) {
        throw new Error('Failed to generate reset token for test user');
      }
      resetToken = userWithToken.reset_token;
    });

    it('should verify valid token', async () => {
      const response = await request(app)
        .get('/api/auth/verify-reset-token')
        .query({ token: resetToken })
        .expect(200);

      expect(response.body).toMatchObject({
        message: 'Reset token is valid',
        valid: true,
        email: testUser.email
      });
    });

    it('should reject invalid token', async () => {
      const response = await request(app)
        .get('/api/auth/verify-reset-token')
        .query({ token: 'invalid-token-1234567890123456789012345678901234567890' })
        .expect(400);

      expect(response.body).toMatchObject({
        error: 'Invalid or expired reset token',
        valid: false
      });
    });

    it('should reject expired token', async () => {
      // Manually expire the token
      await pool.query(
        'UPDATE users SET reset_token_expires = NOW() - INTERVAL \'2 hours\' WHERE email = $1',
        [testUser.email]
      );

      const response = await request(app)
        .get('/api/auth/verify-reset-token')
        .query({ token: resetToken })
        .expect(400);

      expect(response.body).toMatchObject({
        error: 'Invalid or expired reset token',
        valid: false
      });
    });

    it('should validate token format', async () => {
      const response = await request(app)
        .get('/api/auth/verify-reset-token')
        .query({ token: 'short' })
        .expect(400);

      expect(response.body.errors).toBeDefined();
    });
  });
});