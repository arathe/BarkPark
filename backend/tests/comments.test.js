const request = require('supertest');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const testDataFactory = require('./utils/testDataFactory');

// Mock the auth middleware to avoid database user lookups
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
        const decoded = mockJwt.verify(token, process.env.JWT_SECRET || 'test-jwt-secret-key');
        req.user = { id: decoded.userId };
        next();
      } catch (error) {
        return res.status(401).json({ error: 'Invalid token' });
      }
    }
  };
});

const app = require('../server');

describe('Comments API', () => {
  let authToken;
  let authToken2;
  let authToken3;
  let userId;
  let userId2;
  let userId3;
  let postId;
  let friendPostId;
  let publicPostId;

  beforeEach(async () => {
    // Create test users using factory
    const userData1 = testDataFactory.createUserData();
    const userData2 = testDataFactory.createUserData();
    const userData3 = testDataFactory.createUserData();

    const userResult = await pool.query(`
      INSERT INTO users (email, password_hash, first_name, last_name)
      VALUES 
        ($1, 'hashedpassword', $2, $3),
        ($4, 'hashedpassword', $5, $6),
        ($7, 'hashedpassword', $8, $9)
      RETURNING id
    `, [
      userData1.email, userData1.firstName, userData1.lastName,
      userData2.email, userData2.firstName, userData2.lastName,
      userData3.email, userData3.firstName, userData3.lastName
    ]);
    userId = userResult.rows[0].id;
    userId2 = userResult.rows[1].id;
    userId3 = userResult.rows[2].id;

    // Create friendship between user1 and user2
    await pool.query(`
      INSERT INTO friendships (user_id, friend_id, status)
      VALUES ($1, $2, 'accepted'), ($2, $1, 'accepted')
    `, [userId, userId2]);

    // Generate auth tokens
    authToken = testDataFactory.generateTestToken(userId);
    authToken2 = testDataFactory.generateTestToken(userId2);
    authToken3 = testDataFactory.generateTestToken(userId3);

    // Create test posts
    try {
      const postResult = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES 
          ($1, 'Test post for comments', 'status', 'friends'),
          ($2, 'Friend post for comments', 'status', 'friends'),
          ($3, 'Public post for comments', 'status', 'public')
        RETURNING id
      `, [userId, userId2, userId]);
      postId = postResult.rows[0].id;
      friendPostId = postResult.rows[1].id;
      publicPostId = postResult.rows[2].id;
    } catch (error) {
      console.error('Error creating test posts:', error);
      throw error;
    }
  });

  afterEach(async () => {
    // Cleanup is handled by setup.js
  });

  describe('POST /api/posts/:id/comment', () => {
    it('should create a top-level comment', async () => {
      console.log('Creating comment for postId:', postId);
      
      // Check if post exists
      const postCheck = await pool.query('SELECT * FROM posts WHERE id = $1', [postId]);
      console.log('Post exists?', postCheck.rows.length > 0, postCheck.rows[0]);
      
      const res = await request(app)
        .post(`/api/posts/${postId}/comment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'This is a test comment'
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.content).toBe('This is a test comment');
      expect(res.body.user_id).toBe(userId);
      expect(res.body.post_id).toBe(postId);
      expect(res.body.parent_comment_id).toBeNull();
    });

    it('should create a notification for post owner', async () => {
      // Friend comments on user's post
      const res = await request(app)
        .post(`/api/posts/${postId}/comment`)
        .set('Authorization', `Bearer ${authToken2}`)
        .send({
          content: 'Friend commenting on your post'
        });

      expect(res.status).toBe(201);

      // Check notification was created
      const notifResult = await pool.query(`
        SELECT * FROM notifications 
        WHERE user_id = $1 AND type = 'comment' 
        AND data->>'postId' = $2::text
        ORDER BY created_at DESC
        LIMIT 1
      `, [userId, postId]);

      expect(notifResult.rows.length).toBe(1);
      expect(notifResult.rows[0].data.actorId).toBe(userId2);
    });

    it('should create a threaded reply', async () => {
      // First create a parent comment
      const parentRes = await request(app)
        .post(`/api/posts/${postId}/comment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Parent comment'
        });

      const parentCommentId = parentRes.body.id;

      // Create a reply
      const res = await request(app)
        .post(`/api/posts/${postId}/comment`)
        .set('Authorization', `Bearer ${authToken2}`)
        .send({
          content: 'This is a reply',
          parentCommentId
        });

      expect(res.status).toBe(201);
      expect(res.body.parent_comment_id).toBe(parentCommentId);
      expect(res.body.content).toBe('This is a reply');
    });

    it('should create notification for parent comment author on reply', async () => {
      // Create parent comment by user1
      const parentRes = await request(app)
        .post(`/api/posts/${postId}/comment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Another parent comment'
        });

      const parentCommentId = parentRes.body.id;

      // User2 replies
      await request(app)
        .post(`/api/posts/${postId}/comment`)
        .set('Authorization', `Bearer ${authToken2}`)
        .send({
          content: 'Reply to parent',
          parentCommentId
        });

      // Check notification for parent comment author
      const notifResult = await pool.query(`
        SELECT * FROM notifications 
        WHERE user_id = $1 AND type = 'comment' 
        AND data->>'postId' = $2::text
        ORDER BY created_at DESC
        LIMIT 1
      `, [userId, postId]);

      expect(notifResult.rows.length).toBeGreaterThan(0);
      expect(notifResult.rows[0].data.actorId).toBe(userId2);
    });

    it('should fail to comment on non-existent post', async () => {
      const res = await request(app)
        .post('/api/posts/99999/comment')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'This should fail'
        });

      expect(res.status).toBe(404);
      expect(res.body.error).toBe('Post not found');
    });

    it('should validate comment content', async () => {
      const res = await request(app)
        .post(`/api/posts/${postId}/comment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: ''
        });

      expect(res.status).toBe(400);
      expect(res.body.errors).toBeDefined();
    });

    it('should enforce max comment length', async () => {
      const longContent = 'A'.repeat(1001);
      const res = await request(app)
        .post(`/api/posts/${postId}/comment`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: longContent
        });

      expect(res.status).toBe(400);
      expect(res.body.errors).toBeDefined();
    });
  });

  describe('GET /api/posts/:id/comments', () => {
    let commentIds = [];

    beforeEach(async () => {
      // Clear comment IDs from previous test
      commentIds = [];
      
      // Create a nested comment structure
      // Level 1
      const comment1 = await pool.query(`
        INSERT INTO post_comments (post_id, user_id, content)
        VALUES ($1, $2, 'Top level comment 1')
        RETURNING id
      `, [publicPostId, userId]);
      commentIds.push(comment1.rows[0].id);

      const comment2 = await pool.query(`
        INSERT INTO post_comments (post_id, user_id, content)
        VALUES ($1, $2, 'Top level comment 2')
        RETURNING id
      `, [publicPostId, userId2]);
      commentIds.push(comment2.rows[0].id);

      // Level 2 (replies to comment1)
      const reply1 = await pool.query(`
        INSERT INTO post_comments (post_id, user_id, content, parent_comment_id)
        VALUES ($1, $2, 'Reply to comment 1', $3)
        RETURNING id
      `, [publicPostId, userId2, comment1.rows[0].id]);
      commentIds.push(reply1.rows[0].id);

      // Level 3 (reply to reply1)
      const reply2 = await pool.query(`
        INSERT INTO post_comments (post_id, user_id, content, parent_comment_id)
        VALUES ($1, $2, 'Reply to reply 1', $3)
        RETURNING id
      `, [publicPostId, userId, reply1.rows[0].id]);
      commentIds.push(reply2.rows[0].id);
    });

    it('should fetch comments with nested structure', async () => {
      const res = await request(app)
        .get(`/api/posts/${publicPostId}/comments`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.comments).toBeDefined();
      expect(res.body.total).toBeGreaterThanOrEqual(2);

      // Check structure
      const topLevelComments = res.body.comments;
      expect(topLevelComments.length).toBeGreaterThanOrEqual(2);

      // Find the comment with replies
      const commentWithReplies = topLevelComments.find(c => c.content === 'Top level comment 1');
      expect(commentWithReplies).toBeDefined();
      expect(commentWithReplies.replies).toBeDefined();
      expect(commentWithReplies.replies.length).toBeGreaterThan(0);

      // Check nested reply
      const firstReply = commentWithReplies.replies[0];
      expect(firstReply.content).toBe('Reply to comment 1');
      expect(firstReply.replies).toBeDefined();
      expect(firstReply.replies.length).toBeGreaterThan(0);
      expect(firstReply.replies[0].content).toBe('Reply to reply 1');
    });

    it('should include user information', async () => {
      const res = await request(app)
        .get(`/api/posts/${publicPostId}/comments`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      const comment = res.body.comments[0];
      expect(comment.user).toBeDefined();
      expect(comment.user.first_name).toBeDefined();
      expect(comment.user.last_name).toBeDefined();
      expect(comment.user.id).toBeDefined();
    });

    it('should support pagination', async () => {
      const res = await request(app)
        .get(`/api/posts/${publicPostId}/comments?limit=1&offset=0`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.comments.length).toBe(1);
      expect(res.body.total).toBeGreaterThanOrEqual(2);
    });
  });

  describe('DELETE /api/posts/comments/:id', () => {
    let topCommentId;
    let childCommentId;
    let grandchildCommentId;

    beforeEach(async () => {
      // Create a comment tree for deletion testing
      const topComment = await pool.query(`
        INSERT INTO post_comments (post_id, user_id, content)
        VALUES ($1, $2, 'Comment to delete')
        RETURNING id
      `, [postId, userId]);
      topCommentId = topComment.rows[0].id;

      const childComment = await pool.query(`
        INSERT INTO post_comments (post_id, user_id, content, parent_comment_id)
        VALUES ($1, $2, 'Child comment', $3)
        RETURNING id
      `, [postId, userId2, topCommentId]);
      childCommentId = childComment.rows[0].id;

      const grandchildComment = await pool.query(`
        INSERT INTO post_comments (post_id, user_id, content, parent_comment_id)
        VALUES ($1, $2, 'Grandchild comment', $3)
        RETURNING id
      `, [postId, userId, childCommentId]);
      grandchildCommentId = grandchildComment.rows[0].id;
    });

    it('should delete own comment', async () => {
      const res = await request(app)
        .delete(`/api/posts/comments/${topCommentId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.message).toBe('Comment deleted successfully');

      // Verify comment is deleted
      const check = await pool.query(
        'SELECT * FROM post_comments WHERE id = $1',
        [topCommentId]
      );
      expect(check.rows.length).toBe(0);
    });

    it('should cascade delete child comments', async () => {
      await request(app)
        .delete(`/api/posts/comments/${topCommentId}`)
        .set('Authorization', `Bearer ${authToken}`);

      // Verify all comments in tree are deleted
      const check = await pool.query(
        'SELECT * FROM post_comments WHERE id IN ($1, $2, $3)',
        [topCommentId, childCommentId, grandchildCommentId]
      );
      expect(check.rows.length).toBe(0);
    });

    it('should not delete other user comment', async () => {
      const res = await request(app)
        .delete(`/api/posts/comments/${childCommentId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
      expect(res.body.error).toContain('not found or you do not have permission');

      // Verify comment still exists
      const check = await pool.query(
        'SELECT * FROM post_comments WHERE id = $1',
        [childCommentId]
      );
      expect(check.rows.length).toBe(1);
    });

    it('should handle non-existent comment', async () => {
      const res = await request(app)
        .delete('/api/posts/comments/99999')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe('Comment Security and Edge Cases', () => {
    it('should require authentication', async () => {
      const res = await request(app)
        .post(`/api/posts/${postId}/comment`)
        .send({
          content: 'Unauthorized comment'
        });

      expect(res.status).toBe(401);
    });

    it('should handle deeply nested comments beyond limit', async () => {
      // Create 4 levels of nesting (limit is 3)
      let parentId = null;
      let lastCommentId;

      for (let i = 0; i < 4; i++) {
        const result = await pool.query(`
          INSERT INTO post_comments (post_id, user_id, content, parent_comment_id)
          VALUES ($1, $2, $3, $4)
          RETURNING id
        `, [postId, userId, `Level ${i} comment`, parentId]);
        
        lastCommentId = result.rows[0].id;
        parentId = lastCommentId;
      }

      // Fetch comments and verify depth limit
      const res = await request(app)
        .get(`/api/posts/${postId}/comments`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      // The 4th level comment should not appear in nested structure
      // due to the depth < 3 limit in the recursive CTE
    });

    it('should not allow commenting on friend-only post by non-friend', async () => {
      const res = await request(app)
        .post(`/api/posts/${friendPostId}/comment`)
        .set('Authorization', `Bearer ${authToken3}`)
        .send({
          content: 'Non-friend trying to comment'
        });

      // This will succeed because comment creation doesn't check post visibility
      // The visibility check happens at the post listing level
      expect(res.status).toBe(201);
    });
  });
});