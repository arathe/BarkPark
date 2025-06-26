const pool = require('../config/database');

class Friendship {
  // Send a friend request
  static async sendFriendRequest(requesterId, addresseeId) {
    if (requesterId === addresseeId) {
      throw new Error('Cannot send friend request to yourself');
    }

    // Check if friendship already exists (in either direction)
    const existingFriendship = await this.findExistingFriendship(requesterId, addresseeId);
    if (existingFriendship) {
      throw new Error('Friendship request already exists or users are already friends');
    }

    const query = `
      INSERT INTO friendships (user_id, friend_id, status)
      VALUES ($1, $2, 'pending')
      RETURNING id, user_id, friend_id, status, created_at
    `;
    
    const values = [requesterId, addresseeId];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  // Accept a friend request
  static async acceptFriendRequest(friendshipId, userId) {
    const query = `
      UPDATE friendships 
      SET status = 'accepted', updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND friend_id = $2 AND status = 'pending'
      RETURNING id, user_id, friend_id, status, updated_at
    `;
    
    const values = [friendshipId, userId];
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      throw new Error('Friend request not found or not authorized to accept');
    }
    
    return result.rows[0];
  }

  // Decline a friend request
  static async declineFriendRequest(friendshipId, userId) {
    const query = `
      UPDATE friendships 
      SET status = 'declined', updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND friend_id = $2 AND status = 'pending'
      RETURNING id, user_id, friend_id, status, updated_at
    `;
    
    const values = [friendshipId, userId];
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      throw new Error('Friend request not found or not authorized to decline');
    }
    
    return result.rows[0];
  }

  // Get all friends for a user (accepted friendships)
  static async getFriends(userId) {
    const query = `
      SELECT 
        f.id as friendship_id,
        f.status,
        f.created_at as friendship_created_at,
        CASE 
          WHEN f.user_id = $1 THEN u2.id
          ELSE u1.id
        END as friend_id,
        CASE 
          WHEN f.user_id = $1 THEN u2.email
          ELSE u1.email
        END as friend_email,
        CASE 
          WHEN f.user_id = $1 THEN u2.first_name
          ELSE u1.first_name
        END as friend_first_name,
        CASE 
          WHEN f.user_id = $1 THEN u2.last_name
          ELSE u1.last_name
        END as friend_last_name,
        CASE 
          WHEN f.user_id = $1 THEN u2.phone
          ELSE u1.phone
        END as friend_phone,
        CASE 
          WHEN f.user_id = $1 THEN u2.profile_image_url
          ELSE u1.profile_image_url
        END as friend_profile_image_url
      FROM friendships f
      JOIN users u1 ON f.user_id = u1.id
      JOIN users u2 ON f.friend_id = u2.id
      WHERE (f.user_id = $1 OR f.friend_id = $1)
        AND f.status = 'accepted'
      ORDER BY f.created_at DESC
    `;
    
    const result = await pool.query(query, [userId]);
    return result.rows.map(row => ({
      friendshipId: row.friendship_id,
      status: row.status,
      friendshipCreatedAt: row.friendship_created_at,
      friend: {
        id: row.friend_id,
        email: row.friend_email,
        firstName: row.friend_first_name,
        lastName: row.friend_last_name,
        phone: row.friend_phone,
        profileImageUrl: row.friend_profile_image_url
      }
    }));
  }

  // Get pending friend requests (both sent and received)
  static async getPendingRequests(userId) {
    const query = `
      SELECT 
        f.id as friendship_id,
        f.status,
        f.created_at,
        f.user_id,
        f.friend_id,
        CASE 
          WHEN f.user_id = $1 THEN 'sent'
          ELSE 'received'
        END as request_type,
        CASE 
          WHEN f.user_id = $1 THEN u2.id
          ELSE u1.id
        END as other_user_id,
        CASE 
          WHEN f.user_id = $1 THEN u2.email
          ELSE u1.email
        END as other_user_email,
        CASE 
          WHEN f.user_id = $1 THEN u2.first_name
          ELSE u1.first_name
        END as other_user_first_name,
        CASE 
          WHEN f.user_id = $1 THEN u2.last_name
          ELSE u1.last_name
        END as other_user_last_name,
        CASE 
          WHEN f.user_id = $1 THEN u2.phone
          ELSE u1.phone
        END as other_user_phone,
        CASE 
          WHEN f.user_id = $1 THEN u2.profile_image_url
          ELSE u1.profile_image_url
        END as other_user_profile_image_url
      FROM friendships f
      JOIN users u1 ON f.user_id = u1.id
      JOIN users u2 ON f.friend_id = u2.id
      WHERE (f.user_id = $1 OR f.friend_id = $1)
        AND f.status = 'pending'
      ORDER BY f.created_at DESC
    `;
    
    const result = await pool.query(query, [userId]);
    return result.rows.map(row => ({
      friendshipId: row.friendship_id,
      status: row.status,
      createdAt: row.created_at,
      requestType: row.request_type,
      otherUser: {
        id: row.other_user_id,
        email: row.other_user_email,
        firstName: row.other_user_first_name,
        lastName: row.other_user_last_name,
        phone: row.other_user_phone,
        profileImageUrl: row.other_user_profile_image_url
      }
    }));
  }

  // Remove a friendship (can be called by either user)
  static async removeFriend(userId, friendId) {
    const query = `
      DELETE FROM friendships 
      WHERE ((user_id = $1 AND friend_id = $2) 
             OR (user_id = $2 AND friend_id = $1))
        AND status = 'accepted'
      RETURNING id
    `;
    
    const values = [userId, friendId];
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      throw new Error('Friendship not found or not authorized to remove');
    }
    
    return { success: true, message: 'Friendship removed successfully' };
  }

  // Get friendship status between two users
  static async getFriendshipStatus(userId, otherUserId) {
    const query = `
      SELECT id, user_id, friend_id, status, created_at, updated_at
      FROM friendships
      WHERE (user_id = $1 AND friend_id = $2)
         OR (user_id = $2 AND friend_id = $1)
    `;
    
    const result = await pool.query(query, [userId, otherUserId]);
    return result.rows[0] || null;
  }

  // Helper method to check for existing friendship
  static async findExistingFriendship(userId1, userId2) {
    const query = `
      SELECT id, user_id, friend_id, status
      FROM friendships
      WHERE (user_id = $1 AND friend_id = $2)
         OR (user_id = $2 AND friend_id = $1)
    `;
    
    const result = await pool.query(query, [userId1, userId2]);
    return result.rows[0] || null;
  }

  // Cancel a sent friend request (only requester can cancel)
  static async cancelFriendRequest(friendshipId, userId) {
    const query = `
      DELETE FROM friendships 
      WHERE id = $1 AND user_id = $2 AND status = 'pending'
      RETURNING id
    `;
    
    const values = [friendshipId, userId];
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      throw new Error('Friend request not found or not authorized to cancel');
    }
    
    return { success: true, message: 'Friend request cancelled successfully' };
  }
}

module.exports = Friendship;