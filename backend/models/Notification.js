const pool = require('../config/database');

class Notification {
  static async create({ userId, type, actorId, postId = null, commentId = null }) {
    const data = {
      actorId,
      postId,
      commentId
    };
    
    const query = `
      INSERT INTO notifications (user_id, type, data)
      VALUES ($1, $2, $3)
      RETURNING *
    `;
    
    const values = [userId, type, JSON.stringify(data)];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async getForUser(userId, limit = 50, offset = 0) {
    const query = `
      SELECT 
        n.*,
        n.data->>'actorId' as actor_id,
        n.data->>'postId' as post_id,
        n.data->>'commentId' as comment_id,
        u.first_name as actor_first_name,
        u.last_name as actor_last_name,
        u.profile_image_url as actor_profile_image,
        p.content as post_content,
        p.post_type,
        (
          SELECT json_agg(
            json_build_object(
              'media_type', pm.media_type,
              'media_url', pm.media_url,
              'thumbnail_url', pm.thumbnail_url
            ) ORDER BY pm.order_index
          )
          FROM post_media pm
          WHERE pm.post_id = (n.data->>'postId')::int
          LIMIT 1
        ) as post_media,
        pc.content as comment_content
      FROM notifications n
      JOIN users u ON u.id = (n.data->>'actorId')::int
      LEFT JOIN posts p ON p.id = (n.data->>'postId')::int
      LEFT JOIN post_comments pc ON pc.id = (n.data->>'commentId')::int
      WHERE n.user_id = $1
      ORDER BY n.created_at DESC
      LIMIT $2 OFFSET $3
    `;
    
    const result = await pool.query(query, [userId, limit, offset]);
    return result.rows;
  }

  static async markAsRead(notificationId, userId) {
    const query = `
      UPDATE notifications
      SET read = true
      WHERE id = $1 AND user_id = $2
      RETURNING id
    `;
    
    const result = await pool.query(query, [notificationId, userId]);
    return result.rows.length > 0;
  }

  static async markAllAsRead(userId) {
    const query = `
      UPDATE notifications
      SET read = true
      WHERE user_id = $1 AND read = false
      RETURNING id
    `;
    
    const result = await pool.query(query, [userId]);
    return result.rows.length;
  }

  static async getUnreadCount(userId) {
    const query = `
      SELECT COUNT(*) as count
      FROM notifications
      WHERE user_id = $1 AND read = false
    `;
    
    const result = await pool.query(query, [userId]);
    return parseInt(result.rows[0].count);
  }

  static async deleteOldNotifications(daysToKeep = 30) {
    const query = `
      DELETE FROM notifications
      WHERE created_at < NOW() - INTERVAL '${daysToKeep} days'
      RETURNING COUNT(*) as deleted_count
    `;
    
    const result = await pool.query(query);
    return parseInt(result.rows[0].deleted_count);
  }

  static async createBulk(notifications) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      const results = [];
      for (const notif of notifications) {
        const result = await this.create(notif);
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

  static formatNotificationText(notification) {
    const { type, actor_first_name, actor_last_name } = notification;
    const actorName = `${actor_first_name} ${actor_last_name}`;
    
    switch (type) {
      case 'like':
        return `${actorName} liked your post`;
      case 'comment':
        return `${actorName} commented on your post`;
      case 'mention':
        return `${actorName} mentioned you in a post`;
      case 'friend_checkin':
        return `${actorName} checked in at a park`;
      case 'friend_post':
        return `${actorName} shared a new post`;
      default:
        return `${actorName} interacted with your content`;
    }
  }
}

module.exports = Notification;