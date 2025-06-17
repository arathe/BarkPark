const express = require('express');
const { param, validationResult } = require('express-validator');
const User = require('../models/User');
const Dog = require('../models/Dog');
const CheckIn = require('../models/CheckIn');
const Friendship = require('../models/Friendship');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// All user profile routes require authentication
router.use(verifyToken);

// Get user profile by ID (for friends and users who have sent friend requests)
router.get('/:userId/profile', [
  param('userId').isInt({ min: 1 }).withMessage('Valid user ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const targetUserId = parseInt(req.params.userId);
    const requestingUserId = req.user.id;

    // Check if the requesting user can view this profile
    // Users can view profiles if:
    // 1. It's their own profile
    // 2. They are friends
    // 3. They have a pending friend request (sent or received)
    
    if (targetUserId !== requestingUserId) {
      const friendship = await Friendship.getFriendshipStatus(requestingUserId, targetUserId);
      
      if (!friendship) {
        return res.status(403).json({ 
          error: 'You must be friends or have a pending friend request to view this profile' 
        });
      }
    }

    // Get user information
    const user = await User.findById(targetUserId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get user's dogs
    const dogs = await Dog.findByUserId(targetUserId);

    // Get user's recent check-ins (last 3)
    const recentCheckIns = await CheckIn.getUserHistory(targetUserId, 3);

    // Format the response
    const profileData = {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        fullName: `${user.first_name} ${user.last_name}`,
        profileImageUrl: user.profile_image_url,
        createdAt: user.created_at
      },
      dogs: dogs.map(dog => ({
        id: dog.id,
        name: dog.name,
        breed: dog.breed,
        age: dog.age,
        gender: dog.gender,
        weight: dog.weight,
        description: dog.description,
        profileImageUrl: dog.profile_image_url,
        createdAt: dog.created_at
      })),
      recentCheckIns: recentCheckIns.map(checkIn => ({
        id: checkIn.id,
        parkName: checkIn.parkName,
        parkAddress: checkIn.parkAddress,
        checkedInAt: checkIn.checkedInAt,
        checkedOutAt: checkIn.checkedOutAt,
        dogsPresent: checkIn.dogsPresent
      }))
    };

    res.json(profileData);

  } catch (error) {
    console.error('Get user profile error:', error);
    res.status(500).json({ error: 'Failed to get user profile' });
  }
});

module.exports = router;