const request = require('supertest');
const express = require('express');
const cors = require('cors');
const authRoutes = require('../routes/auth');
const CheckIn = require('../models/CheckIn');
const DogPark = require('../models/DogPark');

// Create test app
const createTestApp = () => {
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  return app;
};

describe('CheckIn Model', () => {
  let app;
  let testUser;
  let authToken;
  let testPark;
  let userId;

  beforeAll(() => {
    app = createTestApp();
  });

  beforeEach(async () => {
    // Create and authenticate test user
    testUser = {
      email: 'checkintest@example.com',
      password: 'password123',
      firstName: 'CheckIn',
      lastName: 'Tester'
    };

    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send(testUser)
      .expect(201);
    
    authToken = registerResponse.body.token;
    userId = registerResponse.body.user.id;

    // Create a test park
    testPark = await DogPark.create({
      name: 'CheckIn Test Park',
      description: 'A test park for check-in testing',
      address: '789 CheckIn Street, Test City, TC 54321',
      latitude: 34.0522,
      longitude: -118.2437,
      amenities: ['Off-leash area', 'Water fountains'],
      rules: 'Test check-in rules',
      hoursOpen: '06:00:00',
      hoursClose: '22:00:00'
    });
  });

  describe('CheckIn.create()', () => {
    it('should create a new check-in successfully', async () => {
      const checkInData = {
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: [1, 2, 3]
      };

      const checkIn = await CheckIn.create(checkInData);

      expect(checkIn).toMatchObject({
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: [1, 2, 3]
      });
      expect(checkIn).toHaveProperty('id');
      expect(checkIn).toHaveProperty('checkedInAt');
      expect(checkIn.checkedOutAt).toBeNull();
    });

    it('should create check-in with empty dogs array when not provided', async () => {
      const checkInData = {
        userId: userId,
        dogParkId: testPark.id
      };

      const checkIn = await CheckIn.create(checkInData);

      expect(checkIn.dogsPresent).toEqual([]);
    });
  });

  describe('CheckIn.findActiveByUser()', () => {
    it('should find active check-ins for user', async () => {
      await CheckIn.create({
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: [1]
      });

      const activeCheckIns = await CheckIn.findActiveByUser(userId);

      expect(activeCheckIns).toHaveLength(1);
      expect(activeCheckIns[0]).toMatchObject({
        userId: userId,
        dogParkId: testPark.id
      });
      expect(activeCheckIns[0]).toHaveProperty('parkName', testPark.name);
    });

    it('should return empty array when no active check-ins', async () => {
      const activeCheckIns = await CheckIn.findActiveByUser(userId);
      expect(activeCheckIns).toHaveLength(0);
    });
  });

  describe('CheckIn.findActiveByPark()', () => {
    it('should find active check-ins for park', async () => {
      await CheckIn.create({
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: []
      });

      const activeCheckIns = await CheckIn.findActiveByPark(testPark.id);

      expect(activeCheckIns).toHaveLength(1);
      expect(activeCheckIns[0]).toMatchObject({
        userId: userId,
        dogParkId: testPark.id
      });
    });
  });

  describe('CheckIn.findByUserAndPark()', () => {
    it('should find active check-in for specific user and park', async () => {
      const createdCheckIn = await CheckIn.create({
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: [1, 2]
      });

      const foundCheckIn = await CheckIn.findByUserAndPark(userId, testPark.id);

      expect(foundCheckIn).toMatchObject({
        id: createdCheckIn.id,
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: [1, 2]
      });
    });

    it('should return null when no active check-in found', async () => {
      const foundCheckIn = await CheckIn.findByUserAndPark(userId, testPark.id);
      expect(foundCheckIn).toBeNull();
    });
  });

  describe('CheckIn.checkOut()', () => {
    let checkInId;

    beforeEach(async () => {
      const checkIn = await CheckIn.create({
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: []
      });
      checkInId = checkIn.id;
    });

    it('should check out successfully', async () => {
      const checkedOut = await CheckIn.checkOut(checkInId, userId);

      expect(checkedOut).toMatchObject({
        id: checkInId,
        userId: userId,
        dogParkId: testPark.id
      });
      expect(checkedOut.checkedOutAt).not.toBeNull();
    });

    it('should return null for invalid check-in ID', async () => {
      const checkedOut = await CheckIn.checkOut(99999, userId);
      expect(checkedOut).toBeNull();
    });

    it('should return null for wrong user ID', async () => {
      const checkedOut = await CheckIn.checkOut(checkInId, 99999);
      expect(checkedOut).toBeNull();
    });
  });

  describe('CheckIn.checkOutByPark()', () => {
    beforeEach(async () => {
      await CheckIn.create({
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: []
      });
    });

    it('should check out by park successfully', async () => {
      const checkedOut = await CheckIn.checkOutByPark(userId, testPark.id);

      expect(checkedOut).toMatchObject({
        userId: userId,
        dogParkId: testPark.id
      });
      expect(checkedOut.checkedOutAt).not.toBeNull();
    });

    it('should return null when no active check-in found', async () => {
      // First checkout
      await CheckIn.checkOutByPark(userId, testPark.id);
      
      // Second checkout attempt
      const checkedOut = await CheckIn.checkOutByPark(userId, testPark.id);
      expect(checkedOut).toBeNull();
    });
  });

  describe('CheckIn.getParkActivityStats()', () => {
    beforeEach(async () => {
      // Create some test check-ins
      await CheckIn.create({
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: []
      });
    });

    it('should return activity statistics', async () => {
      const stats = await CheckIn.getParkActivityStats(testPark.id);

      expect(stats).toHaveProperty('totalCheckIns');
      expect(stats).toHaveProperty('currentCheckIns');
      expect(stats).toHaveProperty('averageVisitMinutes');
      expect(typeof stats.totalCheckIns).toBe('number');
      expect(typeof stats.currentCheckIns).toBe('number');
      expect(typeof stats.averageVisitMinutes).toBe('number');
    });

    it('should return zeros for park with no activity', async () => {
      // Create another park
      const emptyPark = await DogPark.create({
        name: 'Empty Test Park',
        description: 'Park with no activity',
        address: '999 Empty Street, Test City, TC 99999',
        latitude: 35.0522,
        longitude: -119.2437,
        amenities: [],
        rules: 'Empty park rules',
        hoursOpen: '06:00:00',
        hoursClose: '22:00:00'
      });

      const stats = await CheckIn.getParkActivityStats(emptyPark.id);

      expect(stats.totalCheckIns).toBe(0);
      expect(stats.currentCheckIns).toBe(0);
      expect(stats.averageVisitMinutes).toBe(0);
    });

    it('should respect time window parameter', async () => {
      const statsLast24Hours = await CheckIn.getParkActivityStats(testPark.id, 24);
      const statsLastHour = await CheckIn.getParkActivityStats(testPark.id, 1);

      expect(typeof statsLast24Hours.totalCheckIns).toBe('number');
      expect(typeof statsLastHour.totalCheckIns).toBe('number');
    });
  });

  describe('CheckIn.getRecentHistory()', () => {
    beforeEach(async () => {
      // Create and complete a check-in
      const checkIn = await CheckIn.create({
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: [1]
      });
      await CheckIn.checkOut(checkIn.id, userId);
    });

    it('should return recent check-in history', async () => {
      const history = await CheckIn.getRecentHistory(userId);

      expect(Array.isArray(history)).toBe(true);
      expect(history.length).toBeGreaterThan(0);
      expect(history[0]).toMatchObject({
        userId: userId,
        dogParkId: testPark.id
      });
      expect(history[0]).toHaveProperty('parkName');
    });

    it('should respect limit parameter', async () => {
      const history = await CheckIn.getRecentHistory(userId, 1);
      expect(history).toHaveLength(1);
    });

    it('should return empty array for user with no history', async () => {
      // Create another user
      const anotherUser = {
        email: 'nohistory@example.com',
        password: 'password123',
        firstName: 'No',
        lastName: 'History'
      };

      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(anotherUser)
        .expect(201);

      const history = await CheckIn.getRecentHistory(registerResponse.body.user.id);
      expect(history).toHaveLength(0);
    });
  });

  describe('CheckIn.formatCheckIn()', () => {
    it('should format check-in data correctly', async () => {
      const checkIn = await CheckIn.create({
        userId: userId,
        dogParkId: testPark.id,
        dogsPresent: [1, 2, 3]
      });

      expect(checkIn).toHaveProperty('id');
      expect(checkIn).toHaveProperty('userId', userId);
      expect(checkIn).toHaveProperty('dogParkId', testPark.id);
      expect(checkIn).toHaveProperty('dogsPresent', [1, 2, 3]);
      expect(checkIn).toHaveProperty('checkedInAt');
      expect(checkIn.checkedOutAt).toBeNull();
    });

    it('should handle null input', () => {
      const formatted = CheckIn.formatCheckIn(null);
      expect(formatted).toBeNull();
    });
  });
});