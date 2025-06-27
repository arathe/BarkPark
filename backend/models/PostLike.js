const pool = require('../config/database');

class PostLike {
  static async toggle(postId, userId, reactionType = 'like') {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // First check if post exists
      const postCheck = await client.query('SELECT id FROM posts WHERE id = $1', [postId]);
      if (postCheck.rows.length === 0) {
        throw new Error('Post not found');
      }
      
      // Check if like exists
      const checkQuery = `
        SELECT id FROM post_likes 
        WHERE post_id = $1 AND user_id = $2
      `;
      const existing = await client.query(checkQuery, [postId, userId]);
      
      let result;
      let action;
      
      if (existing.rows.length > 0) {
        // Unlike - remove the existing like
        const deleteQuery = `
          DELETE FROM post_likes 
          WHERE post_id = $1 AND user_id = $2
          RETURNING id
        `;
        result = await client.query(deleteQuery, [postId, userId]);
        action = 'unliked';
      } else {
        // Like - add new like
        const insertQuery = `
          INSERT INTO post_likes (post_id, user_id, reaction_type)
          VALUES ($1, $2, $3)
          RETURNING *
        `;
        result = await client.query(insertQuery, [postId, userId, reactionType]);
        action = 'liked';
        
        // Create notification for post owner
        const postQuery = 'SELECT user_id FROM posts WHERE id = $1';
        const postResult = await client.query(postQuery, [postId]);
        
        if (postResult.rows[0] && postResult.rows[0].user_id !== userId) {
          const data = {
            actorId: userId,
            postId: postId
          };
          const notifQuery = `
            INSERT INTO notifications (user_id, type, data)
            VALUES ($1, 'like', $2)
          `;
          await client.query(notifQuery, [postResult.rows[0].user_id, JSON.stringify(data)]);
        }
      }
      
      await client.query('COMMIT');
      return { action, data: result.rows[0] };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async getLikesForPost(postId, limit = 50, offset = 0) {
    const query = `
      SELECT pl.*, 
             u.id as user_id, 
             u.first_name, 
             u.last_name, 
             u.profile_image_url
      FROM post_likes pl
      JOIN users u ON u.id = pl.user_id
      WHERE pl.post_id = $1
      ORDER BY pl.created_at DESC
      LIMIT $2 OFFSET $3
    `;
    
    const result = await pool.query(query, [postId, limit, offset]);
    return result.rows;
  }

  static async getLikeCount(postId) {
    const query = `
      SELECT COUNT(*) as count,
             COUNT(CASE WHEN reaction_type = 'like' THEN 1 END) as likes,
             COUNT(CASE WHEN reaction_type = 'love' THEN 1 END) as loves,
             COUNT(CASE WHEN reaction_type = 'laugh' THEN 1 END) as laughs,
             COUNT(CASE WHEN reaction_type = 'wow' THEN 1 END) as wows
      FROM post_likes
      WHERE post_id = $1
    `;
    
    const result = await pool.query(query, [postId]);
    return result.rows[0];
  }

  static async hasUserLiked(postId, userId) {
    const query = `
      SELECT reaction_type 
      FROM post_likes 
      WHERE post_id = $1 AND user_id = $2
    `;
    
    const result = await pool.query(query, [postId, userId]);
    return result.rows.length > 0 ? result.rows[0].reaction_type : null;
  }
}

module.exports = PostLike;