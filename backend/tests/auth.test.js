const request = require('supertest');
const express = require('express');
const cors = require('cors');
const authRoutes = require('../routes/auth');
const User = require('../models/User');

// Create test app
const createTestApp = () => {
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  return app;
};

describe('Authentication API', () => {
  let app;
  let testUser;

  beforeEach(async () => {
    app = createTestApp();
    // Create a test user for login tests
    testUser = {
      email: 'test@example.com',
      password: 'password123',
      firstName: 'Test',
      lastName: 'User'
    };
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user with valid data', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(201);

      expect(response.body).toHaveProperty('message', 'User created successfully');
      expect(response.body).toHaveProperty('token');
      expect(response.body.user).toMatchObject({
        email: testUser.email,
        firstName: testUser.firstName,
        lastName: testUser.lastName
      });
      expect(response.body.user).not.toHaveProperty('password');
    });

    it('should return 409 when registering with existing email', async () => {
      // First registration
      await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(201);

      // Second registration with same email
      const response = await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(409);

      expect(response.body).toHaveProperty('error', 'User with this email already exists');
    });

    it('should return 400 with invalid email format', async () => {
      const invalidUser = { ...testUser, email: 'invalid-email' };
      
      const response = await request(app)
        .post('/api/auth/register')
        .send(invalidUser)
        .expect(400);

      expect(response.body).toHaveProperty('errors');
      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            path: 'email'
          })
        ])
      );
    });

    it('should return 400 with short password', async () => {
      const invalidUser = { ...testUser, password: '123' };
      
      const response = await request(app)
        .post('/api/auth/register')
        .send(invalidUser)
        .expect(400);

      expect(response.body).toHaveProperty('errors');
      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            path: 'password',
            msg: 'Password must be at least 6 characters'
          })
        ])
      );
    });

    it('should return 400 with missing required fields', async () => {
      const invalidUser = { email: testUser.email };
      
      const response = await request(app)
        .post('/api/auth/register')
        .send(invalidUser)
        .expect(400);

      expect(response.body).toHaveProperty('errors');
      expect(response.body.errors.length).toBeGreaterThan(0);
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      // Register user before each login test
      await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(201);
    });

    it('should login with valid credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password
        })
        .expect(200);

      expect(response.body).toHaveProperty('message', 'Login successful');
      expect(response.body).toHaveProperty('token');
      expect(response.body.user).toMatchObject({
        email: testUser.email,
        firstName: testUser.firstName,
        lastName: testUser.lastName
      });
      expect(response.body.user).not.toHaveProperty('password');
    });

    it('should return 401 with incorrect password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: 'wrongpassword'
        })
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Invalid email or password');
      expect(response.body).not.toHaveProperty('token');
    });

    it('should return 401 with non-existent email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: testUser.password
        })
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Invalid email or password');
      expect(response.body).not.toHaveProperty('token');
    });

    it('should return 400 with invalid email format', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'invalid-email',
          password: testUser.password
        })
        .expect(400);

      expect(response.body).toHaveProperty('errors');
    });

    it('should return 400 with missing password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email
        })
        .expect(400);

      expect(response.body).toHaveProperty('errors');
      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            path: 'password',
            msg: 'Password is required'
          })
        ])
      );
    });
  });

  describe('GET /api/auth/me', () => {
    let authToken;

    beforeEach(async () => {
      // Register and login to get token
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(201);
      
      authToken = registerResponse.body.token;
    });

    it('should return current user with valid token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.user).toMatchObject({
        email: testUser.email,
        firstName: testUser.firstName,
        lastName: testUser.lastName
      });
    });

    it('should return 401 without token', async () => {
      await request(app)
        .get('/api/auth/me')
        .expect(401);
    });

    it('should return 401 with invalid token', async () => {
      await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });

  describe('PUT /api/auth/me', () => {
    let authToken;

    beforeEach(async () => {
      // Register and login to get token
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(201);
      
      authToken = registerResponse.body.token;
    });

    it('should update user profile with valid data', async () => {
      const updateData = {
        firstName: 'Updated',
        lastName: 'Name',
        phone: '+12125551234'  // Valid US phone number
      };

      const response = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(200);

      expect(response.body).toHaveProperty('message', 'Profile updated successfully');
      expect(response.body.user).toMatchObject({
        firstName: updateData.firstName,
        lastName: updateData.lastName,
        phone: updateData.phone
      });
    });

    it('should return 401 without token', async () => {
      await request(app)
        .put('/api/auth/me')
        .send({ firstName: 'Updated' })
        .expect(401);
    });

    it('should return 400 with invalid phone format', async () => {
      const response = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ phone: 'invalid-phone' })
        .expect(400);

      expect(response.body).toHaveProperty('errors');
    });
  });
});