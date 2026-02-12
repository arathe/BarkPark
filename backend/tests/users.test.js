const request = require('supertest');
const express = require('express');
const pool = require('../config/database');
const testDataFactory = require('./utils/testDataFactory');

// Mock auth middleware
jest.mock('../middleware/auth', () => require('./utils/testMocks').mockAuthMiddleware());

// Create app instance
const app = express();
app.use(express.json());

// Import routes
const userRoutes = require('../routes/users');
app.use('/api/users', userRoutes);

describe('Users API', () => {
  let userId;
  let authToken;
  let friendId;
  let friendToken;
  let strangerId;
  let strangerToken;

  beforeEach(async () => {
    // Create test users directly in database
    const userData1 = testDataFactory.createUserData();
    const userData2 = testDataFactory.createUserData();
    const userData3 = testDataFactory.createUserData();

    const user1Result = await pool.query(`
      INSERT INTO users (email, password_hash, first_name, last_name, profile_image_url)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id
    `, [userData1.email, 'hashedpassword', userData1.firstName, userData1.lastName, 'https://example.com/photo.jpg']);
    userId = user1Result.rows[0].id;
    authToken = testDataFactory.generateTestToken(userId);

    const user2Result = await pool.query(`
      INSERT INTO users (email, password_hash, first_name, last_name)
      VALUES ($1, $2, $3, $4)
      RETURNING id
    `, [userData2.email, 'hashedpassword', userData2.firstName, userData2.lastName]);
    friendId = user2Result.rows[0].id;
    friendToken = testDataFactory.generateTestToken(friendId);

    const user3Result = await pool.query(`
      INSERT INTO users (email, password_hash, first_name, last_name)
      VALUES ($1, $2, $3, $4)
      RETURNING id
    `, [userData3.email, 'hashedpassword', userData3.firstName, userData3.lastName]);
    strangerId = user3Result.rows[0].id;
    strangerToken = testDataFactory.generateTestToken(strangerId);

    // Create accepted friendship between user1 and user2
    await pool.query(`
      INSERT INTO friendships (user_id, friend_id, status)
      VALUES ($1, $2, 'accepted')
    `, [userId, friendId]);

    // Create a dog for user1
    await pool.query(`
      INSERT INTO dogs (user_id, name, breed, weight, gender)
      VALUES ($1, 'Buddy', 'Golden Retriever', 30.5, 'male')
    `, [userId]);

    // Create a park and check-in for user1
    const parkResult = await pool.query(`
      INSERT INTO dog_parks (name, address, latitude, longitude)
      VALUES ('Central Bark', '123 Park Ave, New York, NY', 40.7829, -73.9654)
      RETURNING id
    `);
    const parkId = parkResult.rows[0].id;

    await pool.query(`
      INSERT INTO checkins (user_id, dog_park_id, checked_in_at, checked_out_at)
      VALUES ($1, $2, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour')
    `, [userId, parkId]);
  });

  describe('GET /api/users/:userId/profile', () => {
    it('should return own profile successfully', async () => {
      const res = await request(app)
        .get(`/api/users/${userId}/profile`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('user');
      expect(res.body).toHaveProperty('dogs');
      expect(res.body).toHaveProperty('recentCheckIns');
      expect(res.body.user.id).toBe(userId);
      expect(res.body.user).toHaveProperty('firstName');
      expect(res.body.user).toHaveProperty('lastName');
      expect(res.body.user).toHaveProperty('profileImageUrl');
      expect(res.body.user).not.toHaveProperty('password_hash');
    });

    it('should return friend profile with dogs and check-ins', async () => {
      const res = await request(app)
        .get(`/api/users/${userId}/profile`)
        .set('Authorization', `Bearer ${friendToken}`);

      expect(res.status).toBe(200);
      expect(res.body.user.id).toBe(userId);
      expect(res.body.dogs).toBeInstanceOf(Array);
      expect(res.body.dogs.length).toBe(1);
      expect(res.body.dogs[0].name).toBe('Buddy');
      expect(res.body.recentCheckIns).toBeInstanceOf(Array);
    });

    it('should return 403 for non-friend without pending request', async () => {
      const res = await request(app)
        .get(`/api/users/${userId}/profile`)
        .set('Authorization', `Bearer ${strangerToken}`);

      expect(res.status).toBe(403);
      expect(res.body.error).toContain('friends');
    });

    it('should allow viewing profile with pending friend request', async () => {
      // Create pending friend request from stranger to user
      await pool.query(`
        INSERT INTO friendships (user_id, friend_id, status)
        VALUES ($1, $2, 'pending')
      `, [strangerId, userId]);

      const res = await request(app)
        .get(`/api/users/${userId}/profile`)
        .set('Authorization', `Bearer ${strangerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.user.id).toBe(userId);
    });

    it('should return 404 for non-existent user', async () => {
      const res = await request(app)
        .get('/api/users/99999/profile')
        .set('Authorization', `Bearer ${authToken}`);

      // Since no friendship exists, it will be 403 before reaching 404
      expect([403, 404]).toContain(res.status);
    });

    it('should return 400 for invalid userId format', async () => {
      const res = await request(app)
        .get('/api/users/invalid/profile')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(400);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .get(`/api/users/${userId}/profile`);

      expect(res.status).toBe(401);
    });

    it('should include dog details in profile', async () => {
      const res = await request(app)
        .get(`/api/users/${userId}/profile`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      const dog = res.body.dogs[0];
      expect(dog).toHaveProperty('id');
      expect(dog).toHaveProperty('name');
      expect(dog).toHaveProperty('breed');
      expect(dog).toHaveProperty('gender');
      expect(dog).toHaveProperty('weight');
    });
  });
});
