const request = require('supertest');
const express = require('express');
const pool = require('../config/database');
const Dog = require('../models/Dog');

// Create app instance
const app = express();
app.use(express.json());

// Import routes
const dogRoutes = require('../routes/dogs');
app.use('/api/dogs', dogRoutes);

describe('Dogs API', () => {
  let authToken;
  let userId;
  let otherUserId;
  let otherAuthToken;
  let dogId;

  beforeAll(async () => {
    // Create test users
    const authApp = express();
    authApp.use(express.json());
    const authRoutes = require('../routes/auth');
    authApp.use('/api/auth', authRoutes);

    // Create main test user
    const registerRes = await request(authApp)
      .post('/api/auth/register')
      .send({
        email: 'testdog@example.com',
        password: 'password123',
        firstName: 'Test',
        lastName: 'DogOwner'
      });

    authToken = registerRes.body.token;
    userId = registerRes.body.user.id;

    // Create other user
    const otherRes = await request(authApp)
      .post('/api/auth/register')
      .send({
        email: 'testdogother@example.com',
        password: 'password123',
        firstName: 'Other',
        lastName: 'Owner'
      });
    
    otherUserId = otherRes.body.user.id;
    otherAuthToken = otherRes.body.token;
  });

  afterAll(async () => {
    // Clean up test data
    await pool.query(`DELETE FROM dogs WHERE user_id IN ($1, $2)`, [userId, otherUserId]);
    await pool.query(`DELETE FROM users WHERE id IN ($1, $2)`, [userId, otherUserId]);
  });

  describe('GET /api/dogs', () => {
    beforeAll(async () => {
      // Create test dogs with new schema
      await pool.query(`
        INSERT INTO dogs (user_id, name, breed, birthday, weight, bio, friendliness_dogs, is_vaccinated)
        VALUES 
          ($1, 'Buddy', 'Golden Retriever', '2021-01-01', 65.5, 'Friendly golden', 5, true),
          ($1, 'Max', 'German Shepherd', '2019-01-01', 75.0, 'Protective but gentle', 4, true),
          ($2, 'Luna', 'Husky', '2022-01-01', 45.0, 'Energetic husky', 5, false)
      `, [userId, otherUserId]);
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

    beforeAll(async () => {
      // Create a test dog
      const result = await pool.query(`
        INSERT INTO dogs (user_id, name, breed, birthday, weight)
        VALUES ($1, 'GetTest', 'Beagle', '2020-01-01', 30.0)
        RETURNING id
      `, [userId]);
      testDogId = result.rows[0].id;
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
      const result = await pool.query(`
        INSERT INTO dogs (user_id, name, breed, birthday)
        VALUES ($1, 'OtherDog', 'Pug', '2022-01-01')
        RETURNING id
      `, [otherUserId]);
      const otherDogId = result.rows[0].id;

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

    beforeAll(async () => {
      // Create a dog to update
      const result = await pool.query(`
        INSERT INTO dogs (user_id, name, breed, birthday, weight, bio)
        VALUES ($1, 'UpdateMe', 'Corgi', '2021-01-01', 25.0, 'Original description')
        RETURNING id
      `, [userId]);
      updateDogId = result.rows[0].id;
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
      expect(res.body.dog.name).toBe('Updated Name');
    });

    it('should not update other user dogs', async () => {
      // Create dog for other user
      const result = await pool.query(`
        INSERT INTO dogs (user_id, name, breed, birthday)
        VALUES ($1, 'NotYours', 'Dalmatian', '2022-01-01')
        RETURNING id
      `, [otherUserId]);
      const otherDogId = result.rows[0].id;

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
      const result = await pool.query(`
        INSERT INTO dogs (user_id, name, breed, birthday)
        VALUES ($1, 'DeleteMe', 'Boxer', '2019-01-01')
        RETURNING id
      `, [userId]);
      deleteDogId = result.rows[0].id;
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
      const result = await pool.query(`
        INSERT INTO dogs (user_id, name, breed, birthday)
        VALUES ($1, 'NotYourDog', 'Poodle', '2021-01-01')
        RETURNING id
      `, [otherUserId]);
      const otherDogId = result.rows[0].id;

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

    beforeAll(async () => {
      // Create a dog for gallery tests
      const result = await pool.query(`
        INSERT INTO dogs (user_id, name, breed, birthday)
        VALUES ($1, 'GalleryDog', 'Shiba Inu', '2022-01-01')
        RETURNING id
      `, [userId]);
      galleryDogId = result.rows[0].id;
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