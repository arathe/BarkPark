const express = require('express');
const router = express.Router();
const { body, param, query, validationResult } = require('express-validator');
const { requireAuth } = require('../middleware/auth');
const Post = require('../models/Post');
const PostLike = require('../models/PostLike');
const PostComment = require('../models/PostComment');
const Notification = require('../models/Notification');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
    files: 10 // Max 10 files per upload
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|mp4|mov|avi|webm/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only images and videos are allowed'));
    }
  }
});

// Create a new post
router.post('/', requireAuth, [
  body('content').optional().isString().trim(),
  body('postType').optional().isIn(['status', 'checkin', 'media', 'shared']),
  body('visibility').optional().isIn(['public', 'friends', 'private']),
  body('checkInId').optional().isInt(),
  body('sharedPostId').optional().isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { content, postType, visibility, checkInId, sharedPostId } = req.body;
    
    // Validate that post has content or is a check-in/share
    if (!content && !checkInId && !sharedPostId) {
      return res.status(400).json({ error: 'Post must have content, be a check-in, or be a share' });
    }

    const post = await Post.create({
      userId: req.user.id,
      content,
      postType,
      visibility,
      checkInId,
      sharedPostId
    });

    // Get the full post with user info
    const fullPost = await Post.findById(post.id);
    
    res.status(201).json(fullPost);
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({ error: 'Failed to create post' });
  }
});

// Get feed for authenticated user
router.get('/feed', requireAuth, [
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;

    const posts = await Post.getFeedForUser(req.user.id, limit, offset);
    
    res.json({
      posts,
      pagination: {
        limit,
        offset,
        hasMore: posts.length === limit
      }
    });
  } catch (error) {
    console.error('Error fetching feed:', error);
    res.status(500).json({ error: 'Failed to fetch feed' });
  }
});

// Get single post
router.get('/:id', requireAuth, [
  param('id').isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const post = await Post.findById(req.params.id);
    
    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    // Check if user can view this post
    const canView = await Post.canViewUserPosts(post.user_id, req.user.id);
    if (!canView && post.visibility === 'friends') {
      return res.status(403).json({ error: 'You do not have permission to view this post' });
    }

    res.json(post);
  } catch (error) {
    console.error('Error fetching post:', error);
    res.status(500).json({ error: 'Failed to fetch post' });
  }
});

// Get posts by user
router.get('/user/:userId', requireAuth, [
  param('userId').isInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;
    const userId = parseInt(req.params.userId);

    const posts = await Post.getUserPosts(userId, req.user.id, limit, offset);
    
    res.json({
      posts,
      pagination: {
        limit,
        offset,
        hasMore: posts.length === limit
      }
    });
  } catch (error) {
    console.error('Error fetching user posts:', error);
    res.status(500).json({ error: 'Failed to fetch user posts' });
  }
});

// Delete post
router.delete('/:id', requireAuth, [
  param('id').isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const deleted = await Post.delete(req.params.id, req.user.id);
    
    if (!deleted) {
      return res.status(404).json({ error: 'Post not found or you do not have permission to delete it' });
    }

    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(500).json({ error: 'Failed to delete post' });
  }
});

// Upload media for a post
router.post('/:id/media', requireAuth, upload.array('media', 10), [
  param('id').isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const postId = parseInt(req.params.id);
    
    // Verify post ownership
    const post = await Post.findById(postId);
    if (!post || post.user_id !== req.user.id) {
      return res.status(403).json({ error: 'You can only add media to your own posts' });
    }

    // TODO: Upload files to cloud storage (S3/Cloudinary)
    // For now, we'll return a placeholder response
    const mediaData = req.files.map((file, index) => ({
      mediaType: file.mimetype.startsWith('video/') ? 'video' : 'photo',
      mediaUrl: `https://placeholder.com/${file.originalname}`,
      thumbnailUrl: file.mimetype.startsWith('video/') ? `https://placeholder.com/thumb_${file.originalname}` : null,
      width: 1080,
      height: 1080,
      duration: file.mimetype.startsWith('video/') ? 30 : null,
      orderIndex: index
    }));

    const media = await Post.addMultipleMedia(postId, mediaData);
    
    res.json({ media });
  } catch (error) {
    console.error('Error uploading media:', error);
    res.status(500).json({ error: 'Failed to upload media' });
  }
});

// Like/unlike a post
router.post('/:id/like', requireAuth, [
  param('id').isInt(),
  body('reactionType').optional().isIn(['like', 'love', 'laugh', 'wow'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const postId = parseInt(req.params.id);
    const reactionType = req.body.reactionType || 'like';
    
    const result = await PostLike.toggle(postId, req.user.id, reactionType);
    const likeCount = await PostLike.getLikeCount(postId);
    
    res.json({
      action: result.action,
      likeCount: likeCount.count,
      reactionCounts: likeCount
    });
  } catch (error) {
    console.error('Error toggling like:', error);
    res.status(500).json({ error: 'Failed to update like status' });
  }
});

// Get likes for a post
router.get('/:id/likes', requireAuth, [
  param('id').isInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const postId = parseInt(req.params.id);
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;
    
    const likes = await PostLike.getLikesForPost(postId, limit, offset);
    const likeCount = await PostLike.getLikeCount(postId);
    
    res.json({
      likes,
      total: likeCount.count,
      reactionCounts: likeCount
    });
  } catch (error) {
    console.error('Error fetching likes:', error);
    res.status(500).json({ error: 'Failed to fetch likes' });
  }
});

// Add comment to a post
router.post('/:id/comment', requireAuth, [
  param('id').isInt(),
  body('content').isString().trim().isLength({ min: 1, max: 1000 }),
  body('parentCommentId').optional().isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const postId = parseInt(req.params.id);
    const { content, parentCommentId } = req.body;
    
    const comment = await PostComment.create({
      postId,
      userId: req.user.id,
      content,
      parentCommentId
    });
    
    res.status(201).json(comment);
  } catch (error) {
    console.error('Error creating comment:', error);
    res.status(500).json({ error: 'Failed to create comment' });
  }
});

// Get comments for a post
router.get('/:id/comments', requireAuth, [
  param('id').isInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const postId = parseInt(req.params.id);
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;
    
    const comments = await PostComment.getCommentsForPost(postId, limit, offset);
    const commentCount = await PostComment.getCommentCount(postId);
    
    res.json({
      comments,
      total: commentCount
    });
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({ error: 'Failed to fetch comments' });
  }
});

// Update comment
router.put('/comments/:id', requireAuth, [
  param('id').isInt(),
  body('content').isString().trim().isLength({ min: 1, max: 1000 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const commentId = parseInt(req.params.id);
    const { content } = req.body;
    
    const comment = await PostComment.update(commentId, req.user.id, content);
    
    if (!comment) {
      return res.status(404).json({ error: 'Comment not found or you do not have permission to edit it' });
    }
    
    res.json(comment);
  } catch (error) {
    console.error('Error updating comment:', error);
    res.status(500).json({ error: 'Failed to update comment' });
  }
});

// Delete comment
router.delete('/comments/:id', requireAuth, [
  param('id').isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const commentId = parseInt(req.params.id);
    const deleted = await PostComment.delete(commentId, req.user.id);
    
    if (!deleted) {
      return res.status(404).json({ error: 'Comment not found or you do not have permission to delete it' });
    }
    
    res.json({ message: 'Comment deleted successfully' });
  } catch (error) {
    console.error('Error deleting comment:', error);
    res.status(500).json({ error: 'Failed to delete comment' });
  }
});

module.exports = router;