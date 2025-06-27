const express = require('express');
const { body, param, validationResult } = require('express-validator');
const Friendship = require('../models/Friendship');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// All friendship routes require authentication
router.use(verifyToken);

// Send a friend request
router.post('/request', [
  body('userId').isInt({ min: 1 }).withMessage('Valid user ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { userId } = req.body;
    const requesterId = req.user.id;

    const friendship = await Friendship.sendFriendRequest(requesterId, userId);

    res.status(201).json({
      message: 'Friend request sent successfully',
      friendship: {
        id: friendship.id,
        user_id: friendship.user_id,
        friend_id: friendship.friend_id,
        status: friendship.status,
        createdAt: friendship.created_at
      }
    });

  } catch (error) {
    console.error('Send friend request error:', error);
    if (error.message.includes('Cannot send friend request to yourself') ||
        error.message.includes('already exists')) {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to send friend request' });
  }
});

// Accept a friend request
router.put('/:id/accept', [
  param('id').isInt({ min: 1 }).withMessage('Valid friendship ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const friendshipId = parseInt(req.params.id);
    const userId = req.user.id;

    const friendship = await Friendship.acceptFriendRequest(friendshipId, userId);

    res.json({
      message: 'Friend request accepted successfully',
      friendship: {
        id: friendship.id,
        requesterId: friendship.requester_id,
        addresseeId: friendship.addressee_id,
        status: friendship.status,
        createdAt: friendship.created_at,
        updatedAt: friendship.updated_at
      }
    });

  } catch (error) {
    console.error('Accept friend request error:', error);
    if (error.message.includes('not found') || error.message.includes('not authorized')) {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to accept friend request' });
  }
});

// Decline a friend request
router.put('/:id/decline', [
  param('id').isInt({ min: 1 }).withMessage('Valid friendship ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const friendshipId = parseInt(req.params.id);
    const userId = req.user.id;

    const friendship = await Friendship.declineFriendRequest(friendshipId, userId);

    res.json({
      message: 'Friend request declined successfully',
      friendship: {
        id: friendship.id,
        requesterId: friendship.requester_id,
        addresseeId: friendship.addressee_id,
        status: friendship.status,
        updatedAt: friendship.updated_at
      }
    });

  } catch (error) {
    console.error('Decline friend request error:', error);
    if (error.message.includes('not found') || error.message.includes('not authorized')) {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to decline friend request' });
  }
});

// Cancel a sent friend request
router.delete('/:id/cancel', [
  param('id').isInt({ min: 1 }).withMessage('Valid friendship ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const friendshipId = parseInt(req.params.id);
    const userId = req.user.id;

    const result = await Friendship.cancelFriendRequest(friendshipId, userId);

    res.json(result);

  } catch (error) {
    console.error('Cancel friend request error:', error);
    if (error.message.includes('not found') || error.message.includes('not authorized')) {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to cancel friend request' });
  }
});

// Get user's friends list
router.get('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const friends = await Friendship.getFriends(userId);

    res.json({
      message: 'Friends retrieved successfully',
      friends: friends.map(friendship => ({
        friendshipId: friendship.friendshipId,
        status: friendship.status,
        friendshipCreatedAt: friendship.friendshipCreatedAt,
        friend: {
          id: friendship.friend.id,
          email: friendship.friend.email,
          firstName: friendship.friend.firstName,
          lastName: friendship.friend.lastName,
          phone: friendship.friend.phone,
          profileImageUrl: friendship.friend.profileImageUrl,
          fullName: `${friendship.friend.firstName} ${friendship.friend.lastName}`
        }
      }))
    });

  } catch (error) {
    console.error('Get friends error:', error);
    res.status(500).json({ error: 'Failed to get friends list' });
  }
});

// Get pending friend requests (both sent and received)
router.get('/requests', async (req, res) => {
  try {
    const userId = req.user.id;
    const requests = await Friendship.getPendingRequests(userId);

    res.json({
      message: 'Friend requests retrieved successfully',
      requests: requests.map(request => ({
        friendshipId: request.friendshipId,
        status: request.status,
        createdAt: request.createdAt,
        requestType: request.requestType, // 'sent' or 'received'
        otherUser: {
          id: request.otherUser.id,
          email: request.otherUser.email,
          firstName: request.otherUser.firstName,
          lastName: request.otherUser.lastName,
          phone: request.otherUser.phone,
          profileImageUrl: request.otherUser.profileImageUrl,
          fullName: `${request.otherUser.firstName} ${request.otherUser.lastName}`
        }
      }))
    });

  } catch (error) {
    console.error('Get friend requests error:', error);
    res.status(500).json({ error: 'Failed to get friend requests' });
  }
});

// Remove a friend
router.delete('/:friendId', [
  param('friendId').isInt({ min: 1 }).withMessage('Valid friend ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const friendId = parseInt(req.params.friendId);
    const userId = req.user.id;

    const result = await Friendship.removeFriend(userId, friendId);

    res.json(result);

  } catch (error) {
    console.error('Remove friend error:', error);
    if (error.message.includes('not found') || error.message.includes('not authorized')) {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to remove friend' });
  }
});

// Get friendship status with another user
router.get('/status/:userId', [
  param('userId').isInt({ min: 1 }).withMessage('Valid user ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const otherUserId = parseInt(req.params.userId);
    const userId = req.user.id;

    const friendship = await Friendship.getFriendshipStatus(userId, otherUserId);

    if (friendship) {
      res.json({
        friendship: {
          id: friendship.id,
          requesterId: friendship.user_id,
          addresseeId: friendship.friend_id,
          status: friendship.status,
          createdAt: friendship.created_at,
          updatedAt: friendship.updated_at,
          isRequester: friendship.user_id === userId
        }
      });
    } else {
      res.json({ friendship: null });
    }

  } catch (error) {
    console.error('Get friendship status error:', error);
    res.status(500).json({ error: 'Failed to get friendship status' });
  }
});

// Connect via QR code
router.post('/qr-connect', [
  body('qrData').isString().isLength({ min: 1 }).withMessage('QR data is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { qrData } = req.body;
    const requesterId = req.user.id;

    // Parse QR data - expected format: "barkpark://user/{userId}/{timestamp}"
    const qrMatch = qrData.match(/^barkpark:\/\/user\/(\d+)\/(\d+)$/);
    if (!qrMatch) {
      return res.status(400).json({ error: 'Invalid QR code format' });
    }

    const targetUserId = parseInt(qrMatch[1]);
    const timestamp = parseInt(qrMatch[2]);

    // Check if QR code is expired (5 minutes = 300000 ms)
    const now = Date.now();
    const fiveMinutes = 5 * 60 * 1000;
    if (now - timestamp > fiveMinutes) {
      return res.status(400).json({ error: 'QR code has expired. Please ask for a new one.' });
    }

    // Validate target user exists
    const User = require('../models/User');
    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Prevent self-friend request
    if (targetUserId === requesterId) {
      return res.status(400).json({ error: 'Cannot add yourself as a friend' });
    }

    // Check if friendship already exists
    const existingFriendship = await Friendship.findExistingFriendship(requesterId, targetUserId);
    if (existingFriendship) {
      if (existingFriendship.status === 'accepted') {
        return res.status(400).json({ error: 'You are already friends with this user' });
      } else if (existingFriendship.status === 'pending') {
        return res.status(400).json({ error: 'Friend request already pending' });
      }
    }

    // Send friend request
    const friendship = await Friendship.sendFriendRequest(requesterId, targetUserId);

    res.status(201).json({
      message: 'Friend request sent successfully via QR code',
      friendship: {
        id: friendship.id,
        requesterId: friendship.requester_id,
        addresseeId: friendship.addressee_id,
        status: friendship.status,
        createdAt: friendship.created_at
      },
      targetUser: {
        id: targetUser.id,
        email: targetUser.email,
        firstName: targetUser.first_name,
        lastName: targetUser.last_name,
        fullName: `${targetUser.first_name} ${targetUser.last_name}`
      }
    });

  } catch (error) {
    console.error('QR connect error:', error);
    if (error.message.includes('Cannot send friend request to yourself') ||
        error.message.includes('already exists')) {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to connect via QR code' });
  }
});

module.exports = router;