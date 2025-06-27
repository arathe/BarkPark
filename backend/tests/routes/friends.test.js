const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');
const Friendship = require('../../models/Friendship');
const pool = require('../../config/database');
const jwt = require('jsonwebtoken');

describe('Friends API Routes', () => {
  let user1, user2, user3, user4;
  let authToken1, authToken2, authToken3;
  
  beforeEach(async () => {
    // Create test users
    user1 = await User.create({
      email: 'friendapi1@test.com',
      password: 'password123',
      firstName: 'API',
      lastName: 'User1'
    });
    
    user2 = await User.create({
      email: 'friendapi2@test.com',
      password: 'password123',
      firstName: 'API',
      lastName: 'User2'
    });
    
    user3 = await User.create({
      email: 'friendapi3@test.com',
      password: 'password123',
      firstName: 'API',
      lastName: 'User3'
    });
    
    user4 = await User.create({
      email: 'friendapi4@test.com',
      password: 'password123',
      firstName: 'API',
      lastName: 'User4'
    });
    
    // Generate auth tokens
    authToken1 = jwt.sign({ userId: user1.id }, process.env.JWT_SECRET);
    authToken2 = jwt.sign({ userId: user2.id }, process.env.JWT_SECRET);
    authToken3 = jwt.sign({ userId: user3.id }, process.env.JWT_SECRET);
  });

  afterEach(async () => {
    // Clean up
    await pool.query('DELETE FROM friendships WHERE user_id IN ($1, $2, $3, $4) OR friend_id IN ($1, $2, $3, $4)', 
      [user1.id, user2.id, user3.id, user4.id]);
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3, $4)', 
      [user1.id, user2.id, user3.id, user4.id]);
  });

  describe('POST /api/friends/request', () => {
    test('should send friend request successfully', async () => {
      const response = await request(app)
        .post('/api/friends/request')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ userId: user2.id })
        .expect(201);

      expect(response.body.message).toBe('Friend request sent successfully');
      expect(response.body.friendship).toMatchObject({
        user_id: user1.id,
        friend_id: user2.id,
        status: 'pending'
      });
    });

    test('should require authentication', async () => {
      await request(app)
        .post('/api/friends/request')
        .send({ userId: user2.id })
        .expect(401);
    });

    test('should validate userId parameter', async () => {
      const response = await request(app)
        .post('/api/friends/request')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ userId: 'invalid' })
        .expect(400);

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].msg).toContain('Valid user ID is required');
    });

    test('should prevent self-friendship', async () => {
      const response = await request(app)
        .post('/api/friends/request')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ userId: user1.id })
        .expect(400);

      expect(response.body.error).toContain('Cannot send friend request to yourself');
    });

    test('should prevent duplicate requests', async () => {
      // First request
      await request(app)
        .post('/api/friends/request')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ userId: user2.id })
        .expect(201);

      // Duplicate request
      const response = await request(app)
        .post('/api/friends/request')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ userId: user2.id })
        .expect(400);

      expect(response.body.error).toContain('already exists');
    });

    test('should prevent request when already friends', async () => {
      // Create accepted friendship
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship.id, user2.id);

      const response = await request(app)
        .post('/api/friends/request')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ userId: user2.id })
        .expect(400);

      expect(response.body.error).toContain('already exists');
    });
  });

  describe('PUT /api/friends/:id/accept', () => {
    let friendship;

    beforeEach(async () => {
      friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
    });

    test('should accept friend request as addressee', async () => {
      const response = await request(app)
        .put(`/api/friends/${friendship.id}/accept`)
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(200);

      expect(response.body.message).toBe('Friend request accepted successfully');
      expect(response.body.friendship.status).toBe('accepted');
    });

    test('should not allow requester to accept own request', async () => {
      const response = await request(app)
        .put(`/api/friends/${friendship.id}/accept`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(404);

      expect(response.body.error).toContain('not found or not authorized');
    });

    test('should not allow third party to accept request', async () => {
      const response = await request(app)
        .put(`/api/friends/${friendship.id}/accept`)
        .set('Authorization', `Bearer ${authToken3}`)
        .expect(404);

      expect(response.body.error).toContain('not found or not authorized');
    });

    test('should validate friendship ID', async () => {
      const response = await request(app)
        .put('/api/friends/invalid/accept')
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(400);

      expect(response.body.errors).toBeDefined();
    });

    test('should handle non-existent friendship', async () => {
      await request(app)
        .put('/api/friends/99999/accept')
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(404);
    });
  });

  describe('PUT /api/friends/:id/decline', () => {
    let friendship;

    beforeEach(async () => {
      friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
    });

    test('should decline friend request as addressee', async () => {
      const response = await request(app)
        .put(`/api/friends/${friendship.id}/decline`)
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(200);

      expect(response.body.message).toBe('Friend request declined successfully');
      expect(response.body.friendship.status).toBe('declined');
    });

    test('should not allow requester to decline own request', async () => {
      await request(app)
        .put(`/api/friends/${friendship.id}/decline`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(404);
    });
  });

  describe('DELETE /api/friends/:id/cancel', () => {
    let friendship;

    beforeEach(async () => {
      friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
    });

    test('should cancel friend request as requester', async () => {
      const response = await request(app)
        .delete(`/api/friends/${friendship.id}/cancel`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('cancelled successfully');
    });

    test('should not allow addressee to cancel received request', async () => {
      await request(app)
        .delete(`/api/friends/${friendship.id}/cancel`)
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(404);
    });

    test('should not allow canceling accepted request', async () => {
      await Friendship.acceptFriendRequest(friendship.id, user2.id);

      await request(app)
        .delete(`/api/friends/${friendship.id}/cancel`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(404);
    });
  });

  describe('GET /api/friends', () => {
    test('should return empty array when no friends', async () => {
      const response = await request(app)
        .get('/api/friends')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.friends).toEqual([]);
    });

    test('should return friends list', async () => {
      // Create friendships
      const f1 = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(f1.id, user2.id);
      
      const f2 = await Friendship.sendFriendRequest(user3.id, user1.id);
      await Friendship.acceptFriendRequest(f2.id, user1.id);

      const response = await request(app)
        .get('/api/friends')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.friends.length).toBe(2);
      const friendIds = response.body.friends.map(f => f.friend.id).sort();
      expect(friendIds).toEqual([user2.id, user3.id].sort());
    });

    test('should format friend data correctly', async () => {
      const f = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(f.id, user2.id);

      const response = await request(app)
        .get('/api/friends')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.friends[0]).toMatchObject({
        friendshipId: f.id,
        status: 'accepted',
        friend: {
          id: user2.id,
          email: user2.email,
          firstName: 'API',
          lastName: 'User2',
          fullName: 'API User2'
        }
      });
    });
  });

  describe('GET /api/friends/requests', () => {
    test('should return both sent and received requests', async () => {
      // User1 sends to User2
      await Friendship.sendFriendRequest(user1.id, user2.id);
      
      // User3 sends to User1
      await Friendship.sendFriendRequest(user3.id, user1.id);

      const response = await request(app)
        .get('/api/friends/requests')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.requests.length).toBe(2);
      
      const sent = response.body.requests.filter(r => r.requestType === 'sent');
      const received = response.body.requests.filter(r => r.requestType === 'received');
      
      expect(sent.length).toBe(1);
      expect(received.length).toBe(1);
      expect(sent[0].otherUser.id).toBe(user2.id);
      expect(received[0].otherUser.id).toBe(user3.id);
    });

    test('should not include accepted or declined requests', async () => {
      const f1 = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(f1.id, user2.id);
      
      const f2 = await Friendship.sendFriendRequest(user3.id, user1.id);
      await Friendship.declineFriendRequest(f2.id, user1.id);
      
      const f3 = await Friendship.sendFriendRequest(user1.id, user4.id);

      const response = await request(app)
        .get('/api/friends/requests')
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.requests.length).toBe(1);
      expect(response.body.requests[0].otherUser.id).toBe(user4.id);
    });
  });

  describe('DELETE /api/friends/:friendId', () => {
    test('should remove friendship', async () => {
      const f = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(f.id, user2.id);

      await request(app)
        .delete(`/api/friends/${user2.id}`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      // Verify friendship is removed
      const friends = await Friendship.getFriends(user1.id);
      expect(friends.length).toBe(0);
    });

    test('should allow either user to remove friendship', async () => {
      const f = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(f.id, user2.id);

      await request(app)
        .delete(`/api/friends/${user1.id}`)
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(200);
    });

    test('should handle non-existent friendship', async () => {
      await request(app)
        .delete(`/api/friends/${user2.id}`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(404);
    });
  });

  describe('GET /api/friends/status/:userId', () => {
    test('should return null when no relationship exists', async () => {
      const response = await request(app)
        .get(`/api/friends/status/${user2.id}`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.friendship).toBeNull();
    });

    test('should return friendship status', async () => {
      const f = await Friendship.sendFriendRequest(user1.id, user2.id);

      const response = await request(app)
        .get(`/api/friends/status/${user2.id}`)
        .set('Authorization', `Bearer ${authToken1}`)
        .expect(200);

      expect(response.body.friendship).toMatchObject({
        id: f.id,
        status: 'pending',
        isRequester: true
      });
    });

    test('should work bidirectionally', async () => {
      const f = await Friendship.sendFriendRequest(user1.id, user2.id);

      const response = await request(app)
        .get(`/api/friends/status/${user1.id}`)
        .set('Authorization', `Bearer ${authToken2}`)
        .expect(200);

      expect(response.body.friendship).toMatchObject({
        id: f.id,
        status: 'pending',
        isRequester: false
      });
    });
  });

  describe('POST /api/friends/qr-connect', () => {
    test('should connect via valid QR code', async () => {
      const timestamp = Date.now();
      const qrData = `barkpark://user/${user2.id}/${timestamp}`;

      const response = await request(app)
        .post('/api/friends/qr-connect')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ qrData })
        .expect(201);

      expect(response.body.message).toContain('QR code');
      expect(response.body.targetUser.id).toBe(user2.id);
    });

    test('should reject expired QR code', async () => {
      const timestamp = Date.now() - (6 * 60 * 1000); // 6 minutes ago
      const qrData = `barkpark://user/${user2.id}/${timestamp}`;

      const response = await request(app)
        .post('/api/friends/qr-connect')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ qrData })
        .expect(400);

      expect(response.body.error).toContain('expired');
    });

    test('should validate QR code format', async () => {
      const response = await request(app)
        .post('/api/friends/qr-connect')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ qrData: 'invalid-format' })
        .expect(400);

      expect(response.body.error).toContain('Invalid QR code format');
    });

    test('should prevent self-connection via QR', async () => {
      const timestamp = Date.now();
      const qrData = `barkpark://user/${user1.id}/${timestamp}`;

      const response = await request(app)
        .post('/api/friends/qr-connect')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ qrData })
        .expect(400);

      expect(response.body.error).toContain('Cannot add yourself');
    });

    test('should handle non-existent user in QR code', async () => {
      const timestamp = Date.now();
      const qrData = `barkpark://user/99999/${timestamp}`;

      const response = await request(app)
        .post('/api/friends/qr-connect')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ qrData })
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });

    test('should prevent duplicate request via QR', async () => {
      await Friendship.sendFriendRequest(user1.id, user2.id);

      const timestamp = Date.now();
      const qrData = `barkpark://user/${user2.id}/${timestamp}`;

      const response = await request(app)
        .post('/api/friends/qr-connect')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ qrData })
        .expect(400);

      expect(response.body.error).toContain('already pending');
    });

    test('should prevent QR connect when already friends', async () => {
      const f = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(f.id, user2.id);

      const timestamp = Date.now();
      const qrData = `barkpark://user/${user2.id}/${timestamp}`;

      const response = await request(app)
        .post('/api/friends/qr-connect')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ qrData })
        .expect(400);

      expect(response.body.error).toContain('already friends');
    });

    test('should handle edge case QR timestamp exactly at expiration', async () => {
      const timestamp = Date.now() - (5 * 60 * 1000); // Exactly 5 minutes
      const qrData = `barkpark://user/${user2.id}/${timestamp}`;

      const response = await request(app)
        .post('/api/friends/qr-connect')
        .set('Authorization', `Bearer ${authToken1}`)
        .send({ qrData })
        .expect(400);

      expect(response.body.error).toContain('expired');
    });
  });

  describe('Authorization edge cases', () => {
    test('should handle invalid auth token', async () => {
      await request(app)
        .get('/api/friends')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });

    test('should handle missing auth header', async () => {
      await request(app)
        .get('/api/friends')
        .expect(401);
    });

    test('should handle user deletion after token generation', async () => {
      const tempUser = await User.create({
        email: 'temp@test.com',
        password: 'password123',
        firstName: 'Temp',
        lastName: 'User'
      });
      
      const tempToken = jwt.sign({ userId: tempUser.id }, process.env.JWT_SECRET);
      
      // Delete the user
      await pool.query('DELETE FROM users WHERE id = $1', [tempUser.id]);
      
      // Try to use the token
      await request(app)
        .get('/api/friends')
        .set('Authorization', `Bearer ${tempToken}`)
        .expect(401);
    });
  });
});