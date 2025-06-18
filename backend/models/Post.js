const pool = require('../config/database');

class Post {
  static async create({ userId, content, postType = 'status', visibility = 'friends', checkInId = null, sharedPostId = null }) {
    const query = `
      INSERT INTO posts (user_id, content, post_type, visibility, check_in_id, shared_post_id)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;
    
    const values = [userId, content, postType, visibility, checkInId, sharedPostId];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async findById(id) {
    const query = `
      SELECT p.*, 
             u.first_name, u.last_name, u.profile_image_url as user_profile_image,
             COUNT(DISTINCT pl.id)::int as like_count,
             COUNT(DISTINCT pc.id)::int as comment_count,
             (
               SELECT json_agg(
                 json_build_object(
                   'id', pm.id,
                   'media_type', pm.media_type,
                   'media_url', pm.media_url,
                   'thumbnail_url', pm.thumbnail_url,
                   'width', pm.width,
                   'height', pm.height,
                   'duration', pm.duration,
                   'order_index', pm.order_index
                 ) ORDER BY pm.order_index
               ) 
               FROM post_media pm 
               WHERE pm.post_id = p.id
             ) as media,
             (
               SELECT json_build_object(
                 'id', ci.id,
                 'park_id', ci.dog_park_id,
                 'park_name', dp.name,
                 'checked_in_at', ci.checked_in_at
               )
               FROM checkins ci
               JOIN dog_parks dp ON dp.id = ci.dog_park_id
               WHERE ci.id = p.check_in_id
             ) as check_in
      FROM posts p
      JOIN users u ON u.id = p.user_id
      LEFT JOIN post_likes pl ON pl.post_id = p.id
      LEFT JOIN post_comments pc ON pc.post_id = p.id
      WHERE p.id = $1
      GROUP BY p.id, u.first_name, u.last_name, u.profile_image_url
    `;
    
    const result = await pool.query(query, [id]);
    return result.rows[0];
  }

  static async getFeedForUser(userId, limit = 20, offset = 0) {
    const query = `
      SELECT p.*, 
             u.first_name, u.last_name, u.profile_image_url as user_profile_image,
             COUNT(DISTINCT pl.id)::int as like_count,
             COUNT(DISTINCT pc.id)::int as comment_count,
             EXISTS(
               SELECT 1 FROM post_likes 
               WHERE post_id = p.id AND user_id = $1
             ) as user_liked,
             (
               SELECT json_agg(
                 json_build_object(
                   'id', pm.id,
                   'media_type', pm.media_type,
                   'media_url', pm.media_url,
                   'thumbnail_url', pm.thumbnail_url,
                   'width', pm.width,
                   'height', pm.height,
                   'duration', pm.duration,
                   'order_index', pm.order_index
                 ) ORDER BY pm.order_index
               ) 
               FROM post_media pm 
               WHERE pm.post_id = p.id
             ) as media,
             (
               SELECT json_build_object(
                 'id', ci.id,
                 'park_id', ci.dog_park_id,
                 'park_name', dp.name,
                 'checked_in_at', ci.checked_in_at
               )
               FROM checkins ci
               JOIN dog_parks dp ON dp.id = ci.dog_park_id
               WHERE ci.id = p.check_in_id
             ) as check_in
      FROM posts p
      JOIN users u ON u.id = p.user_id
      LEFT JOIN post_likes pl ON pl.post_id = p.id
      LEFT JOIN post_comments pc ON pc.post_id = p.id
      WHERE (
        p.user_id = $1 OR
        p.user_id IN (
          SELECT CASE 
            WHEN requester_id = $1 THEN addressee_id
            ELSE requester_id
          END
          FROM friendships
          WHERE (requester_id = $1 OR addressee_id = $1)
          AND status = 'accepted'
        )
      )
      AND (p.visibility = 'friends' OR p.visibility = 'public' OR p.user_id = $1)
      GROUP BY p.id, u.first_name, u.last_name, u.profile_image_url
      ORDER BY p.created_at DESC
      LIMIT $2 OFFSET $3
    `;
    
    const values = [userId, limit, offset];
    const result = await pool.query(query, values);
    return result.rows;
  }

  static async getUserPosts(userId, viewerId, limit = 20, offset = 0) {
    // Check if viewer can see posts
    const canView = await this.canViewUserPosts(userId, viewerId);
    if (!canView) {
      return [];
    }

    const query = `
      SELECT p.*, 
             u.first_name, u.last_name, u.profile_image_url as user_profile_image,
             COUNT(DISTINCT pl.id)::int as like_count,
             COUNT(DISTINCT pc.id)::int as comment_count,
             EXISTS(
               SELECT 1 FROM post_likes 
               WHERE post_id = p.id AND user_id = $2
             ) as user_liked,
             (
               SELECT json_agg(
                 json_build_object(
                   'id', pm.id,
                   'media_type', pm.media_type,
                   'media_url', pm.media_url,
                   'thumbnail_url', pm.thumbnail_url,
                   'width', pm.width,
                   'height', pm.height,
                   'duration', pm.duration,
                   'order_index', pm.order_index
                 ) ORDER BY pm.order_index
               ) 
               FROM post_media pm 
               WHERE pm.post_id = p.id
             ) as media
      FROM posts p
      JOIN users u ON u.id = p.user_id
      LEFT JOIN post_likes pl ON pl.post_id = p.id
      LEFT JOIN post_comments pc ON pc.post_id = p.id
      WHERE p.user_id = $1
      AND (p.visibility = 'public' OR $1 = $2 OR (
        p.visibility = 'friends' AND EXISTS (
          SELECT 1 FROM friendships
          WHERE ((requester_id = $1 AND addressee_id = $2) OR 
                 (requester_id = $2 AND addressee_id = $1))
          AND status = 'accepted'
        )
      ))
      GROUP BY p.id, u.first_name, u.last_name, u.profile_image_url
      ORDER BY p.created_at DESC
      LIMIT $3 OFFSET $4
    `;
    
    const values = [userId, viewerId, limit, offset];
    const result = await pool.query(query, values);
    return result.rows;
  }

  static async canViewUserPosts(userId, viewerId) {
    if (userId === viewerId) return true;
    
    const query = `
      SELECT 1 FROM friendships
      WHERE ((requester_id = $1 AND addressee_id = $2) OR 
             (requester_id = $2 AND addressee_id = $1))
      AND status = 'accepted'
    `;
    
    const result = await pool.query(query, [userId, viewerId]);
    return result.rows.length > 0;
  }

  static async delete(postId, userId) {
    const query = `
      DELETE FROM posts 
      WHERE id = $1 AND user_id = $2
      RETURNING id
    `;
    
    const result = await pool.query(query, [postId, userId]);
    return result.rows.length > 0;
  }

  static async addMedia(postId, mediaData) {
    const { mediaType, mediaUrl, thumbnailUrl, width, height, duration, orderIndex = 0 } = mediaData;
    
    const query = `
      INSERT INTO post_media (post_id, media_type, media_url, thumbnail_url, width, height, duration, order_index)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `;
    
    const values = [postId, mediaType, mediaUrl, thumbnailUrl, width, height, duration, orderIndex];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async addMultipleMedia(postId, mediaArray) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      const results = [];
      for (let i = 0; i < mediaArray.length; i++) {
        const media = { ...mediaArray[i], orderIndex: i };
        const result = await this.addMedia(postId, media);
        results.push(result);
      }
      
      await client.query('COMMIT');
      return results;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = Post;