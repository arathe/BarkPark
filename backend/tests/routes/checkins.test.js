const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');
const DogPark = require('../../models/DogPark');
const Dog = require('../../models/Dog');
const CheckIn = require('../../models/CheckIn');
const Friendship = require('../../models/Friendship');
const pool = require('../../config/database');
const jwt = require('jsonwebtoken');

describe('Check-In API Routes', () => {
  let user1, user2, user3;
  let authToken1, authToken2, authToken3;
  let park1, park2;
  let dog1, dog2;
  
  beforeEach(async () => {
    // Create test users
    user1 = await User.create({
      email: 'checkinapi1@test.com',
      password: 'password123',
      firstName: 'CheckIn',
      lastName: 'User1'
    });
    
    user2 = await User.create({
      email: 'checkinapi2@test.com',
      password: 'password123',
      firstName: 'CheckIn',
      lastName: 'User2'
    });
    
    user3 = await User.create({
      email: 'checkinapi3@test.com',
      password: 'password123',
      firstName: 'CheckIn',
      lastName: 'User3'
    });
    
    // Generate auth tokens
    authToken1 = jwt.sign({ id: user1.id, email: user1.email }, process.env.JWT_SECRET);
    authToken2 = jwt.sign({ id: user2.id, email: user2.email }, process.env.JWT_SECRET);
    authToken3 = jwt.sign({ id: user3.id, email: user3.email }, process.env.JWT_SECRET);
    
    // Create test parks
    park1 = await DogPark.create({
      name: 'API Test Park 1',
      address: '123 API Test St',
      latitude: 40.7128,
      longitude: -74.0060,
      hoursOpen: '06:00',
      hoursClose: '22:00',
      amenities: ['water', 'benches'],
      rules: 'Dogs must be leashed in common areas'
    });
    
    park2 = await DogPark.create({
      name: 'API Test Park 2',
      address: '456 API Test Ave',
      latitude: 40.7589,
      longitude: -73.9851,
      hoursOpen: '07:00',
      hoursClose: '21:00'
    });
    
    // Create test dogs
    dog1 = await Dog.create({
      userId: user1.id,
      name: 'API Test Dog 1',
      breed: 'Golden Retriever',
      age: 3
    });
    
    dog2 = await Dog.create({
      userId: user1.id,
      name: 'API Test Dog 2',
      breed: 'Poodle',
      age: 2
    });
  });

  afterEach(async () => {
    // Clean up
    await pool.query('DELETE FROM checkins WHERE user_id IN ($1, $2, $3)', [user1.id, user2.id, user3.id]);
    await pool.query('DELETE FROM dogs WHERE user_id IN ($1, $2, $3)', [user1.id, user2.id, user3.id]);
    await pool.query('DELETE FROM dog_parks WHERE id IN ($1, $2)', [park1.id, park2.id]);
    await pool.query('DELETE FROM friendships WHERE requester_id IN ($1, $2, $3) OR addressee_id IN ($1, $2, $3)', 
      [user1.id, user2.id, user3.id]);
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3)', [user1.id, user2.id, user3.id]);
  });

  describe('POST /api/parks/:id/checkin', () => {
    test('should check in successfully', async () => {
      const response = await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ dogsPresent: [dog1.id] })
        .expect(201);

      expect(response.body.message).toBe('Checked in successfully');
      expect(response.body.checkIn).toMatchObject({
        userId: user1.id,
        dogParkId: park1.id,
        dogsPresent: [dog1.id]
      });
      expect(response.body.checkIn.checkedOutAt).toBeNull();
    });

    test('should check in without dogs', async () => {
      const response = await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .send({})
        .expect(201);

      expect(response.body.checkIn.dogsPresent).toEqual([]);
    });

    test('should check in with multiple dogs', async () => {
      const response = await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ dogsPresent: [dog1.id, dog2.id] })
        .expect(201);

      expect(response.body.checkIn.dogsPresent).toHaveLength(2);
      expect(response.body.checkIn.dogsPresent).toContain(dog1.id);
      expect(response.body.checkIn.dogsPresent).toContain(dog2.id);
    });

    test('should prevent duplicate check-in at same park', async () => {
      // First check-in
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ dogsPresent: [dog1.id] })
        .expect(201);

      // Duplicate check-in attempt
      const response = await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ dogsPresent: [dog2.id] })
        .expect(400);

      expect(response.body.error).toBe('Already checked in to this park');
      expect(response.body.checkIn).toBeDefined();
    });

    test('should allow check-in at different parks simultaneously', async () => {
      // Check in at park 1
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      // Check in at park 2
      const response = await request(app)
        .post(`/api/parks/${park2.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      expect(response.body.checkIn.dogParkId).toBe(park2.id);
    });

    test('should handle non-existent park', async () => {
      await request(app)
        .post('/api/parks/99999/checkin')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(404);
    });

    test('should validate dogs present array', async () => {
      const response = await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ dogsPresent: 'not-an-array' })
        .expect(400);

      expect(response.body.errors).toBeDefined();
    });

    test('should require authentication', async () => {
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .send({ dogsPresent: [] })
        .expect(401);
    });
  });

  describe('PUT /api/parks/:id/checkout', () => {
    test('should check out successfully', async () => {
      // Check in first
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      // Check out
      const response = await request(app)
        .put(`/api/parks/${park1.id}/checkout`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.message).toBe('Checked out successfully');
      expect(response.body.checkOut.checkedOutAt).toBeDefined();
    });

    test('should handle no active check-in', async () => {
      const response = await request(app)
        .put(`/api/parks/${park1.id}/checkout`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(400);

      expect(response.body.error).toBe('No active check-in found for this park');
    });

    test('should not check out another user\'s check-in', async () => {
      // User 1 checks in
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      // User 2 tries to check out
      const response = await request(app)
        .put(`/api/parks/${park1.id}/checkout`)
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(400);

      expect(response.body.error).toBe('No active check-in found for this park');
    });

    test('should handle double check-out', async () => {
      // Check in
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      // First check out
      await request(app)
        .put(`/api/parks/${park1.id}/checkout`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      // Second check out attempt
      const response = await request(app)
        .put(`/api/parks/${park1.id}/checkout`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(400);

      expect(response.body.error).toBe('No active check-in found for this park');
    });
  });

  describe('GET /api/parks/user/active', () => {
    test('should return empty array when no active check-ins', async () => {
      const response = await request(app)
        .get('/api/parks/user/active')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.activeCheckIns).toEqual([]);
      expect(response.body.total).toBe(0);
    });

    test('should return active check-ins', async () => {
      // Check in at two parks
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      await request(app)
        .post(`/api/parks/${park2.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      const response = await request(app)
        .get('/api/parks/user/active')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.total).toBe(2);
      expect(response.body.activeCheckIns).toHaveLength(2);
      expect(response.body.activeCheckIns[0].parkName).toBeDefined();
    });

    test('should not include checked-out visits', async () => {
      // Check in and out
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      await request(app)
        .put(`/api/parks/${park1.id}/checkout`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      // Check in at another park
      await request(app)
        .post(`/api/parks/${park2.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      const response = await request(app)
        .get('/api/parks/user/active')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.total).toBe(1);
      expect(response.body.activeCheckIns[0].dogParkId).toBe(park2.id);
    });
  });

  describe('GET /api/parks/user/history', () => {
    test('should return check-in history', async () => {
      // Create multiple check-ins
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      await request(app)
        .put(`/api/parks/${park1.id}/checkout`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      await request(app)
        .post(`/api/parks/${park2.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      const response = await request(app)
        .get('/api/parks/user/history')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.history).toHaveLength(2);
      expect(response.body.total).toBe(2);
      // Most recent first
      expect(response.body.history[0].dogParkId).toBe(park2.id);
    });

    test('should respect limit parameter', async () => {
      // Create many check-ins
      for (let i = 0; i < 15; i++) {
        await CheckIn.create({
          userId: user1.id,
          dogParkId: i % 2 === 0 ? park1.id : park2.id
        });
      }

      const response = await request(app)
        .get('/api/parks/user/history?limit=5')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.history).toHaveLength(5);
    });

    test('should handle invalid limit', async () => {
      const response = await request(app)
        .get('/api/parks/user/history?limit=invalid')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      // Should use default limit
      expect(response.body.history).toBeDefined();
    });
  });

  describe('GET /api/parks/:id/activity', () => {
    test('should return park activity stats', async () => {
      // Create some check-ins
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(201);

      const response = await request(app)
        .get(`/api/parks/${park1.id}/activity`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body).toMatchObject({
        parkId: park1.id,
        activityLevel: expect.any(String),
        stats: {
          totalCheckIns: expect.any(Number),
          currentCheckIns: 2,
          averageVisitMinutes: expect.any(Number)
        },
        activeVisitors: expect.any(Array),
        lastUpdated: expect.any(String)
      });
    });

    test('should handle park not found', async () => {
      await request(app)
        .get('/api/parks/99999/activity')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(404);
    });
  });

  describe('GET /api/parks/:id/friends', () => {
    test('should return friends at park', async () => {
      // Create friendship
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship.id, user2.id);

      // Both check in
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(201);

      const response = await request(app)
        .get(`/api/parks/${park1.id}/friends`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.friendsPresent).toBe(1);
      expect(response.body.friends).toHaveLength(1);
      expect(response.body.friends[0].userId).toBe(user2.id);
    });

    test('should not include non-friends', async () => {
      // No friendship, both check in
      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(201);

      const response = await request(app)
        .get(`/api/parks/${park1.id}/friends`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.friendsPresent).toBe(0);
      expect(response.body.friends).toEqual([]);
    });
  });

  describe('Concurrent check-in scenarios', () => {
    test('should handle multiple users checking in simultaneously', async () => {
      const promises = [
        request(app)
          .post(`/api/parks/${park1.id}/checkin`)
          .set('Authorization', `Bearer ${authToken1}`)
          .send({ dogsPresent: [] }),
        request(app)
          .post(`/api/parks/${park1.id}/checkin`)
          .set('Authorization', `Bearer ${authToken2}`)
          .send({ dogsPresent: [] }),
        request(app)
          .post(`/api/parks/${park1.id}/checkin`)
          .set('Authorization', `Bearer ${authToken3}`)
          .send({ dogsPresent: [] })
      ];

      const results = await Promise.allSettled(promises);
      
      // All should succeed
      const succeeded = results.filter(r => r.status === 'fulfilled' && r.value.status === 201);
      expect(succeeded.length).toBe(3);

      // Verify all are active
      const activity = await request(app)
        .get(`/api/parks/${park1.id}/activity`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(activity.body.stats.currentCheckIns).toBe(3);
    });

    test('should handle rapid check-in/check-out cycles', async () => {
      // Rapid cycles
      for (let i = 0; i < 5; i++) {
        await request(app)
          .post(`/api/parks/${park1.id}/checkin`)
          .set('Authorization', `Bearer ${authToken1}`)
          .expect(201);

        await request(app)
          .put(`/api/parks/${park1.id}/checkout`)
          .set('Authorization', `Bearer ${authToken1}`)
          .expect(200);
      }

      // Should have no active check-ins
      const active = await request(app)
        .get('/api/parks/user/active')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(active.body.total).toBe(0);

      // Should have 5 in history
      const history = await request(app)
        .get('/api/parks/user/history')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(history.body.history.length).toBe(5);
    });
  });

  describe('Time-sensitive edge cases', () => {
    test('should handle check-ins at park closing time', async () => {
      // Set park hours to be nearly closed
      const now = new Date();
      const closeTime = `${now.getHours()}:${String(now.getMinutes() + 1).padStart(2, '0')}:00`;
      
      await pool.query('UPDATE dog_parks SET hours_close = $1 WHERE id = $2', [closeTime, park1.id]);

      // Should still allow check-in (business logic would handle warnings)
      const response = await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(201);

      expect(response.body.checkIn).toBeDefined();
    });

    test('should track long visits accurately', async () => {
      // Create check-in with timestamp 3 hours ago
      const oldTime = new Date();
      oldTime.setHours(oldTime.getHours() - 3);

      const result = await pool.query(`
        INSERT INTO checkins (user_id, dog_park_id, dogs_present, checked_in_at)
        VALUES ($1, $2, $3, $4)
        RETURNING *
      `, [user1.id, park1.id, [], oldTime]);

      const checkInId = result.rows[0].id;

      // Check out
      await CheckIn.checkOut(checkInId, user1.id);

      // Get stats
      const stats = await CheckIn.getParkActivityStats(park1.id);
      
      // Average visit should reflect the long visit
      expect(stats.averageVisitMinutes).toBeGreaterThan(150); // > 2.5 hours
    });
  });

  describe('Error handling and validation', () => {
    test('should handle database errors gracefully', async () => {
      // Try to check in with invalid dog ID
      const response = await request(app)
        .post(`/api/parks/${park1.id}/checkin`)
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ dogsPresent: [99999] })
        .expect(500);

      expect(response.body.error).toBeDefined();
    });

    test('should validate park ID format', async () => {
      await request(app)
        .post('/api/parks/not-a-number/checkin')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(404);
    });

    test('should handle missing authentication gracefully', async () => {
      const endpoints = [
        { method: 'post', url: `/api/parks/${park1.id}/checkin` },
        { method: 'put', url: `/api/parks/${park1.id}/checkout` },
        { method: 'get', url: '/api/parks/user/active' },
        { method: 'get', url: '/api/parks/user/history' }
      ];

      for (const endpoint of endpoints) {
        await request(app)[endpoint.method](endpoint.url).expect(401);
      }
    });
  });
});