const request = require('supertest');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

// Mock the auth middleware
jest.mock('../middleware/auth', () => {
  const mockJwt = require('jsonwebtoken');
  return {
    verifyToken: (req, res, next) => {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Access token required' });
      }
      const token = authHeader.substring(7);
      try {
        const decoded = mockJwt.verify(token, process.env.JWT_SECRET || 'test_secret');
        req.user = { id: decoded.userId };
        next();
      } catch (error) {
        return res.status(401).json({ error: 'Invalid token' });
      }
    }
  };
});

const app = require('../server');

describe('Comments API - Simple Test', () => {
  let authToken;
  let userId;
  let postId;

  beforeEach(async () => {
    // Create a unique test user
    const timestamp = Date.now();
    const userResult = await pool.query(`
      INSERT INTO users (email, password_hash, first_name, last_name)
      VALUES ($1, 'hashedpassword', 'Test', 'User')
      RETURNING id
    `, [`testuser${timestamp}@example.com`]);
    userId = userResult.rows[0].id;

    // Generate auth token
    authToken = jwt.sign({ userId }, process.env.JWT_SECRET || 'test_secret');

    // Create a test post
    const postResult = await pool.query(`
      INSERT INTO posts (user_id, content, post_type, visibility)
      VALUES ($1, 'Test post', 'status', 'public')
      RETURNING id
    `, [userId]);
    postId = postResult.rows[0].id;

    console.log('Test setup:', { userId, postId });
  });

  afterEach(async () => {
    // Cleanup is handled by setup.js
  });

  it('should create a comment on a post', async () => {
    const res = await request(app)
      .post(`/api/posts/${postId}/comment`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        content: 'This is a test comment'
      });

    console.log('Response:', res.status, res.body);

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.content).toBe('This is a test comment');
    expect(res.body.post_id).toBe(postId);
    expect(res.body.user_id).toBe(userId);
  });

  it('should fetch comments for a post', async () => {
    // First create a comment
    await pool.query(`
      INSERT INTO post_comments (post_id, user_id, content)
      VALUES ($1, $2, 'Direct DB comment')
    `, [postId, userId]);

    const res = await request(app)
      .get(`/api/posts/${postId}/comments`)
      .set('Authorization', `Bearer ${authToken}`);

    console.log('Comments response:', res.status, res.body);

    expect(res.status).toBe(200);
    expect(res.body.comments).toBeDefined();
    expect(res.body.comments.length).toBeGreaterThan(0);
    expect(res.body.total).toBeGreaterThan(0);
  });

  it('should delete own comment', async () => {
    // Create a comment to delete
    const commentResult = await pool.query(`
      INSERT INTO post_comments (post_id, user_id, content)
      VALUES ($1, $2, 'Comment to delete')
      RETURNING id
    `, [postId, userId]);
    const commentId = commentResult.rows[0].id;

    const res = await request(app)
      .delete(`/api/posts/comments/${commentId}`)
      .set('Authorization', `Bearer ${authToken}`);

    console.log('Delete response:', res.status, res.body);

    expect(res.status).toBe(200);
    expect(res.body.message).toBe('Comment deleted successfully');

    // Verify it's deleted
    const check = await pool.query(
      'SELECT * FROM post_comments WHERE id = $1',
      [commentId]
    );
    expect(check.rows.length).toBe(0);
  });
});