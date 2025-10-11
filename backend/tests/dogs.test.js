const request = require('supertest');
const express = require('express');
const pool = require('../config/database');
const Dog = require('../models/Dog');
const testDataFactory = require('./utils/testDataFactory');

// Mock auth middleware
jest.mock('../middleware/auth', () => ({
  verifyToken: (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ error: 'No token provided' });
    }
    // Extract user ID from test token
    const token = authHeader.split(' ')[1];
    const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());
    req.userId = payload.userId;
    req.user = { id: payload.userId };
    next();
  }
}));

// Create app instance
const app = express();
app.use(express.json());

// Import routes
const dogRoutes = require('../routes/dogs');
app.use('/api/dogs', dogRoutes);

const createDogForUser = async (ownerId, overrides = {}) => {
  const data = {
    name: 'TestDog',
    breed: 'Mixed',
    birthday: '2020-01-01',
    weight: 30,
    bio: null,
    friendlinessDogs: 3,
    isVaccinated: true,
    ...overrides
  };

  const insertResult = await pool.query(`
    INSERT INTO dogs (primary_owner_id, name, breed, birthday, weight, bio, friendliness_dogs, is_vaccinated)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING id
  `, [
    ownerId,
    data.name,
    data.breed,
    data.birthday,
    data.weight,
    data.bio,
    data.friendlinessDogs,
    data.isVaccinated
  ]);

  const dogId = insertResult.rows[0].id;

  await pool.query(`
    INSERT INTO dog_memberships (dog_id, user_id, role, status, invited_by)
    VALUES ($1, $2, 'owner', 'active', $2)
    ON CONFLICT (dog_id, user_id) DO NOTHING
  `, [dogId, ownerId]);

  return dogId;
};

describe('Dogs API', () => {
  let authToken;
  let userId;
  let otherUserId;
  let otherAuthToken;
  let dogId;

  beforeEach(async () => {
    // Create test users using test data factory
    const userData = testDataFactory.createUserData();
    const otherUserData = testDataFactory.createUserData();

    // Create users directly in database
    const userResult = await pool.query(`
      INSERT INTO users (email, password_hash, first_name, last_name)
      VALUES ($1, $2, $3, $4)
      RETURNING id
    `, [userData.email, 'hashedpassword', userData.firstName, userData.lastName]);
    userId = userResult.rows[0].id;

    const otherUserResult = await pool.query(`
      INSERT INTO users (email, password_hash, first_name, last_name)
      VALUES ($1, $2, $3, $4)
      RETURNING id
    `, [otherUserData.email, 'hashedpassword', otherUserData.firstName, otherUserData.lastName]);
    otherUserId = otherUserResult.rows[0].id;

    // Generate auth tokens
    authToken = testDataFactory.generateTestToken(userId);
    otherAuthToken = testDataFactory.generateTestToken(otherUserId);
  });

  afterEach(async () => {
    // Cleanup is handled by setup.js
  });

  describe('GET /api/dogs', () => {
    beforeEach(async () => {
      // Create test dogs with new schema
      await createDogForUser(userId, {
        name: 'Buddy',
        breed: 'Golden Retriever',
        birthday: '2021-01-01',
        weight: 65.5,
        bio: 'Friendly golden',
        friendlinessDogs: 5,
        isVaccinated: true
      });

      await createDogForUser(userId, {
        name: 'Max',
        breed: 'German Shepherd',
        birthday: '2019-01-01',
        weight: 75.0,
        bio: 'Protective but gentle',
        friendlinessDogs: 4,
        isVaccinated: true
      });

      await createDogForUser(otherUserId, {
        name: 'Luna',
        breed: 'Husky',
        birthday: '2022-01-01',
        weight: 45.0,
        bio: 'Energetic husky',
        friendlinessDogs: 5,
        isVaccinated: false
      });
    });

    it('should get all dogs for authenticated user', async () => {
      const res = await request(app)
        .get('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('dogs');
      expect(res.body.dogs).toBeInstanceOf(Array);
      expect(res.body.dogs.length).toBe(2);
      
      // Check dog structure
      const dog = res.body.dogs[0];
      expect(dog).toHaveProperty('id');
      expect(dog).toHaveProperty('name');
      expect(dog).toHaveProperty('breed');
      expect(dog).toHaveProperty('age');
      expect(dog).toHaveProperty('weight');
      expect(dog).toHaveProperty('isVaccinated');
      expect(dog).toHaveProperty('friendlinessDogs');
      expect(dog.owners).toBeInstanceOf(Array);
      expect(dog.owners.length).toBeGreaterThan(0);
      expect(dog.owners[0].id).toBe(userId);

      // Should only see own dogs
      const dogNames = res.body.dogs.map(d => d.name);
      expect(dogNames).toContain('Buddy');
      expect(dogNames).toContain('Max');
      expect(dogNames).not.toContain('Luna');
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .get('/api/dogs');

      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/dogs', () => {
    it('should create a new dog', async () => {
      const res = await request(app)
        .post('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Charlie',
          breed: 'Labrador',
          birthday: '2022-01-01',
          weight: 55.5,
          bio: 'Playful lab',
          friendlinessDogs: 5,
          isVaccinated: true
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('dog');
      expect(res.body.dog.name).toBe('Charlie');
      expect(res.body.dog.breed).toBe('Labrador');
      expect(res.body.dog.age).toBe(3); // Calculated from birthday
      expect(res.body.dog.weight).toBe('55.50');
      expect(res.body.dog.userId).toBe(userId);
      expect(res.body.dog.owners).toBeInstanceOf(Array);
      expect(res.body.dog.owners.some(owner => owner.id === userId)).toBe(true);

      dogId = res.body.dog.id;
    });

    it('should validate required fields', async () => {
      const res = await request(app)
        .post('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          // Missing name
          breed: 'Poodle',
          birthday: '2023-01-01'
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('errors');
    });

    it('should validate birthday format', async () => {
      const res = await request(app)
        .post('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Bad Date Dog',
          breed: 'Mixed',
          birthday: 'not-a-date',
          weight: 30
        });

      expect(res.status).toBe(400);
    });

    it('should validate weight must be numeric', async () => {
      const res = await request(app)
        .post('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Heavy Dog',
          breed: 'Mastiff',
          birthday: '2020-01-01',
          weight: 'not-a-number'
        });

      expect(res.status).toBe(400);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .post('/api/dogs')
        .send({
          name: 'Test Dog',
          breed: 'Test Breed',
          birthday: '2021-01-01'
        });

      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/dogs/:id', () => {
    let testDogId;

    beforeEach(async () => {
      // Create a test dog
      testDogId = await createDogForUser(userId, {
        name: 'GetTest',
        breed: 'Beagle',
        birthday: '2020-01-01',
        weight: 30.0
      });
    });

    it('should get a specific dog', async () => {
      const res = await request(app)
        .get(`/api/dogs/${testDogId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('dog');
      expect(res.body.dog.id).toBe(testDogId);
      expect(res.body.dog.name).toBe('GetTest');
      expect(res.body.dog.breed).toBe('Beagle');
    });

    it('should not get other user dogs', async () => {
      // Create dog for other user
      const otherDogId = await createDogForUser(otherUserId, {
        name: 'OtherDog',
        breed: 'Pug',
        birthday: '2022-01-01'
      });

      const res = await request(app)
        .get(`/api/dogs/${otherDogId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
    });

    it('should handle non-existent dog', async () => {
      const res = await request(app)
        .get('/api/dogs/99999')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .get(`/api/dogs/${testDogId}`);

      expect(res.status).toBe(401);
    });
  });

  describe('PUT /api/dogs/:id', () => {
    let updateDogId;

    beforeEach(async () => {
      // Create a dog to update
      updateDogId = await createDogForUser(userId, {
        name: 'UpdateMe',
        breed: 'Corgi',
        birthday: '2021-01-01',
        weight: 25.0,
        bio: 'Original description'
      });
    });

    it('should update a dog', async () => {
      const res = await request(app)
        .put(`/api/dogs/${updateDogId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Updated Name',
          breed: 'Pembroke Welsh Corgi',
          birthday: '2020-01-01',
          weight: 27.5,
          bio: 'Updated description',
          friendlinessDogs: 5,
          isVaccinated: true
        });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('dog');
      expect(res.body.dog.name).toBe('Updated Name');
      expect(res.body.dog.breed).toBe('Pembroke Welsh Corgi');
      expect(res.body.dog.age).toBe(5); // Calculated from birthday
      expect(res.body.dog.weight).toBe('27.50');
      expect(res.body.dog.bio).toBe('Updated description');
    });

    it('should allow partial updates', async () => {
      const res = await request(app)
        .put(`/api/dogs/${updateDogId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          bio: 'Only updating bio'
        });

      expect(res.status).toBe(200);
      expect(res.body.dog.bio).toBe('Only updating bio');
      // Other fields should remain unchanged
      expect(res.body.dog.name).toBe('UpdateMe');
    });

    it('should not update other user dogs', async () => {
      // Create dog for other user
      const otherDogId = await createDogForUser(otherUserId, {
        name: 'NotYours',
        breed: 'Dalmatian',
        birthday: '2022-01-01'
      });

      const res = await request(app)
        .put(`/api/dogs/${otherDogId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Trying to update'
        });

      expect(res.status).toBe(404);
    });

    it('should validate updates', async () => {
      const res = await request(app)
        .put(`/api/dogs/${updateDogId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          birthday: 'invalid-date' // Invalid birthday
        });

      expect(res.status).toBe(400);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .put(`/api/dogs/${updateDogId}`)
        .send({
          name: 'No auth'
        });

      expect(res.status).toBe(401);
    });
  });

  describe('DELETE /api/dogs/:id', () => {
    let deleteDogId;

    beforeEach(async () => {
      // Create a dog to delete
      deleteDogId = await createDogForUser(userId, {
        name: 'DeleteMe',
        breed: 'Boxer',
        birthday: '2019-01-01'
      });
    });

    it('should delete a dog', async () => {
      const res = await request(app)
        .delete(`/api/dogs/${deleteDogId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('deleted');

      // Verify dog was deleted
      const check = await pool.query(
        'SELECT * FROM dogs WHERE id = $1',
        [deleteDogId]
      );
      expect(check.rows.length).toBe(0);
    });

    it('should not delete other user dogs', async () => {
      // Create dog for other user
      const otherDogId = await createDogForUser(otherUserId, {
        name: 'NotYourDog',
        breed: 'Poodle',
        birthday: '2021-01-01'
      });

      const res = await request(app)
        .delete(`/api/dogs/${otherDogId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
      
      // Verify dog still exists
      const check = await pool.query(
        'SELECT * FROM dogs WHERE id = $1',
        [otherDogId]
      );
      expect(check.rows.length).toBe(1);
    });

    it('should handle non-existent dog', async () => {
      const res = await request(app)
        .delete('/api/dogs/99999')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .delete(`/api/dogs/${deleteDogId}`);

      expect(res.status).toBe(401);
    });
  });

  describe('Gallery Management', () => {
    let galleryDogId;

    beforeEach(async () => {
      // Create a dog for gallery tests
      galleryDogId = await createDogForUser(userId, {
        name: 'GalleryDog',
        breed: 'Shiba Inu',
        birthday: '2022-01-01'
      });
    });

    it('should validate gallery image removal request', async () => {
      const res = await request(app)
        .delete(`/api/dogs/${galleryDogId}/gallery`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          // Missing imageUrl
        });

      expect(res.status).toBe(400);
    });

    it('should validate profile image update from gallery', async () => {
      const res = await request(app)
        .put(`/api/dogs/${galleryDogId}/profile-image-from-gallery`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          // Missing imageUrl
        });

      expect(res.status).toBe(400);
    });
  });

  describe('Edge Cases', () => {
    it('should handle special characters in dog names', async () => {
      const res = await request(app)
        .post('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: "Buddy's Friend & Co.",
          breed: 'Mixed',
          birthday: '2021-01-01',
          weight: 40
        });

      expect(res.status).toBe(201);
      expect(res.body.dog.name).toBe("Buddy's Friend & Co.");
    });

    it('should handle very long descriptions', async () => {
      const longBio = 'A'.repeat(1000);
      const res = await request(app)
        .post('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'LongDesc',
          breed: 'Test',
          birthday: '2023-01-01',
          bio: longBio
        });

      expect(res.status).toBe(201);
      expect(res.body.dog.bio.length).toBe(1000);
    });

    it('should handle decimal ages and weights correctly', async () => {
      const res = await request(app)
        .post('/api/dogs')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Decimal Dog',
          breed: 'Test',
          birthday: '2022-06-01',
          weight: 35.75
        });

      expect(res.status).toBe(201);
      expect(res.body.dog.age).toBe(3); // Age calculated from birthday
      expect(res.body.dog.weight).toBe('35.75'); // Weight preserved as decimal
    });
  });
});