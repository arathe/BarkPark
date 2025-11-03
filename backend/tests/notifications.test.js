const request = require('supertest');
const express = require('express');
const pool = require('../config/database');
const Notification = require('../models/Notification');
const testDataFactory = require('./utils/testDataFactory');

// Mock auth middleware
jest.mock('../middleware/auth', () => require('./utils/testMocks').mockAuthMiddleware());

// Create app instance
const app = express();
app.use(express.json());

// Import routes
const notificationRoutes = require('../routes/notifications');
const postRoutes = require('../routes/posts');
app.use('/api/notifications', notificationRoutes);
app.use('/api/posts', postRoutes);

describe('Notifications API', () => {
  let authToken;
  let userId;
  let otherUserId;
  let otherAuthToken;
  let postId;

  beforeEach(async () => {
    // Create test users using factory
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

    // Create friendship so they can interact
    await pool.query(`
      INSERT INTO friendships (user_id, friend_id, status)
      VALUES ($1, $2, 'accepted')
    `, [userId, otherUserId]);

    // Create a test post
    const postResult = await pool.query(`
      INSERT INTO posts (user_id, content, post_type, visibility)
      VALUES ($1, 'Test post for notifications', 'status', 'friends')
      RETURNING id
    `, [userId]);
    postId = postResult.rows[0].id;
  });

  afterEach(async () => {
    // Cleanup is handled by setup.js
  });

  describe('GET /api/notifications', () => {
    beforeEach(async () => {
      // Create various types of notifications
      await pool.query(`
        INSERT INTO notifications (user_id, type, data, read, created_at)
        VALUES 
          ($1, 'like', $2, false, NOW() - INTERVAL '1 hour'),
          ($1, 'comment', $2, false, NOW() - INTERVAL '2 hours'),
          ($1, 'friend_post', $2, true, NOW() - INTERVAL '3 hours')
      `, [userId, JSON.stringify({ actorId: otherUserId, postId: postId })]);
    });

    it('should get notifications for authenticated user', async () => {
      const res = await request(app)
        .get('/api/notifications')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('notifications');
      expect(res.body).toHaveProperty('unreadCount');
      expect(res.body).toHaveProperty('pagination');
      
      expect(res.body.notifications).toBeInstanceOf(Array);
      expect(res.body.notifications.length).toBeGreaterThan(0);
      
      // Check notification structure
      const notification = res.body.notifications[0];
      expect(notification).toHaveProperty('id');
      expect(notification).toHaveProperty('type');
      expect(notification).toHaveProperty('actor_id');
      expect(notification).toHaveProperty('read');
      expect(notification).toHaveProperty('created_at');
      expect(notification).toHaveProperty('text'); // Formatted text
    });

    it('should support pagination', async () => {
      const res = await request(app)
        .get('/api/notifications?limit=2&offset=0')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.notifications.length).toBeLessThanOrEqual(2);
      expect(res.body.pagination.limit).toBe(2);
      expect(res.body.pagination.offset).toBe(0);
      expect(res.body.pagination.hasMore).toBeDefined();
    });

    it('should only show notifications for authenticated user', async () => {
      const res = await request(app)
        .get('/api/notifications')
        .set('Authorization', `Bearer ${otherAuthToken}`);

      expect(res.status).toBe(200);
      
      // Other user should not see notifications meant for the main user
      const notificationIds = res.body.notifications.map(n => n.user_id);
      expect(notificationIds).not.toContain(userId);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .get('/api/notifications');

      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/notifications/unread-count', () => {
    it('should get unread notification count', async () => {
      const res = await request(app)
        .get('/api/notifications/unread-count')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('unreadCount');
      expect(typeof res.body.unreadCount).toBe('number');
      expect(res.body.unreadCount).toBeGreaterThanOrEqual(0);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .get('/api/notifications/unread-count');

      expect(res.status).toBe(401);
    });
  });

  describe('PUT /api/notifications/:id/read', () => {
    let notificationId;

    beforeEach(async () => {
      // Create a new unread notification
      const result = await pool.query(`
        INSERT INTO notifications (user_id, type, data, read)
        VALUES ($1, 'like', $2, false)
        RETURNING id
      `, [userId, JSON.stringify({ actorId: otherUserId, postId: postId })]);
      notificationId = result.rows[0].id;
    });

    it('should mark notification as read', async () => {
      const res = await request(app)
        .put(`/api/notifications/${notificationId}/read`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('marked as read');

      // Verify notification was marked as read
      const check = await pool.query(
        'SELECT read FROM notifications WHERE id = $1',
        [notificationId]
      );
      expect(check.rows[0].read).toBe(true);
    });

    it('should handle non-existent notification', async () => {
      const res = await request(app)
        .put('/api/notifications/99999/read')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
    });

    it('should not allow marking other user notifications as read', async () => {
      // Create notification for other user
      const result = await pool.query(`
        INSERT INTO notifications (user_id, type, data, read)
        VALUES ($1, 'friend_post', $2, false)
        RETURNING id
      `, [otherUserId, JSON.stringify({ actorId: userId })]);
      const othersNotificationId = result.rows[0].id;

      const res = await request(app)
        .put(`/api/notifications/${othersNotificationId}/read`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
      
      // Verify notification is still unread
      const check = await pool.query(
        'SELECT read FROM notifications WHERE id = $1',
        [othersNotificationId]
      );
      expect(check.rows[0].read).toBe(false);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .put(`/api/notifications/${notificationId}/read`);

      expect(res.status).toBe(401);
    });
  });

  describe('PUT /api/notifications/read-all', () => {
    beforeEach(async () => {
      // Create multiple unread notifications
      await pool.query(`
        INSERT INTO notifications (user_id, type, data, read)
        VALUES 
          ($1, 'like', $2, false),
          ($1, 'comment', $2, false),
          ($1, 'friend_checkin', $2, false)
      `, [userId, JSON.stringify({ actorId: otherUserId })]);
    });

    it('should mark all notifications as read', async () => {
      const res = await request(app)
        .put('/api/notifications/read-all')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('notifications marked as read');
      expect(res.body.updatedCount).toBeGreaterThan(0);

      // Verify all notifications are read
      const check = await pool.query(
        'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND read = false',
        [userId]
      );
      expect(parseInt(check.rows[0].count)).toBe(0);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .put('/api/notifications/read-all');

      expect(res.status).toBe(401);
    });
  });

  describe('Notification Creation Tests', () => {
    it('should persist JSON payload alongside scalar columns', async () => {
      const created = await Notification.create({
        userId,
        type: 'like',
        actorId: otherUserId,
        postId
      });

      expect(created.user_id).toBe(userId);
      expect(created.actor_id).toBe(otherUserId);
      expect(created.post_id).toBe(postId);
      expect(created.data).toEqual({
        actorId: otherUserId,
        postId
      });

      const check = await pool.query(`
        SELECT 
          actor_id,
          post_id,
          data->>'actorId' as data_actor_id,
          data->>'postId' as data_post_id
        FROM notifications
        WHERE id = $1
      `, [created.id]);

      expect(check.rows[0].actor_id).toBe(otherUserId);
      expect(check.rows[0].post_id).toBe(postId);
      expect(check.rows[0].data_actor_id).toBe(String(otherUserId));
      expect(check.rows[0].data_post_id).toBe(String(postId));
    });

    it('should support bulk notification creation with consistent payloads', async () => {
      const commentResult = await pool.query(`
        INSERT INTO post_comments (post_id, user_id, content)
        VALUES ($1, $2, 'Notification bulk test comment')
        RETURNING id
      `, [postId, otherUserId]);

      const commentId = commentResult.rows[0].id;

      const notifications = [
        {
          userId,
          type: 'like',
          actorId: otherUserId,
          postId
        },
        {
          userId,
          type: 'comment',
          actorId: otherUserId,
          postId,
          commentId
        }
      ];

      const created = await Notification.createBulk(notifications);

      expect(created).toHaveLength(2);
      created.forEach(record => {
        expect(record.user_id).toBe(userId);
        expect(record.actor_id).toBe(otherUserId);
      });

      const dbCheck = await pool.query(`
        SELECT 
          COUNT(*) FILTER (WHERE data->>'actorId' = $1 AND actor_id = $2) as matching_rows
        FROM notifications
        WHERE user_id = $3
          AND type IN ('like', 'comment')
      `, [String(otherUserId), otherUserId, userId]);

      expect(parseInt(dbCheck.rows[0].matching_rows)).toBeGreaterThanOrEqual(2);
    });

    it('should create notification when post is liked', async () => {
      // Create a new post
      const postResult = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES ($1, 'Post to be liked', 'status', 'public')
        RETURNING id
      `, [userId]);
      const newPostId = postResult.rows[0].id;

      // Like the post as other user
      await request(app)
        .post(`/api/posts/${newPostId}/like`)
        .set('Authorization', `Bearer ${otherAuthToken}`);

      // Check that notification was created
      const notifCheck = await pool.query(`
        SELECT * FROM notifications 
        WHERE user_id = $1 AND type = 'like' AND data->>'postId' = $2 AND data->>'actorId' = $3
      `, [userId, newPostId.toString(), otherUserId.toString()]);

      expect(notifCheck.rows.length).toBe(1);
      expect(notifCheck.rows[0].read).toBe(false);
    });

    it('should create notification when post is commented on', async () => {
      // Create a new post
      const postResult = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES ($1, 'Post to be commented on', 'status', 'public')
        RETURNING id
      `, [userId]);
      const newPostId = postResult.rows[0].id;

      // Comment on the post as other user
      await request(app)
        .post(`/api/posts/${newPostId}/comment`)
        .set('Authorization', `Bearer ${otherAuthToken}`)
        .send({
          content: 'Great post!'
        });

      // Check that notification was created
      const notifCheck = await pool.query(`
        SELECT * FROM notifications 
        WHERE user_id = $1 AND type = 'comment' AND data->>'postId' = $2 AND data->>'actorId' = $3
      `, [userId, newPostId.toString(), otherUserId.toString()]);

      expect(notifCheck.rows.length).toBe(1);
      expect(notifCheck.rows[0].read).toBe(false);
    });

    it('should not create notification for own actions', async () => {
      // Create a new post
      const postResult = await pool.query(`
        INSERT INTO posts (user_id, content, post_type, visibility)
        VALUES ($1, 'My own post', 'status', 'public')
        RETURNING id
      `, [userId]);
      const newPostId = postResult.rows[0].id;

      // Like own post
      await request(app)
        .post(`/api/posts/${newPostId}/like`)
        .set('Authorization', `Bearer ${authToken}`);

      // Check that no notification was created
      const notifCheck = await pool.query(`
        SELECT * FROM notifications 
        WHERE user_id = $1 AND type = 'like' AND data->>'postId' = $2 AND data->>'actorId' = $1::text
      `, [userId, newPostId.toString()]);

      expect(notifCheck.rows.length).toBe(0);
    });
  });

  describe('Edge Cases', () => {
    it('should handle concurrent read operations', async () => {
      // Create a notification
      const result = await pool.query(`
        INSERT INTO notifications (user_id, type, data, read)
        VALUES ($1, 'like', $2, false)
        RETURNING id
      `, [userId, JSON.stringify({ actorId: otherUserId })]);
      const notifId = result.rows[0].id;

      // Send multiple read requests concurrently
      const promises = Array(5).fill().map(() => 
        request(app)
          .put(`/api/notifications/${notifId}/read`)
          .set('Authorization', `Bearer ${authToken}`)
      );

      const results = await Promise.all(promises);
      
      // All should succeed
      results.forEach(res => {
        expect(res.status).toBe(200);
      });

      // Notification should still be marked as read only once
      const check = await pool.query(
        'SELECT read FROM notifications WHERE id = $1',
        [notifId]
      );
      expect(check.rows[0].read).toBe(true);
    });

    it('should validate notification ID format', async () => {
      const res = await request(app)
        .put('/api/notifications/invalid-id/read')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(400);
    });

    it('should handle large number of notifications', async () => {
      // Create many notifications
      const values = Array(50).fill().map((_, i) => 
        `(${userId}, 'like', '${JSON.stringify({ actorId: otherUserId }).replace(/'/g, "''")}', false, NOW() - INTERVAL '${i} minutes')`
      ).join(',');
      
      await pool.query(`
        INSERT INTO notifications (user_id, type, data, read, created_at)
        VALUES ${values}
      `);

      const res = await request(app)
        .get('/api/notifications?limit=100')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.notifications.length).toBeGreaterThan(40);
    });
  });
});
