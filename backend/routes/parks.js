const express = require('express');
const { body, query, validationResult } = require('express-validator');
const DogPark = require('../models/DogPark');
const CheckIn = require('../models/CheckIn');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(verifyToken);

// Get nearby parks with optional filtering
router.get('/', [
  query('latitude').isFloat({ min: -90, max: 90 }).withMessage('Valid latitude required'),
  query('longitude').isFloat({ min: -180, max: 180 }).withMessage('Valid longitude required'),
  query('radius').optional().isFloat({ min: 0.1, max: 100 }).withMessage('Radius must be between 0.1 and 100 km')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { latitude, longitude, radius = 10 } = req.query;
    
    const parks = await DogPark.findNearby(
      parseFloat(latitude), 
      parseFloat(longitude), 
      parseFloat(radius)
    );

    // Add activity levels to each park
    const parksWithActivity = await Promise.all(
      parks.map(async (park) => {
        const activityLevel = await DogPark.getActivityLevel(park.id);
        const stats = await CheckIn.getParkActivityStats(park.id);
        return {
          ...park,
          activityLevel,
          currentVisitors: stats.currentCheckIns
        };
      })
    );

    res.json({
      parks: parksWithActivity,
      total: parksWithActivity.length,
      radius: parseFloat(radius),
      center: {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude)
      }
    });

  } catch (error) {
    console.error('Get nearby parks error:', error);
    res.status(500).json({ error: 'Failed to fetch nearby parks' });
  }
});

// Get all parks (for admin or full listing)
router.get('/all', async (req, res) => {
  try {
    const parks = await DogPark.findAll();
    res.json({ parks });
  } catch (error) {
    console.error('Get all parks error:', error);
    res.status(500).json({ error: 'Failed to fetch parks' });
  }
});

// Get specific park by ID with detailed information
router.get('/:id', async (req, res) => {
  try {
    const park = await DogPark.findById(req.params.id);
    
    if (!park) {
      return res.status(404).json({ error: 'Park not found' });
    }

    // Get additional park information
    const activityLevel = await DogPark.getActivityLevel(park.id);
    const stats = await CheckIn.getParkActivityStats(park.id);
    const activeVisitors = await CheckIn.findActiveByPark(park.id);
    const friendsAtPark = await CheckIn.getFriendsAtPark(req.user.id, park.id);

    res.json({
      park: {
        ...park,
        activityLevel,
        stats,
        activeVisitors: activeVisitors.length,
        friendsPresent: friendsAtPark.length,
        friends: friendsAtPark
      }
    });

  } catch (error) {
    console.error('Get park details error:', error);
    res.status(500).json({ error: 'Failed to fetch park details' });
  }
});

// Get current activity for a specific park
router.get('/:id/activity', async (req, res) => {
  try {
    const park = await DogPark.findById(req.params.id);
    
    if (!park) {
      return res.status(404).json({ error: 'Park not found' });
    }

    const activityLevel = await DogPark.getActivityLevel(park.id);
    const stats = await CheckIn.getParkActivityStats(park.id);
    const activeVisitors = await CheckIn.findActiveByPark(park.id);

    res.json({
      parkId: park.id,
      activityLevel,
      stats,
      activeVisitors,
      lastUpdated: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get park activity error:', error);
    res.status(500).json({ error: 'Failed to fetch park activity' });
  }
});

// Get friends currently at a specific park
router.get('/:id/friends', async (req, res) => {
  try {
    const park = await DogPark.findById(req.params.id);
    
    if (!park) {
      return res.status(404).json({ error: 'Park not found' });
    }

    const friendsAtPark = await CheckIn.getFriendsAtPark(req.user.id, park.id);

    res.json({
      parkId: park.id,
      friendsPresent: friendsAtPark.length,
      friends: friendsAtPark
    });

  } catch (error) {
    console.error('Get friends at park error:', error);
    res.status(500).json({ error: 'Failed to fetch friends at park' });
  }
});

// Check into a park
router.post('/:id/checkin', [
  body('dogsPresent').optional().isArray().withMessage('Dogs present must be an array of dog IDs')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const park = await DogPark.findById(req.params.id);
    if (!park) {
      return res.status(404).json({ error: 'Park not found' });
    }

    // Check if user is already checked in to this park
    const existingCheckIn = await CheckIn.findByUserAndPark(req.user.id, park.id);
    if (existingCheckIn) {
      return res.status(400).json({ 
        error: 'Already checked in to this park',
        checkIn: existingCheckIn
      });
    }

    const checkIn = await CheckIn.create({
      userId: req.user.id,
      dogParkId: park.id,
      dogsPresent: req.body.dogsPresent || []
    });

    res.status(201).json({
      message: 'Checked in successfully',
      checkIn,
      park
    });

  } catch (error) {
    console.error('Check in error:', error);
    res.status(500).json({ error: 'Failed to check in to park' });
  }
});

// Check out of a park
router.put('/:id/checkout', async (req, res) => {
  try {
    const park = await DogPark.findById(req.params.id);
    if (!park) {
      return res.status(404).json({ error: 'Park not found' });
    }

    const checkOut = await CheckIn.checkOutByPark(req.user.id, park.id);
    if (!checkOut) {
      return res.status(400).json({ error: 'No active check-in found for this park' });
    }

    res.json({
      message: 'Checked out successfully',
      checkOut,
      park
    });

  } catch (error) {
    console.error('Check out error:', error);
    res.status(500).json({ error: 'Failed to check out of park' });
  }
});

// Get user's check-in history
router.get('/user/history', async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const history = await CheckIn.getRecentHistory(req.user.id, parseInt(limit));

    res.json({
      history,
      total: history.length
    });

  } catch (error) {
    console.error('Get check-in history error:', error);
    res.status(500).json({ error: 'Failed to fetch check-in history' });
  }
});

// Get user's current active check-ins
router.get('/user/active', async (req, res) => {
  try {
    const activeCheckIns = await CheckIn.findActiveByUser(req.user.id);

    res.json({
      activeCheckIns,
      total: activeCheckIns.length
    });

  } catch (error) {
    console.error('Get active check-ins error:', error);
    res.status(500).json({ error: 'Failed to fetch active check-ins' });
  }
});

// Admin routes (if needed later)

// Create new park (admin only - placeholder for future implementation)
router.post('/', [
  body('name').trim().isLength({ min: 1 }).withMessage('Park name is required'),
  body('address').trim().isLength({ min: 1 }).withMessage('Park address is required'),
  body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Valid latitude required'),
  body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Valid longitude required'),
  body('amenities').optional().isArray(),
  body('rules').optional().trim(),
  body('hoursOpen').optional().matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/),
  body('hoursClose').optional().matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/)
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    // TODO: Add admin role check here
    
    const park = await DogPark.create(req.body);

    res.status(201).json({
      message: 'Park created successfully',
      park
    });

  } catch (error) {
    console.error('Create park error:', error);
    res.status(500).json({ error: 'Failed to create park' });
  }
});

module.exports = router;