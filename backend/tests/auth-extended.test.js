const request = require('supertest');
const express = require('express');
const pool = require('../config/database');
const User = require('../models/User');
const testDataFactory = require('./utils/testDataFactory');

// Create test app - using REAL auth routes (no mocking)
const createTestApp = () => {
  const app = express();
  app.use(express.json());
  const authRoutes = require('../routes/auth');
  app.use('/api/auth', authRoutes);
  return app;
};

describe('Auth API - Extended Coverage', () => {
  let app;

  beforeEach(async () => {
    app = createTestApp();
  });

  describe('POST /api/auth/change-password', () => {
    let authToken;

    beforeEach(async () => {
      // Register a user to get a token
      const userData = testDataFactory.createUserData();
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: userData.email,
          password: 'oldpassword123',
          firstName: userData.firstName,
          lastName: userData.lastName
        });
      authToken = res.body.token;
    });

    it('should change password with valid current password', async () => {
      const res = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          currentPassword: 'oldpassword123',
          newPassword: 'newpassword456'
        });

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('Password changed');
    });

    it('should allow login with new password after change', async () => {
      // Get the user's email
      const meRes = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`);
      const email = meRes.body.user.email;

      // Change password
      await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          currentPassword: 'oldpassword123',
          newPassword: 'newpassword456'
        });

      // Login with new password
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({ email, password: 'newpassword456' });

      expect(loginRes.status).toBe(200);
      expect(loginRes.body).toHaveProperty('token');
    });

    it('should reject change with incorrect current password', async () => {
      const res = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          currentPassword: 'wrongpassword',
          newPassword: 'newpassword456'
        });

      expect(res.status).toBe(401);
      expect(res.body.error).toContain('incorrect');
    });

    it('should reject new password shorter than 8 characters', async () => {
      const res = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          currentPassword: 'oldpassword123',
          newPassword: 'short'
        });

      expect(res.status).toBe(400);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .post('/api/auth/change-password')
        .send({
          currentPassword: 'oldpassword123',
          newPassword: 'newpassword456'
        });

      expect(res.status).toBe(401);
    });

    it('should require current password field', async () => {
      const res = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          newPassword: 'newpassword456'
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/auth/search', () => {
    let authToken;
    let searchableUserId;

    beforeEach(async () => {
      // Create the searching user
      const searcherData = testDataFactory.createUserData();
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: searcherData.email,
          password: 'password123',
          firstName: 'Searcher',
          lastName: 'User'
        });
      authToken = res.body.token;

      // Create searchable users directly in DB
      const user2Result = await pool.query(`
        INSERT INTO users (email, password_hash, first_name, last_name, is_searchable)
        VALUES ($1, $2, 'Alice', 'Johnson', true)
        RETURNING id
      `, [`alice_${Date.now()}@example.com`, 'hashedpassword']);
      searchableUserId = user2Result.rows[0].id;

      // Create non-searchable user
      await pool.query(`
        INSERT INTO users (email, password_hash, first_name, last_name, is_searchable)
        VALUES ($1, $2, 'Hidden', 'Person', false)
      `, [`hidden_${Date.now()}@example.com`, 'hashedpassword']);
    });

    it('should find users by first name', async () => {
      const res = await request(app)
        .get('/api/auth/search?q=Alice')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('users');
      expect(res.body.users.length).toBeGreaterThanOrEqual(1);
      expect(res.body.users[0].firstName).toBe('Alice');
    });

    it('should not return non-searchable users', async () => {
      const res = await request(app)
        .get('/api/auth/search?q=Hidden')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      const names = res.body.users.map(u => u.firstName);
      expect(names).not.toContain('Hidden');
    });

    it('should not return the searching user themselves', async () => {
      const res = await request(app)
        .get('/api/auth/search?q=Searcher')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      const names = res.body.users.map(u => u.firstName);
      expect(names).not.toContain('Searcher');
    });

    it('should return 400 with query shorter than 2 characters', async () => {
      const res = await request(app)
        .get('/api/auth/search?q=A')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(400);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .get('/api/auth/search?q=Alice');

      expect(res.status).toBe(401);
    });

    it('should return user details in results', async () => {
      const res = await request(app)
        .get('/api/auth/search?q=Alice')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      if (res.body.users.length > 0) {
        const user = res.body.users[0];
        expect(user).toHaveProperty('id');
        expect(user).toHaveProperty('firstName');
        expect(user).toHaveProperty('lastName');
        expect(user).toHaveProperty('email');
        expect(user).toHaveProperty('fullName');
        expect(user).not.toHaveProperty('password_hash');
      }
    });

    it('should return empty array when no users match', async () => {
      const res = await request(app)
        .get('/api/auth/search?q=Zzzznonexistent')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.users).toEqual([]);
      expect(res.body.count).toBe(0);
    });
  });

  describe('DELETE /api/auth/me/profile-photo', () => {
    let authToken;

    beforeEach(async () => {
      const userData = testDataFactory.createUserData();
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: userData.email,
          password: 'password123',
          firstName: userData.firstName,
          lastName: userData.lastName
        });
      authToken = res.body.token;

      // Set a profile image URL directly in DB
      await pool.query(`
        UPDATE users SET profile_image_url = 'https://test-bucket.s3.amazonaws.com/test.jpg'
        WHERE id = $1
      `, [res.body.user.id]);
    });

    it('should remove profile photo', async () => {
      const res = await request(app)
        .delete('/api/auth/me/profile-photo')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('removed');
      expect(res.body.user.profileImageUrl).toBeNull();
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .delete('/api/auth/me/profile-photo');

      expect(res.status).toBe(401);
    });
  });

  describe('PUT /api/auth/me - isSearchable toggle', () => {
    let authToken;

    beforeEach(async () => {
      const userData = testDataFactory.createUserData();
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: userData.email,
          password: 'password123',
          firstName: userData.firstName,
          lastName: userData.lastName
        });
      authToken = res.body.token;
    });

    it('should update isSearchable to false', async () => {
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ isSearchable: false });

      expect(res.status).toBe(200);
      expect(res.body.user.isSearchable).toBe(false);
    });

    it('should update isSearchable to true', async () => {
      // First set to false
      await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ isSearchable: false });

      // Then set back to true
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ isSearchable: true });

      expect(res.status).toBe(200);
      expect(res.body.user.isSearchable).toBe(true);
    });
  });

  describe('Registration edge cases', () => {
    it('should trim whitespace from names', async () => {
      const userData = testDataFactory.createUserData();
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: userData.email,
          password: 'password123',
          firstName: '  John  ',
          lastName: '  Doe  '
        });

      expect(res.status).toBe(201);
      expect(res.body.user.firstName).toBe('John');
      expect(res.body.user.lastName).toBe('Doe');
    });

    it('should normalize email to lowercase', async () => {
      const userData = testDataFactory.createUserData();
      const upperEmail = `UPPER_${Date.now()}@EXAMPLE.COM`;
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: upperEmail,
          password: 'password123',
          firstName: 'Test',
          lastName: 'User'
        });

      expect(res.status).toBe(201);
      expect(res.body.user.email).toBe(upperEmail.toLowerCase());
    });

    it('should accept optional phone number', async () => {
      const userData = testDataFactory.createUserData();
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: userData.email,
          password: 'password123',
          firstName: 'Test',
          lastName: 'User',
          phone: '+12125551234'
        });

      expect(res.status).toBe(201);
      expect(res.body.user.phone).toBe('+12125551234');
    });
  });
});
