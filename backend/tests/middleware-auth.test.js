const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const testDataFactory = require('./utils/testDataFactory');

// Import the REAL auth middleware (not mocked)
const { generateToken, verifyToken, optionalAuth } = require('../middleware/auth');

// Helper to create mock req/res/next
const createMockObjects = () => {
  const req = {
    headers: {}
  };
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis()
  };
  const next = jest.fn();
  return { req, res, next };
};

describe('Auth Middleware - Unit Tests', () => {
  let testUserId;

  beforeEach(async () => {
    // Create a test user
    const userData = testDataFactory.createUserData();
    const result = await pool.query(`
      INSERT INTO users (email, password_hash, first_name, last_name)
      VALUES ($1, $2, $3, $4)
      RETURNING id
    `, [userData.email, 'hashedpassword', userData.firstName, userData.lastName]);
    testUserId = result.rows[0].id;
  });

  describe('generateToken', () => {
    it('should generate a valid JWT token', () => {
      const token = generateToken(testUserId);
      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.')).toHaveLength(3); // JWT has 3 parts
    });

    it('should encode the userId in the token', () => {
      const token = generateToken(testUserId);
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      expect(decoded.userId).toBe(testUserId);
    });

    it('should include an expiration', () => {
      const token = generateToken(testUserId);
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      expect(decoded).toHaveProperty('exp');
      expect(decoded.exp).toBeGreaterThan(Math.floor(Date.now() / 1000));
    });
  });

  describe('verifyToken', () => {
    it('should set req.user for valid token', async () => {
      const token = generateToken(testUserId);
      const { req, res, next } = createMockObjects();
      req.headers.authorization = `Bearer ${token}`;

      await verifyToken(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeDefined();
      expect(req.user.id).toBe(testUserId);
    });

    it('should return 401 when no authorization header', async () => {
      const { req, res, next } = createMockObjects();

      await verifyToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ error: expect.any(String) })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 when authorization header lacks Bearer prefix', async () => {
      const { req, res, next } = createMockObjects();
      req.headers.authorization = 'Basic sometoken';

      await verifyToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 for invalid token', async () => {
      const { req, res, next } = createMockObjects();
      req.headers.authorization = 'Bearer invalid.token.here';

      await verifyToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 for expired token', async () => {
      // Create a token that expires immediately
      const token = jwt.sign(
        { userId: testUserId },
        process.env.JWT_SECRET,
        { expiresIn: '0s' }
      );

      // Wait a moment for the token to expire
      await new Promise(resolve => setTimeout(resolve, 1100));

      const { req, res, next } = createMockObjects();
      req.headers.authorization = `Bearer ${token}`;

      await verifyToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ error: expect.stringContaining('expired') })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 for token with non-existent user', async () => {
      const token = jwt.sign(
        { userId: 99999 },
        process.env.JWT_SECRET,
        { expiresIn: '1h' }
      );
      const { req, res, next } = createMockObjects();
      req.headers.authorization = `Bearer ${token}`;

      await verifyToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 for token signed with wrong secret', async () => {
      const token = jwt.sign(
        { userId: testUserId },
        'wrong-secret-key',
        { expiresIn: '1h' }
      );
      const { req, res, next } = createMockObjects();
      req.headers.authorization = `Bearer ${token}`;

      await verifyToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('optionalAuth', () => {
    it('should set req.user for valid token', async () => {
      const token = generateToken(testUserId);
      const { req, res, next } = createMockObjects();
      req.headers.authorization = `Bearer ${token}`;

      await optionalAuth(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeDefined();
      expect(req.user.id).toBe(testUserId);
    });

    it('should set req.user to null when no authorization header', async () => {
      const { req, res, next } = createMockObjects();

      await optionalAuth(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeNull();
    });

    it('should set req.user to null for invalid token', async () => {
      const { req, res, next } = createMockObjects();
      req.headers.authorization = 'Bearer invalid.token.here';

      await optionalAuth(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeNull();
    });

    it('should not return error status for missing/invalid tokens', async () => {
      const { req, res, next } = createMockObjects();
      req.headers.authorization = 'Bearer bad-token';

      await optionalAuth(req, res, next);

      expect(res.status).not.toHaveBeenCalled();
      expect(next).toHaveBeenCalled();
    });
  });
});
