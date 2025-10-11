const express = require('express');
const { body, param, validationResult } = require('express-validator');
const Dog = require('../models/Dog');
const { verifyToken } = require('../middleware/auth');
const { uploadSingle, uploadMultiple } = require('../middleware/upload');
const { uploadToS3, deleteFromS3, generateFilename } = require('../config/s3');
const { DogMembership, MembershipError } = require('../models/DogMembership');

const router = express.Router();

// All routes require authentication
router.use(verifyToken);

const handleMembershipError = (res, error) => {
  if (error instanceof MembershipError) {
    res.status(error.statusCode || 400).json({ error: error.message });
    return true;
  }
  return false;
};

// Get all dogs for current user
router.get('/', async (req, res) => {
  try {
    const dogs = await Dog.findByUserId(req.user.id);
    res.json({ dogs });
  } catch (error) {
    console.error('Get dogs error:', error);
    res.status(500).json({ error: 'Failed to fetch dogs' });
  }
});

// Get specific dog by ID
router.get('/:id', async (req, res) => {
  try {
    const dog = await Dog.findByIdAndUser(req.params.id, req.user.id);
    
    if (!dog) {
      return res.status(404).json({ error: 'Dog not found' });
    }

    res.json({ dog });
  } catch (error) {
    console.error('Get dog error:', error);
    res.status(500).json({ error: 'Failed to fetch dog' });
  }
});

// Create new dog profile
router.post('/', [
  body('name').trim().isLength({ min: 1 }).withMessage('Dog name is required'),
  body('breed').optional().trim().isLength({ max: 100 }),
  body('birthday').optional().isISO8601().withMessage('Invalid birthday format'),
  body('weight').optional().isNumeric().withMessage('Weight must be a number'),
  body('gender').optional().isIn(['male', 'female', 'unknown']),
  body('sizeCategory').optional().isIn(['small', 'medium', 'large']),
  body('energyLevel').optional().isIn(['low', 'medium', 'high']),
  body('friendlinessDogs').optional().isInt({ min: 1, max: 5 }),
  body('friendlinessPeople').optional().isInt({ min: 1, max: 5 }),
  body('trainingLevel').optional().isIn(['puppy', 'basic', 'advanced']),
  body('favoriteActivities').optional().isArray(),
  body('isVaccinated').optional().isBoolean(),
  body('isSpayedNeutered').optional().isBoolean(),
  body('specialNeeds').optional().trim(),
  body('bio').optional().trim().isLength({ max: 1000 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const dogData = {
      userId: req.user.id,
      name: req.body.name,
      breed: req.body.breed,
      birthday: req.body.birthday,
      weight: req.body.weight,
      gender: req.body.gender || 'unknown',
      sizeCategory: req.body.sizeCategory || 'medium',
      energyLevel: req.body.energyLevel || 'medium',
      friendlinessDogs: req.body.friendlinessDogs || 3,
      friendlinessPeople: req.body.friendlinessPeople || 3,
      trainingLevel: req.body.trainingLevel || 'basic',
      favoriteActivities: req.body.favoriteActivities || [],
      isVaccinated: req.body.isVaccinated || false,
      isSpayedNeutered: req.body.isSpayedNeutered || false,
      specialNeeds: req.body.specialNeeds,
      bio: req.body.bio
    };

    const dog = await Dog.create(dogData);

    res.status(201).json({
      message: 'Dog profile created successfully',
      dog
    });

  } catch (error) {
    console.error('Create dog error:', error);
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      code: error.code
    });
    res.status(500).json({ error: 'Failed to create dog profile', details: error.message });
  }
});

// Update dog profile
router.put('/:id', [
  body('name').optional().trim().isLength({ min: 1 }),
  body('breed').optional().trim().isLength({ max: 100 }),
  body('birthday').optional().isISO8601(),
  body('weight').optional().isNumeric(),
  body('gender').optional().isIn(['male', 'female', 'unknown']),
  body('sizeCategory').optional().isIn(['small', 'medium', 'large']),
  body('energyLevel').optional().isIn(['low', 'medium', 'high']),
  body('friendlinessDogs').optional().isInt({ min: 1, max: 5 }),
  body('friendlinessPeople').optional().isInt({ min: 1, max: 5 }),
  body('trainingLevel').optional().isIn(['puppy', 'basic', 'advanced']),
  body('favoriteActivities').optional().isArray(),
  body('isVaccinated').optional().isBoolean(),
  body('isSpayedNeutered').optional().isBoolean(),
  body('specialNeeds').optional().trim(),
  body('bio').optional().trim().isLength({ max: 1000 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const updates = {};
    const allowedFields = [
      'name', 'breed', 'birthday', 'weight', 'gender', 'sizeCategory',
      'energyLevel', 'friendlinessDogs', 'friendlinessPeople', 'trainingLevel',
      'favoriteActivities', 'isVaccinated', 'isSpayedNeutered', 'specialNeeds', 'bio'
    ];

    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        // Convert camelCase to snake_case for database
        const dbField = field.replace(/([A-Z])/g, '_$1').toLowerCase();
        updates[dbField] = req.body[field];
      }
    });

    const dog = await Dog.update(req.params.id, req.user.id, updates);

    if (!dog) {
      return res.status(404).json({ error: 'Dog not found' });
    }

    res.json({
      message: 'Dog profile updated successfully',
      dog
    });

  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Update dog error:', error);
    res.status(500).json({ error: 'Failed to update dog profile' });
  }
});

// Delete dog profile
router.delete('/:id', async (req, res) => {
  try {
    await DogMembership.authorize(req.user.id, req.params.id, 'delete');
    const dog = await Dog.findById(req.params.id);

    if (!dog) {
      return res.status(404).json({ error: 'Dog not found' });
    }

    if (dog.profileImageUrl) {
      await deleteFromS3(dog.profileImageUrl);
    }

    if (dog.galleryImages && dog.galleryImages.length > 0) {
      for (const imageUrl of dog.galleryImages) {
        await deleteFromS3(imageUrl);
      }
    }

    await Dog.delete(req.params.id, req.user.id);

    res.json({ message: 'Dog profile deleted successfully' });

  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Delete dog error:', error);
    res.status(500).json({ error: 'Failed to delete dog profile' });
  }
});

// Upload profile image
router.post('/:id/profile-image', uploadSingle('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    await DogMembership.authorize(req.user.id, req.params.id, 'edit');
    const dog = await Dog.findById(req.params.id);
    if (!dog) {
      return res.status(404).json({ error: 'Dog not found' });
    }

    // Delete old profile image if exists
    if (dog.profileImageUrl) {
      await deleteFromS3(dog.profileImageUrl);
    }

    // Upload new image to S3
    const filename = generateFilename(req.file.originalname, 'profile-');
    const folder = `dogs/${req.params.id}`;
    const imageUrl = await uploadToS3(req.file, folder, filename);

    // Update dog with new profile image URL
    const updatedDog = await Dog.update(req.params.id, req.user.id, {
      profile_image_url: imageUrl
    });

    res.json({
      message: 'Profile image uploaded successfully',
      dog: updatedDog
    });

  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Upload profile image error:', error);
    res.status(500).json({ error: 'Failed to upload profile image' });
  }
});

// Upload gallery images
router.post('/:id/gallery', uploadMultiple('images', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No image files provided' });
    }

    await DogMembership.authorize(req.user.id, req.params.id, 'edit');
    const dog = await Dog.findById(req.params.id);
    if (!dog) {
      return res.status(404).json({ error: 'Dog not found' });
    }

    const uploadPromises = req.files.map(file => {
      const filename = generateFilename(file.originalname, 'gallery-');
      const folder = `dogs/${req.params.id}/gallery`;
      return uploadToS3(file, folder, filename);
    });

    const imageUrls = await Promise.all(uploadPromises);

    // Add new images to gallery
    let updatedDog = dog;
    for (const imageUrl of imageUrls) {
      updatedDog = await Dog.addGalleryImage(req.params.id, req.user.id, imageUrl);
    }

    res.json({
      message: 'Gallery images uploaded successfully',
      dog: updatedDog,
      uploadedImages: imageUrls
    });

  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Upload gallery images error:', error);
    res.status(500).json({ error: 'Failed to upload gallery images' });
  }
});

// Set profile image from gallery
router.put('/:id/profile-image-from-gallery', [
  body('imageUrl').isURL().withMessage('Valid image URL is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    await DogMembership.authorize(req.user.id, req.params.id, 'edit');
    const dog = await Dog.findById(req.params.id);
    if (!dog) {
      return res.status(404).json({ error: 'Dog not found' });
    }

    const { imageUrl } = req.body;

    // Verify the image URL is in the dog's gallery
    if (!dog.galleryImages || !dog.galleryImages.includes(imageUrl)) {
      return res.status(400).json({ error: 'Image URL not found in gallery' });
    }

    // Delete old profile image if exists and it's different from the new one
    if (dog.profileImageUrl && dog.profileImageUrl !== imageUrl) {
      await deleteFromS3(dog.profileImageUrl);
    }

    // Update dog with new profile image URL
    const updatedDog = await Dog.update(req.params.id, req.user.id, {
      profile_image_url: imageUrl
    });

    res.json({
      message: 'Profile image set from gallery successfully',
      dog: updatedDog
    });

  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Set profile image from gallery error:', error);
    res.status(500).json({ error: 'Failed to set profile image from gallery' });
  }
});

// Delete gallery image
router.delete('/:id/gallery', [
  body('imageUrl').isURL().withMessage('Valid image URL is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    await DogMembership.authorize(req.user.id, req.params.id, 'edit');
    const dog = await Dog.findById(req.params.id);
    if (!dog) {
      return res.status(404).json({ error: 'Dog not found' });
    }

    const { imageUrl } = req.body;

    // Remove image from S3
    await deleteFromS3(imageUrl);

    // Remove image from gallery
    const updatedDog = await Dog.removeGalleryImage(req.params.id, req.user.id, imageUrl);

    res.json({
      message: 'Gallery image deleted successfully',
      dog: updatedDog
    });

  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Delete gallery image error:', error);
    res.status(500).json({ error: 'Failed to delete gallery image' });
  }
});

// Membership management
router.get('/:id/members', async (req, res) => {
  try {
    await DogMembership.authorize(req.user.id, req.params.id, 'view');
    const data = await DogMembership.listMembers(req.params.id);
    res.json(data);
  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('List dog members error:', error);
    res.status(500).json({ error: 'Failed to fetch dog members' });
  }
});

router.post('/:id/members', [
  body('role').optional().isIn(['primary_owner', 'co_owner', 'viewer']),
  body('userId').optional().isInt({ min: 1 }),
  body('email').optional().isEmail().normalizeEmail()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    await DogMembership.authorize(req.user.id, req.params.id, 'manage');

    const role = req.body.role || 'co_owner';
    const userId = req.body.userId ? parseInt(req.body.userId, 10) : null;
    const email = req.body.email || null;

    if (!userId && !email) {
      return res.status(400).json({ error: 'Provide a userId or email to invite a member' });
    }

    const dog = await Dog.findById(req.params.id);
    if (!dog) {
      return res.status(404).json({ error: 'Dog not found' });
    }

    const inviterName = [req.user.first_name, req.user.last_name].filter(Boolean).join(' ').trim() || req.user.email;

    const invitation = await DogMembership.inviteMember({
      dogId: req.params.id,
      inviterId: req.user.id,
      role,
      targetUserId: userId,
      email,
      dogName: dog.name,
      inviterName
    });

    res.status(201).json({
      message: 'Invitation sent successfully',
      invitation
    });
  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Invite dog member error:', error);
    res.status(500).json({ error: 'Failed to invite dog member' });
  }
});

router.post('/:id/members/:invitationId/respond', [
  param('invitationId').isInt({ min: 1 }).withMessage('Valid invitation ID is required'),
  body('action').isIn(['accept', 'decline']).withMessage('Action must be accept or decline'),
  body('token').isString().trim().notEmpty().withMessage('Invitation token is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const result = await DogMembership.respondToInvitation({
      dogId: req.params.id,
      invitationId: parseInt(req.params.invitationId, 10),
      userId: req.user.id,
      token: req.body.token,
      action: req.body.action
    });

    res.json({
      message: req.body.action === 'accept' ? 'Invitation accepted' : 'Invitation declined',
      ...result
    });
  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Respond to invitation error:', error);
    res.status(500).json({ error: 'Failed to respond to invitation' });
  }
});

router.patch('/:id/members/:memberId', [
  param('memberId').isInt({ min: 1 }).withMessage('Valid member ID is required'),
  body('role').isIn(['primary_owner', 'co_owner', 'viewer']).withMessage('Invalid role')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const member = await DogMembership.updateRole({
      dogId: req.params.id,
      memberId: parseInt(req.params.memberId, 10),
      role: req.body.role,
      actingUserId: req.user.id
    });

    res.json({
      message: 'Member role updated successfully',
      member
    });
  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Update member role error:', error);
    res.status(500).json({ error: 'Failed to update member role' });
  }
});

router.delete('/:id/members/:memberId', [
  param('memberId').isInt({ min: 1 }).withMessage('Valid member ID is required')
], async (req, res) => {
  try {
    await DogMembership.removeMember({
      dogId: req.params.id,
      memberId: parseInt(req.params.memberId, 10),
      actingUserId: req.user.id
    });

    res.json({ message: 'Member removed successfully' });
  } catch (error) {
    if (handleMembershipError(res, error)) return;
    console.error('Remove dog member error:', error);
    res.status(500).json({ error: 'Failed to remove dog member' });
  }
});

module.exports = router;