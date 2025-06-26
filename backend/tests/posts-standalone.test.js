// Standalone configuration for posts tests
// This avoids conflicts with the global afterEach in setup.js

// Mock AWS SDK for tests
jest.mock('aws-sdk', () => ({
  S3: jest.fn(() => ({
    upload: jest.fn(() => ({
      promise: jest.fn(() => Promise.resolve({
        Location: 'https://test-bucket.s3.amazonaws.com/test-image.jpg'
      }))
    })),
    deleteObject: jest.fn(() => ({
      promise: jest.fn(() => Promise.resolve())
    }))
  }))
}));

// Test environment setup
process.env.NODE_ENV = 'test';
process.env.DB_NAME = 'barkpark_test';
process.env.DB_USER = process.env.DB_USER || 'austinrathe';
process.env.DB_PASSWORD = process.env.DB_PASSWORD || '';
process.env.DB_HOST = 'localhost';
process.env.DB_PORT = '5432';
process.env.JWT_SECRET = 'test-jwt-secret-key';

const request = require('supertest');
const express = require('express');
const pool = require('../config/database');
const Post = require('../models/Post');
const PostLike = require('../models/PostLike');
const PostComment = require('../models/PostComment');

// Create app instance
const app = express();
app.use(express.json());

// Import routes
const postRoutes = require('../routes/posts');
app.use('/api/posts', postRoutes);

describe('Posts API Tests', () => {
  let authToken;
  let userId;
  let otherUserId;
  let postId;
  let friendId;
  let checkInId;

  beforeAll(async () => {
    // Initialize test database tables if needed
    try {
      const fs = require('fs');
      const path = require('path');
      
      // Check if tables exist
      const tablesExist = await pool.query(`
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = 'posts'
        );
      `);
      
      if (!tablesExist.rows[0].exists) {
        // Run migrations
        const socialFeedPath = path.join(__dirname, '..', 'migrations', '007_add_social_feed.sql');
        const socialFeedSchema = fs.readFileSync(socialFeedPath, 'utf8');
        await pool.query(socialFeedSchema);
      }
    } catch (error) {
      console.warn('Table setup warning:', error.message);
    }

    // Clean up any existing test data
    await pool.query(`DELETE FROM notifications WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM post_comments WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM post_likes WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM post_media WHERE post_id IN (SELECT id FROM posts WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%'))`);
    await pool.query(`DELETE FROM posts WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM checkins WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM friendships WHERE requester_id IN (SELECT id FROM users WHERE email LIKE 'test%') OR addressee_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM users WHERE email IN ('testpost@example.com', 'testfriend@example.com', 'testother@example.com')`);

    // Create test users
    const authApp = express();
    authApp.use(express.json());
    const authRoutes = require('../routes/auth');
    authApp.use('/api/auth', authRoutes);

    // Create main test user
    const registerRes = await request(authApp)
      .post('/api/auth/register')
      .send({
        email: 'testpost@example.com',
        password: 'password123',
        firstName: 'Test',
        lastName: 'Post'
      });

    authToken = registerRes.body.token;
    userId = registerRes.body.user.id;

    // Create friend user
    const friendRes = await request(authApp)
      .post('/api/auth/register')
      .send({
        email: 'testfriend@example.com',
        password: 'password123',
        firstName: 'Test',
        lastName: 'Friend'
      });
    
    friendId = friendRes.body.user.id;

    // Create other user (not a friend)
    const otherRes = await request(authApp)
      .post('/api/auth/register')
      .send({
        email: 'testother@example.com',
        password: 'password123',
        firstName: 'Test',
        lastName: 'Other'
      });
    
    otherUserId = otherRes.body.user.id;

    // Create friendship
    await pool.query(`
      INSERT INTO friendships (requester_id, addressee_id, status)
      VALUES ($1, $2, 'accepted')
    `, [userId, friendId]);

    // Create a test check-in
    const parkResult = await pool.query(`
      INSERT INTO dog_parks (name, address, latitude, longitude)
      VALUES ('Test Park Posts', '123 Test St, Test City, NY', 40.7128, -74.0060)
      RETURNING id
    `);
    const parkId = parkResult.rows[0].id;

    const checkInResult = await pool.query(`
      INSERT INTO checkins (user_id, dog_park_id, checked_in_at)
      VALUES ($1, $2, NOW())
      RETURNING id
    `, [userId, parkId]);
    checkInId = checkInResult.rows[0].id;
  });

  afterAll(async () => {
    // Final cleanup
    await pool.query(`DELETE FROM notifications WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM post_comments WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM post_likes WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM post_media WHERE post_id IN (SELECT id FROM posts WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%'))`);
    await pool.query(`DELETE FROM posts WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM checkins WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM dog_parks WHERE name = 'Test Park Posts'`);
    await pool.query(`DELETE FROM friendships WHERE requester_id IN (SELECT id FROM users WHERE email LIKE 'test%') OR addressee_id IN (SELECT id FROM users WHERE email LIKE 'test%')`);
    await pool.query(`DELETE FROM users WHERE email IN ('testpost@example.com', 'testfriend@example.com', 'testother@example.com')`);
    await pool.end();
  });

  describe('POST /api/posts', () => {
    afterEach(async () => {
      // Clean up posts after each test
      await pool.query(`DELETE FROM posts WHERE user_id = $1`, [userId]);
    });

    it('should create a status post', async () => {
      const res = await request(app)
        .post('/api/posts')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'This is a test post',
          postType: 'status',
          visibility: 'friends'
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.content).toBe('This is a test post');
      expect(res.body.post_type).toBe('status');
      expect(res.body.visibility).toBe('friends');
      expect(res.body.user_id).toBe(userId);
    });

    it('should create a check-in post', async () => {
      const res = await request(app)
        .post('/api/posts')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Just arrived at the park!',
          postType: 'checkin',
          checkInId: checkInId,
          visibility: 'public'
        });

      expect(res.status).toBe(201);
      expect(res.body.post_type).toBe('checkin');
      expect(res.body.check_in_id).toBe(checkInId);
      expect(res.body.check_in).toBeDefined();
      expect(res.body.check_in.park_name).toBe('Test Park Posts');
    });

    it('should require content or check-in/share', async () => {
      const res = await request(app)
        .post('/api/posts')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          postType: 'status',
          visibility: 'friends'
        });

      expect(res.status).toBe(400);
      expect(res.body.error).toContain('must have content');
    });

    it('should validate post type', async () => {
      const res = await request(app)
        .post('/api/posts')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Test',
          postType: 'invalid',
          visibility: 'friends'
        });

      expect(res.status).toBe(400);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .post('/api/posts')
        .send({
          content: 'Test post',
          postType: 'status',
          visibility: 'friends'
        });

      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/posts/feed', () => {
    beforeAll(async () => {
      // Create posts with different visibilities
      await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility, created_at)
        VALUES 
          ($1, 'My public post', 'status', 'public', NOW() - INTERVAL '1 hour'),
          ($1, 'My friends post', 'status', 'friends', NOW() - INTERVAL '2 hours'),
          ($1, 'My private post', 'status', 'private', NOW() - INTERVAL '3 hours'),
          ($2, 'Friend public post', 'status', 'public', NOW() - INTERVAL '4 hours'),
          ($2, 'Friend friends post', 'status', 'friends', NOW() - INTERVAL '5 hours'),
          ($3, 'Other public post', 'status', 'public', NOW() - INTERVAL '6 hours'),
          ($3, 'Other friends post', 'status', 'friends', NOW() - INTERVAL '7 hours')
      `, [userId, friendId, otherUserId]);
    });

    it('should get feed with proper visibility filtering', async () => {
      const res = await request(app)
        .get('/api/posts/feed')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('posts');
      expect(res.body).toHaveProperty('pagination');
      
      const postContents = res.body.posts.map(p => p.content);
      
      // Should see own posts (all visibilities)
      expect(postContents).toContain('My public post');
      expect(postContents).toContain('My friends post');
      expect(postContents).toContain('My private post');
      
      // Should see friend's public and friends posts
      expect(postContents).toContain('Friend public post');
      expect(postContents).toContain('Friend friends post');
      
      // Should NOT see non-friend's friends posts
      expect(postContents).not.toContain('Other friends post');
    });

    it('should support pagination', async () => {
      const res = await request(app)
        .get('/api/posts/feed?limit=3&offset=0')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.posts.length).toBeLessThanOrEqual(3);
      expect(res.body.pagination.limit).toBe(3);
      expect(res.body.pagination.offset).toBe(0);
      expect(res.body.pagination.hasMore).toBeDefined();
    });

    it('should include post metadata', async () => {
      const res = await request(app)
        .get('/api/posts/feed?limit=1')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      const post = res.body.posts[0];
      
      expect(post).toHaveProperty('user_id');
      expect(post).toHaveProperty('first_name');
      expect(post).toHaveProperty('last_name');
      expect(post).toHaveProperty('like_count');
      expect(post).toHaveProperty('comment_count');
      expect(post).toHaveProperty('user_liked');
      expect(post).toHaveProperty('created_at');
    });
  });

  describe('POST /api/posts/:id/like', () => {
    let likePostId;

    beforeAll(async () => {
      // Create a post to like
      const result = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES ($1, 'Post to like', 'status', 'public')
        RETURNING id
      `, [friendId]);
      likePostId = result.rows[0].id;
    });

    it('should like a post', async () => {
      const res = await request(app)
        .post(`/api/posts/${likePostId}/like`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.action).toBe('liked');
      expect(res.body.likeCount).toBeGreaterThan(0);

      // Verify like was created
      const likeCheck = await pool.query(
        'SELECT * FROM post_likes WHERE post_id = $1 AND user_id = $2',
        [likePostId, userId]
      );
      expect(likeCheck.rows.length).toBe(1);
    });

    it('should unlike a post', async () => {
      const res = await request(app)
        .post(`/api/posts/${likePostId}/like`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.action).toBe('unliked');

      // Verify like was removed
      const likeCheck = await pool.query(
        'SELECT * FROM post_likes WHERE post_id = $1 AND user_id = $2',
        [likePostId, userId]
      );
      expect(likeCheck.rows.length).toBe(0);
    });

    it('should handle non-existent post', async () => {
      const res = await request(app)
        .post('/api/posts/99999/like')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe('POST /api/posts/:id/comment', () => {
    let commentPostId;

    beforeAll(async () => {
      const result = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES ($1, 'Post for comments', 'status', 'public')
        RETURNING id
      `, [userId]);
      commentPostId = result.rows[0].id;
    });

    it('should add a comment to a post', async () => {
      const res = await request(app)
        .post(`/api/posts/${commentPostId}/comment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Great post!'
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.content).toBe('Great post!');
      expect(res.body.user_id).toBe(userId);
      expect(res.body.post_id).toBe(commentPostId);
    });

    it('should require comment content', async () => {
      const res = await request(app)
        .post(`/api/posts/${commentPostId}/comment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({});

      expect(res.status).toBe(400);
    });

    it('should handle non-existent post', async () => {
      const res = await request(app)
        .post('/api/posts/99999/comment')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Comment'
        });

      expect(res.status).toBe(404);
    });
  });

  describe('GET /api/posts/:id/comments', () => {
    let commentedPostId;
    
    beforeAll(async () => {
      // Create post and comments
      const postResult = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES ($1, 'Post with comments', 'status', 'public')
        RETURNING id
      `, [userId]);
      commentedPostId = postResult.rows[0].id;

      // Add multiple comments
      await pool.query(`
        INSERT INTO post_comments (post_id, user_id, content, created_at)
        VALUES 
          ($1, $2, 'First comment', NOW() - INTERVAL '2 hours'),
          ($1, $3, 'Second comment', NOW() - INTERVAL '1 hour'),
          ($1, $2, 'Third comment', NOW())
      `, [commentedPostId, userId, friendId]);
    });

    it('should get comments for a post', async () => {
      const res = await request(app)
        .get(`/api/posts/${commentedPostId}/comments`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('comments');
      expect(res.body.comments.length).toBe(3);
      
      // Should be ordered by created_at ASC (oldest first)
      expect(res.body.comments[0].content).toBe('First comment');
      expect(res.body.comments[2].content).toBe('Third comment');
      
      // Should include user info
      expect(res.body.comments[0]).toHaveProperty('first_name');
      expect(res.body.comments[0]).toHaveProperty('last_name');
    });

    it('should support pagination', async () => {
      const res = await request(app)
        .get(`/api/posts/${commentedPostId}/comments?limit=2&offset=0`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.comments.length).toBe(2);
      expect(res.body.pagination.limit).toBe(2);
      expect(res.body.pagination.hasMore).toBe(true);
    });
  });

  describe('DELETE /api/posts/:id', () => {
    let deletePostId;
    let otherUserPostId;

    beforeEach(async () => {
      // Create user's own post
      const result1 = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES ($1, 'My post to delete', 'status', 'public')
        RETURNING id
      `, [userId]);
      deletePostId = result1.rows[0].id;

      // Create another user's post
      const result2 = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES ($1, 'Other user post', 'status', 'public')
        RETURNING id
      `, [friendId]);
      otherUserPostId = result2.rows[0].id;
    });

    it('should delete own post', async () => {
      const res = await request(app)
        .delete(`/api/posts/${deletePostId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('deleted');

      // Verify post was deleted
      const check = await pool.query(
        'SELECT * FROM posts WHERE id = $1',
        [deletePostId]
      );
      expect(check.rows.length).toBe(0);
    });

    it('should not delete other user post', async () => {
      const res = await request(app)
        .delete(`/api/posts/${otherUserPostId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(403);
      
      // Verify post still exists
      const check = await pool.query(
        'SELECT * FROM posts WHERE id = $1',
        [otherUserPostId]
      );
      expect(check.rows.length).toBe(1);
    });
  });

  describe('Edge Cases and Security', () => {
    it('should handle very long content gracefully', async () => {
      const longContent = 'A'.repeat(5000);
      const res = await request(app)
        .post('/api/posts')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: longContent,
          postType: 'status',
          visibility: 'friends'
        });

      expect(res.status).toBe(201);
      expect(res.body.content.length).toBe(5000);
    });

    it('should handle concurrent likes correctly', async () => {
      // Create a post
      const result = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES ($1, 'Concurrent like test', 'status', 'public')
        RETURNING id
      `, [userId]);
      const testPostId = result.rows[0].id;

      // Send multiple like requests concurrently
      const promises = Array(5).fill().map(() => 
        request(app)
          .post(`/api/posts/${testPostId}/like`)
          .set('Authorization', `Bearer ${authToken}`)
      );

      const results = await Promise.all(promises);
      
      // All should succeed
      results.forEach(res => {
        expect(res.status).toBe(200);
      });

      // But only one like should exist
      const likeCheck = await pool.query(
        'SELECT COUNT(*) FROM post_likes WHERE post_id = $1 AND user_id = $2',
        [testPostId, userId]
      );
      expect(parseInt(likeCheck.rows[0].count)).toBe(1);
    });
  });
});