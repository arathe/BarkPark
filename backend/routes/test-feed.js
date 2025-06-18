const express = require('express');
const router = express.Router();

// Debug endpoint to see raw feed response
router.get('/feed/debug', async (req, res) => {
  try {
    // Mock response to test structure
    const mockResponse = {
      posts: [
        {
          id: 1,
          user_id: 1,
          content: "Test post",
          post_type: "status",
          visibility: "friends",
          check_in_id: null,
          shared_post_id: null,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          first_name: "Test",
          last_name: "User",
          user_profile_image: null,
          like_count: 0,
          comment_count: 0,
          user_liked: false,
          media: null,
          check_in: null
        }
      ],
      pagination: {
        limit: 20,
        offset: 0,
        hasMore: false
      }
    };
    
    res.json(mockResponse);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get actual database response without auth
router.get('/feed/raw', async (req, res) => {
  try {
    const pool = require('../config/database');
    
    // First check if posts table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'posts'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      return res.json({ 
        error: "posts table does not exist",
        tables: await pool.query(`
          SELECT table_name 
          FROM information_schema.tables 
          WHERE table_schema = 'public'
          ORDER BY table_name;
        `).then(r => r.rows.map(row => row.table_name))
      });
    }
    
    // Get raw post data
    const result = await pool.query(`
      SELECT p.*, u.first_name, u.last_name
      FROM posts p
      JOIN users u ON u.id = p.user_id
      LIMIT 1
    `);
    
    res.json({
      rowCount: result.rowCount,
      firstRow: result.rows[0] || null,
      tableExists: true
    });
  } catch (error) {
    res.status(500).json({ 
      error: error.message,
      stack: error.stack 
    });
  }
});

module.exports = router;