const express = require('express');
const router = express.Router();
const { param, query, validationResult } = require('express-validator');
const { requireAuth } = require('../middleware/auth');
const Notification = require('../models/Notification');

// Get notifications for authenticated user
router.get('/', requireAuth, [
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    const notifications = await Notification.getForUser(req.user.id, limit, offset);
    const unreadCount = await Notification.getUnreadCount(req.user.id);
    
    // Format notifications with human-readable text
    const formattedNotifications = notifications.map(notif => ({
      ...notif,
      text: Notification.formatNotificationText(notif)
    }));
    
    res.json({
      notifications: formattedNotifications,
      unreadCount,
      pagination: {
        limit,
        offset,
        hasMore: notifications.length === limit
      }
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// Get unread notification count
router.get('/unread-count', requireAuth, async (req, res) => {
  try {
    const unreadCount = await Notification.getUnreadCount(req.user.id);
    res.json({ unreadCount });
  } catch (error) {
    console.error('Error fetching unread count:', error);
    res.status(500).json({ error: 'Failed to fetch unread count' });
  }
});

// Mark notification as read
router.put('/:id/read', requireAuth, [
  param('id').isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const notificationId = parseInt(req.params.id);
    const success = await Notification.markAsRead(notificationId, req.user.id);
    
    if (!success) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    
    res.json({ message: 'Notification marked as read' });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: 'Failed to mark notification as read' });
  }
});

// Mark all notifications as read
router.put('/read-all', requireAuth, async (req, res) => {
  try {
    const updatedCount = await Notification.markAllAsRead(req.user.id);
    res.json({ 
      message: 'All notifications marked as read',
      updatedCount 
    });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ error: 'Failed to mark all notifications as read' });
  }
});

module.exports = router;