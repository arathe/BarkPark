const request = require('supertest');
const express = require('express');
const cors = require('cors');
const authRoutes = require('../routes/auth');
const parkRoutes = require('../routes/parks');
const DogPark = require('../models/DogPark');
const CheckIn = require('../models/CheckIn');

// Create test app
const createTestApp = () => {
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  app.use('/api/parks', parkRoutes);
  return app;
};

describe('Parks API', () => {
  let app;
  let testUser;
  let authToken;
  let testPark;

  beforeAll(() => {
    app = createTestApp();
  });

  beforeEach(async () => {
    // Create and authenticate test user
    testUser = {
      email: 'parktest@example.com',
      password: 'password123',
      firstName: 'Park',
      lastName: 'Tester'
    };

    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send(testUser)
      .expect(201);
    
    authToken = registerResponse.body.token;

    // Create a test park
    testPark = await DogPark.create({
      name: 'Test Dog Park',
      description: 'A test park for unit testing',
      address: '123 Test Street, Test City, TC 12345',
      latitude: 37.7749,
      longitude: -122.4194,
      amenities: ['Off-leash area', 'Water fountains', 'Waste bags'],
      rules: 'Test rules for the park',
      hoursOpen: '06:00:00',
      hoursClose: '22:00:00'
    });
  });

  describe('GET /api/parks', () => {
    it('should get nearby parks with valid coordinates', async () => {
      const response = await request(app)
        .get('/api/parks')
        .query({
          latitude: 37.7749,
          longitude: -122.4194,
          radius: 10
        })
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('parks');
      expect(response.body).toHaveProperty('total');
      expect(response.body).toHaveProperty('radius', 10);
      expect(response.body).toHaveProperty('center');
      expect(response.body.center).toMatchObject({
        latitude: 37.7749,
        longitude: -122.4194
      });
      expect(Array.isArray(response.body.parks)).toBe(true);
    });

    it('should return 400 with invalid latitude', async () => {
      const response = await request(app)
        .get('/api/parks')
        .query({
          latitude: 95, // Invalid - outside -90 to 90 range
          longitude: -122.4194
        })
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body).toHaveProperty('errors');
      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            path: 'latitude'
          })
        ])
      );
    });

    it('should return 400 with invalid longitude', async () => {
      const response = await request(app)
        .get('/api/parks')
        .query({
          latitude: 37.7749,
          longitude: 185 // Invalid - outside -180 to 180 range
        })
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body).toHaveProperty('errors');
    });

    it('should return 401 without authentication token', async () => {
      await request(app)
        .get('/api/parks')
        .query({
          latitude: 37.7749,
          longitude: -122.4194
        })
        .expect(401);
    });

    it('should use default radius when not specified', async () => {
      const response = await request(app)
        .get('/api/parks')
        .query({
          latitude: 37.7749,
          longitude: -122.4194
        })
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('radius', 10);
    });

    it('should include activity level and current visitors for each park', async () => {
      const response = await request(app)
        .get('/api/parks')
        .query({
          latitude: 37.7749,
          longitude: -122.4194
        })
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      if (response.body.parks.length > 0) {
        const park = response.body.parks[0];
        expect(park).toHaveProperty('activityLevel');
        expect(park).toHaveProperty('currentVisitors');
        expect(['quiet', 'low', 'moderate', 'busy']).toContain(park.activityLevel);
      }
    });
  });

  describe('GET /api/parks/all', () => {
    it('should get all parks without location filtering', async () => {
      const response = await request(app)
        .get('/api/parks/all')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('parks');
      expect(Array.isArray(response.body.parks)).toBe(true);
    });

    it('should return 401 without authentication', async () => {
      await request(app)
        .get('/api/parks/all')
        .expect(401);
    });
  });

  describe('GET /api/parks/:id', () => {
    it('should get specific park details with activity information', async () => {
      const response = await request(app)
        .get(`/api/parks/${testPark.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('park');
      expect(response.body.park).toMatchObject({
        id: testPark.id,
        name: testPark.name,
        description: testPark.description,
        address: testPark.address
      });
      expect(response.body.park).toHaveProperty('activityLevel');
      expect(response.body.park).toHaveProperty('stats');
      expect(response.body.park).toHaveProperty('activeVisitors');
      expect(response.body.park).toHaveProperty('friendsPresent');
    });

    it('should return 404 for non-existent park', async () => {
      const response = await request(app)
        .get('/api/parks/99999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body).toHaveProperty('error', 'Park not found');
    });

    it('should return 401 without authentication', async () => {
      await request(app)
        .get(`/api/parks/${testPark.id}`)
        .expect(401);
    });
  });

  describe('GET /api/parks/:id/activity', () => {
    it('should get park activity information', async () => {
      const response = await request(app)
        .get(`/api/parks/${testPark.id}/activity`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('parkId', testPark.id);
      expect(response.body).toHaveProperty('activityLevel');
      expect(response.body).toHaveProperty('stats');
      expect(response.body).toHaveProperty('activeVisitors');
      expect(response.body).toHaveProperty('lastUpdated');
      expect(['quiet', 'low', 'moderate', 'busy']).toContain(response.body.activityLevel);
    });

    it('should return 404 for non-existent park', async () => {
      await request(app)
        .get('/api/parks/99999/activity')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('GET /api/parks/:id/friends', () => {
    it('should get friends at park', async () => {
      const response = await request(app)
        .get(`/api/parks/${testPark.id}/friends`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('parkId', testPark.id);
      expect(response.body).toHaveProperty('friendsPresent');
      expect(response.body).toHaveProperty('friends');
      expect(Array.isArray(response.body.friends)).toBe(true);
    });

    it('should return 404 for non-existent park', async () => {
      await request(app)
        .get('/api/parks/99999/friends')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('POST /api/parks/:id/checkin', () => {
    it('should check into park successfully', async () => {
      const response = await request(app)
        .post(`/api/parks/${testPark.id}/checkin`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ dogsPresent: [1, 2] })
        .expect(201);

      expect(response.body).toHaveProperty('message', 'Checked in successfully');
      expect(response.body).toHaveProperty('checkIn');
      expect(response.body).toHaveProperty('park');
      expect(response.body.checkIn).toMatchObject({
        userId: expect.any(Number),
        dogParkId: testPark.id,
        dogsPresent: [1, 2]
      });
    });

    it('should return 400 when already checked in', async () => {
      // First check-in
      await request(app)
        .post(`/api/parks/${testPark.id}/checkin`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);

      // Second check-in attempt
      const response = await request(app)
        .post(`/api/parks/${testPark.id}/checkin`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body).toHaveProperty('error', 'Already checked in to this park');
    });

    it('should return 404 for non-existent park', async () => {
      await request(app)
        .post('/api/parks/99999/checkin')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });

    it('should return 400 with invalid dogsPresent format', async () => {
      const response = await request(app)
        .post(`/api/parks/${testPark.id}/checkin`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ dogsPresent: 'not-an-array' })
        .expect(400);

      expect(response.body).toHaveProperty('errors');
    });
  });

  describe('PUT /api/parks/:id/checkout', () => {
    beforeEach(async () => {
      // Check in first
      await request(app)
        .post(`/api/parks/${testPark.id}/checkin`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);
    });

    it('should check out of park successfully', async () => {
      const response = await request(app)
        .put(`/api/parks/${testPark.id}/checkout`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('message', 'Checked out successfully');
      expect(response.body).toHaveProperty('checkOut');
      expect(response.body).toHaveProperty('park');
      expect(response.body.checkOut).toHaveProperty('checkedOutAt');
    });

    it('should return 400 when not checked in', async () => {
      // First checkout
      await request(app)
        .put(`/api/parks/${testPark.id}/checkout`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Second checkout attempt
      const response = await request(app)
        .put(`/api/parks/${testPark.id}/checkout`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body).toHaveProperty('error', 'No active check-in found for this park');
    });

    it('should return 404 for non-existent park', async () => {
      await request(app)
        .put('/api/parks/99999/checkout')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('GET /api/parks/user/history', () => {
    beforeEach(async () => {
      // Create some check-in history
      await request(app)
        .post(`/api/parks/${testPark.id}/checkin`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);

      await request(app)
        .put(`/api/parks/${testPark.id}/checkout`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
    });

    it('should get user check-in history', async () => {
      const response = await request(app)
        .get('/api/parks/user/history')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('history');
      expect(response.body).toHaveProperty('total');
      expect(Array.isArray(response.body.history)).toBe(true);
    });

    it('should respect limit parameter', async () => {
      const response = await request(app)
        .get('/api/parks/user/history')
        .query({ limit: 5 })
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.history.length).toBeLessThanOrEqual(5);
    });

    it('should return 401 without authentication', async () => {
      await request(app)
        .get('/api/parks/user/history')
        .expect(401);
    });
  });

  describe('GET /api/parks/user/active', () => {
    it('should get user active check-ins', async () => {
      const response = await request(app)
        .get('/api/parks/user/active')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('activeCheckIns');
      expect(response.body).toHaveProperty('total');
      expect(Array.isArray(response.body.activeCheckIns)).toBe(true);
    });

    it('should show active check-in when checked in', async () => {
      await request(app)
        .post(`/api/parks/${testPark.id}/checkin`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);

      const response = await request(app)
        .get('/api/parks/user/active')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.total).toBe(1);
      expect(response.body.activeCheckIns[0]).toMatchObject({
        dogParkId: testPark.id,
        userId: expect.any(Number)
      });
    });

    it('should return 401 without authentication', async () => {
      await request(app)
        .get('/api/parks/user/active')
        .expect(401);
    });
  });

  describe('POST /api/parks (Create Park)', () => {
    it('should create new park with valid data', async () => {
      const newPark = {
        name: 'New Test Park',
        description: 'A newly created test park',
        address: '456 New Street, New City, NC 67890',
        latitude: 40.7128,
        longitude: -74.0060,
        amenities: ['Agility equipment', 'Shade structures'],
        rules: 'New park rules',
        hoursOpen: '07:00:00',
        hoursClose: '21:00:00'
      };

      const response = await request(app)
        .post('/api/parks')
        .set('Authorization', `Bearer ${authToken}`)
        .send(newPark)
        .expect(201);

      expect(response.body).toHaveProperty('message', 'Park created successfully');
      expect(response.body).toHaveProperty('park');
      expect(response.body.park).toMatchObject({
        name: newPark.name,
        description: newPark.description,
        address: newPark.address,
        latitude: newPark.latitude,
        longitude: newPark.longitude
      });
    });

    it('should return 400 with missing required fields', async () => {
      const invalidPark = {
        description: 'Park without name'
      };

      const response = await request(app)
        .post('/api/parks')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidPark)
        .expect(400);

      expect(response.body).toHaveProperty('errors');
    });

    it('should return 400 with invalid coordinates', async () => {
      const invalidPark = {
        name: 'Invalid Park',
        address: '123 Invalid St',
        latitude: 95, // Invalid
        longitude: -74.0060
      };

      const response = await request(app)
        .post('/api/parks')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidPark)
        .expect(400);

      expect(response.body).toHaveProperty('errors');
    });

    it('should return 401 without authentication', async () => {
      await request(app)
        .post('/api/parks')
        .send({
          name: 'Unauthorized Park',
          address: '123 Test St',
          latitude: 40.7128,
          longitude: -74.0060
        })
        .expect(401);
    });
  });
});