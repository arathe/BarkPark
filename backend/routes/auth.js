const express = require('express');
const { body, query, validationResult } = require('express-validator');
const User = require('../models/User');
const { generateToken, verifyToken } = require('../middleware/auth');

const router = express.Router();

// Register new user
router.post('/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('firstName').trim().isLength({ min: 1 }).withMessage('First name is required'),
  body('lastName').trim().isLength({ min: 1 }).withMessage('Last name is required'),
  body('phone').optional().isMobilePhone()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, firstName, lastName, phone } = req.body;

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(409).json({ error: 'User with this email already exists' });
    }

    // Create new user
    const user = await User.create({
      email,
      password,
      firstName,
      lastName,
      phone
    });

    // Generate JWT token
    const token = generateToken(user.id);

    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        phone: user.phone,
        profileImageUrl: user.profile_image_url,
        isSearchable: user.is_searchable
      },
      token
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// Login user
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').exists().withMessage('Password is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;

    // Find user by email
    const user = await User.findByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Validate password
    const isValidPassword = await User.validatePassword(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = generateToken(user.id);

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        phone: user.phone,
        profileImageUrl: user.profile_image_url,
        isSearchable: user.is_searchable
      },
      token
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Get current user profile
router.get('/me', verifyToken, async (req, res) => {
  try {
    res.json({
      user: {
        id: req.user.id,
        email: req.user.email,
        firstName: req.user.first_name,
        lastName: req.user.last_name,
        phone: req.user.phone,
        profileImageUrl: req.user.profile_image_url,
        isSearchable: req.user.is_searchable
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to get user profile' });
  }
});

// Update user profile
router.put('/me', verifyToken, [
  body('firstName').optional().trim().isLength({ min: 1 }),
  body('lastName').optional().trim().isLength({ min: 1 }),
  body('phone').optional().isMobilePhone(),
  body('isSearchable').optional().isBoolean().withMessage('isSearchable must be a boolean')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const updates = {};
    if (req.body.firstName) updates.first_name = req.body.firstName;
    if (req.body.lastName) updates.last_name = req.body.lastName;
    if (req.body.phone) updates.phone = req.body.phone;
    if (req.body.profileImageUrl) updates.profile_image_url = req.body.profileImageUrl;
    if (req.body.isSearchable !== undefined) updates.is_searchable = req.body.isSearchable;

    const updatedUser = await User.updateProfile(req.user.id, updates);

    res.json({
      message: 'Profile updated successfully',
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        firstName: updatedUser.first_name,
        lastName: updatedUser.last_name,
        phone: updatedUser.phone,
        profileImageUrl: updatedUser.profile_image_url,
        isSearchable: updatedUser.is_searchable
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Search users by name or email
router.get('/search', verifyToken, [
  query('q').isLength({ min: 2 }).withMessage('Search query must be at least 2 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const searchQuery = req.query.q.trim();
    const currentUserId = req.user.id;

    const query = `
      SELECT id, email, first_name, last_name, phone, profile_image_url, is_searchable
      FROM users
      WHERE id != $1 
        AND is_searchable = true
        AND (
          LOWER(first_name) LIKE LOWER($2) OR
          LOWER(last_name) LIKE LOWER($2) OR
          LOWER(CONCAT(first_name, ' ', last_name)) LIKE LOWER($2) OR
          LOWER(email) LIKE LOWER($2)
        )
      ORDER BY 
        CASE 
          WHEN LOWER(CONCAT(first_name, ' ', last_name)) LIKE LOWER($3) THEN 1
          WHEN LOWER(first_name) LIKE LOWER($3) OR LOWER(last_name) LIKE LOWER($3) THEN 2
          ELSE 3
        END,
        first_name, last_name
      LIMIT 20
    `;

    const searchPattern = `%${searchQuery}%`;
    const exactPattern = `${searchQuery}%`;
    const values = [currentUserId, searchPattern, exactPattern];

    const pool = require('../config/database');
    const result = await pool.query(query, values);

    const users = result.rows.map(user => ({
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      phone: user.phone,
      profileImageUrl: user.profile_image_url,
      isSearchable: user.is_searchable,
      fullName: `${user.first_name} ${user.last_name}`
    }));

    res.json({
      message: 'Users found successfully',
      users,
      count: users.length
    });

  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({ error: 'Failed to search users' });
  }
});

module.exports = router;