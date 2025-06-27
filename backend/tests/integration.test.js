const request = require('supertest');
const express = require('express');
const cors = require('cors');
const authRoutes = require('../routes/auth');
const dogsRoutes = require('../routes/dogs');

// Create test app with full route setup
const createTestApp = () => {
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  app.use('/api/dogs', dogsRoutes);
  return app;
};

describe('Integration Tests - Full Authentication Flow', () => {
  let app;

  beforeAll(() => {
    app = createTestApp();
  });

  describe('End-to-End Authentication Flow', () => {
    let userToken;
    const testUser = {
      email: 'integration@test.com',
      password: 'integration123',
      firstName: 'Integration',
      lastName: 'Test'
    };

    it('should complete full registration → login → protected route flow', async () => {
      // Step 1: Register new user
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(201);

      expect(registerResponse.body).toHaveProperty('message', 'User created successfully');
      expect(registerResponse.body).toHaveProperty('token');
      expect(registerResponse.body.user.email).toBe(testUser.email);

      const registrationToken = registerResponse.body.token;

      // Step 2: Access protected route with registration token
      const profileResponse = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${registrationToken}`)
        .expect(200);

      expect(profileResponse.body.user.email).toBe(testUser.email);

      // Step 3: Login with same credentials
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password
        })
        .expect(200);

      expect(loginResponse.body).toHaveProperty('message', 'Login successful');
      expect(loginResponse.body).toHaveProperty('token');
      expect(loginResponse.body.user.email).toBe(testUser.email);

      userToken = loginResponse.body.token;

      // Step 4: Access protected route with login token
      const secondProfileResponse = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(secondProfileResponse.body.user.email).toBe(testUser.email);

      // Step 5: Update profile
      const updateResponse = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          firstName: 'Updated',
          phone: '+12125551234'
        })
        .expect(200);

      expect(updateResponse.body.user.firstName).toBe('Updated');
      expect(updateResponse.body.user.phone).toBe('+12125551234');
    });

    it('should handle authentication errors correctly in full flow', async () => {
      // Step 1: Try to register user that already exists
      const duplicateUser = {
        email: 'duplicate@test.com',
        password: 'duplicate123',
        firstName: 'Duplicate',
        lastName: 'Test'
      };
      
      // First register the user
      await request(app)
        .post('/api/auth/register')
        .send(duplicateUser)
        .expect(201);
      
      // Now try to register again
      const duplicateResponse = await request(app)
        .post('/api/auth/register')
        .send(duplicateUser)
        .expect(409);

      expect(duplicateResponse.body).toHaveProperty('error', 'User with this email already exists');

      // Step 2: Try to login with wrong password
      const wrongPasswordResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: duplicateUser.email,
          password: 'wrongpassword'
        })
        .expect(401);

      expect(wrongPasswordResponse.body).toHaveProperty('error', 'Invalid email or password');

      // Step 3: Try to access protected route without token
      await request(app)
        .get('/api/auth/me')
        .expect(401);

      // Step 4: Try to access protected route with invalid token
      await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);

      // Step 5: Try to login with non-existent user
      const nonExistentResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@test.com',
          password: 'anypassword'
        })
        .expect(401);

      expect(nonExistentResponse.body).toHaveProperty('error', 'Invalid email or password');
    });

    it('should maintain authentication state across requests', async () => {
      // Create a fresh user and login
      const persistUser = {
        email: 'persist@test.com',
        password: 'persist123',
        firstName: 'Persist',
        lastName: 'Test'
      };
      
      const registerRes = await request(app)
        .post('/api/auth/register')
        .send(persistUser)
        .expect(201);
        
      const token = registerRes.body.token;

      // Make multiple authenticated requests
      for (let i = 0; i < 3; i++) {
        const response = await request(app)
          .get('/api/auth/me')
          .set('Authorization', `Bearer ${token}`)
          .expect(200);

        expect(response.body.user.email).toBe(persistUser.email);
      }
    });
  });

  describe('Authentication + Dogs API Integration', () => {
    let authToken;
    const testUser = {
      email: 'dogs@test.com',
      password: 'dogstest123',
      firstName: 'Dog',
      lastName: 'Owner'
    };

    beforeEach(async () => {
      // Create a unique user for each test to avoid conflicts
      const uniqueEmail = `dogs${Date.now()}@test.com`;
      const uniqueUser = {
        ...testUser,
        email: uniqueEmail
      };
      
      // Register and get token
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(uniqueUser)
        .expect(201);

      authToken = registerResponse.body.token;
    });

    it('should access dogs API with valid authentication', async () => {
      // Access dogs endpoint with authentication
      const dogsResponse = await request(app)
        .get('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(dogsResponse.body).toHaveProperty('dogs');
      expect(Array.isArray(dogsResponse.body.dogs)).toBe(true);
    });

    it('should reject dogs API access without authentication', async () => {
      // Try to access dogs endpoint without token
      await request(app)
        .get('/api/dogs')
        .expect(401);

      // Try with invalid token
      await request(app)
        .get('/api/dogs')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });

    it('should create dog with valid authentication', async () => {
      const dogData = {
        name: 'Test Dog',
        breed: 'Test Breed',
        birthday: '2020-01-01',
        weight: 25.5,
        gender: 'male',
        sizeCategory: 'medium',
        energyLevel: 'medium',
        friendlinessDogs: 4,
        friendlinessPeople: 5,
        trainingLevel: 'basic',
        favoriteActivities: ['fetch', 'walk'],
        isVaccinated: true,
        isSpayedNeutered: false,
        bio: 'A test dog for integration testing'
      };

      const createResponse = await request(app)
        .post('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`)
        .send(dogData)
        .expect(201);

      expect(createResponse.body).toHaveProperty('message', 'Dog profile created successfully');
      expect(createResponse.body.dog.name).toBe(dogData.name);
      expect(createResponse.body.dog.breed).toBe(dogData.breed);
    });
  });

  describe('Session Management', () => {
    const sessionUser = {
      email: 'session@test.com',
      password: 'session123',
      firstName: 'Session',
      lastName: 'Test'
    };

    it('should handle multiple concurrent sessions', async () => {
      // Register user
      await request(app)
        .post('/api/auth/register')
        .send(sessionUser)
        .expect(201);

      // Create multiple login sessions
      const session1 = await request(app)
        .post('/api/auth/login')
        .send({
          email: sessionUser.email,
          password: sessionUser.password
        })
        .expect(200);

      const session2 = await request(app)
        .post('/api/auth/login')
        .send({
          email: sessionUser.email,
          password: sessionUser.password
        })
        .expect(200);

      // Both tokens should be valid
      await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${session1.body.token}`)
        .expect(200);

      await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${session2.body.token}`)
        .expect(200);
    });
  });

  describe('Error Response Consistency', () => {
    it('should return consistent error formats across all endpoints', async () => {
      // Test validation error format consistency
      const validationError = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'invalid-email',
          password: '123', // Too short
          firstName: '', // Empty
          lastName: 'Valid'
        })
        .expect(400);

      expect(validationError.body).toHaveProperty('errors');
      expect(Array.isArray(validationError.body.errors)).toBe(true);
      expect(validationError.body.errors.length).toBeGreaterThan(0);

      // Test single error format consistency
      const singleError = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@test.com',
          password: 'anypassword'
        })
        .expect(401);

      expect(singleError.body).toHaveProperty('error');
      expect(typeof singleError.body.error).toBe('string');
    });

    it('should provide meaningful error messages for authentication failures', async () => {
      // Wrong password
      const testUser = {
        email: 'errortest@example.com',
        password: 'correctpass',
        firstName: 'Error',
        lastName: 'Test'
      };

      await request(app)
        .post('/api/auth/register')
        .send(testUser)
        .expect(201);

      const wrongPasswordResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: 'wrongpass'
        })
        .expect(401);

      expect(wrongPasswordResponse.body.error).toBe('Invalid email or password');

      // Non-existent email
      const nonExistentResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'doesnotexist@test.com',
          password: 'anypass'
        })
        .expect(401);

      expect(nonExistentResponse.body.error).toBe('Invalid email or password');
    });
  });
});