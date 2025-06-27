const pool = require('../config/database');

class PostComment {
  static async create({ postId, userId, content, parentCommentId = null }) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // Check if post exists
      const postCheck = await client.query('SELECT id FROM posts WHERE id = $1', [postId]);
      if (postCheck.rows.length === 0) {
        throw new Error('Post not found');
      }
      
      const insertQuery = `
        INSERT INTO post_comments (post_id, user_id, content, parent_comment_id)
        VALUES ($1, $2, $3, $4)
        RETURNING *
      `;
      
      const values = [postId, userId, content, parentCommentId];
      const result = await client.query(insertQuery, values);
      const comment = result.rows[0];
      
      // Create notification for post owner
      const postQuery = 'SELECT user_id FROM posts WHERE id = $1';
      const postResult = await client.query(postQuery, [postId]);
      
      if (postResult.rows[0] && postResult.rows[0].user_id !== userId) {
        const data = {
          actorId: userId,
          postId: postId,
          commentId: comment.id
        };
        const notifQuery = `
          INSERT INTO notifications (user_id, type, data)
          VALUES ($1, 'comment', $2)
        `;
        await client.query(notifQuery, [postResult.rows[0].user_id, JSON.stringify(data)]);
      }
      
      // If replying to a comment, notify the parent comment author
      if (parentCommentId) {
        const parentQuery = 'SELECT user_id FROM post_comments WHERE id = $1';
        const parentResult = await client.query(parentQuery, [parentCommentId]);
        
        if (parentResult.rows[0] && parentResult.rows[0].user_id !== userId) {
          const data = {
            actorId: userId,
            postId: postId,
            commentId: comment.id
          };
          const replyNotifQuery = `
            INSERT INTO notifications (user_id, type, data)
            VALUES ($1, 'comment', $2)
          `;
          await client.query(replyNotifQuery, [parentResult.rows[0].user_id, JSON.stringify(data)]);
        }
      }
      
      await client.query('COMMIT');
      return comment;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async getCommentsForPost(postId, limit = 50, offset = 0) {
    const query = `
      WITH RECURSIVE comment_tree AS (
        -- Base case: top-level comments
        SELECT 
          pc.*,
          u.first_name,
          u.last_name,
          u.profile_image_url,
          0 as depth,
          ARRAY[pc.id] as path
        FROM post_comments pc
        JOIN users u ON u.id = pc.user_id
        WHERE pc.post_id = $1 AND pc.parent_comment_id IS NULL
        
        UNION ALL
        
        -- Recursive case: replies
        SELECT 
          pc.*,
          u.first_name,
          u.last_name,
          u.profile_image_url,
          ct.depth + 1,
          ct.path || pc.id
        FROM post_comments pc
        JOIN users u ON u.id = pc.user_id
        JOIN comment_tree ct ON pc.parent_comment_id = ct.id
        WHERE ct.depth < 3  -- Limit nesting depth
      )
      SELECT 
        id,
        post_id,
        user_id,
        parent_comment_id,
        content,
        created_at,
        updated_at,
        first_name,
        last_name,
        profile_image_url,
        depth,
        path
      FROM comment_tree
      ORDER BY path, created_at
      LIMIT $2 OFFSET $3
    `;
    
    const result = await pool.query(query, [postId, limit, offset]);
    
    // Transform flat list into nested structure
    const comments = [];
    const commentMap = {};
    
    result.rows.forEach(row => {
      const comment = {
        id: row.id,
        post_id: row.post_id,
        user_id: row.user_id,
        content: row.content,
        created_at: row.created_at,
        updated_at: row.updated_at,
        user: {
          id: row.user_id,
          first_name: row.first_name,
          last_name: row.last_name,
          profile_image_url: row.profile_image_url
        },
        replies: []
      };
      
      commentMap[comment.id] = comment;
      
      if (!row.parent_comment_id) {
        comments.push(comment);
      } else if (commentMap[row.parent_comment_id]) {
        commentMap[row.parent_comment_id].replies.push(comment);
      }
    });
    
    return comments;
  }

  static async getCommentCount(postId) {
    const query = `
      SELECT COUNT(*) as count
      FROM post_comments
      WHERE post_id = $1
    `;
    
    const result = await pool.query(query, [postId]);
    return parseInt(result.rows[0].count);
  }

  static async delete(commentId, userId) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // First check if the comment exists and belongs to the user
      const checkQuery = `
        SELECT id, user_id, post_id
        FROM post_comments
        WHERE id = $1
      `;
      const checkResult = await client.query(checkQuery, [commentId]);
      
      if (checkResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return false;
      }
      
      if (checkResult.rows[0].user_id !== userId) {
        await client.query('ROLLBACK');
        return false;
      }
      
      // Delete all child comments recursively using CTE
      const deleteQuery = `
        WITH RECURSIVE comment_tree AS (
          -- Base case: the comment to delete
          SELECT id FROM post_comments WHERE id = $1
          
          UNION ALL
          
          -- Recursive case: all child comments
          SELECT pc.id 
          FROM post_comments pc
          JOIN comment_tree ct ON pc.parent_comment_id = ct.id
        )
        DELETE FROM post_comments
        WHERE id IN (SELECT id FROM comment_tree)
        RETURNING id
      `;
      
      const result = await client.query(deleteQuery, [commentId]);
      
      await client.query('COMMIT');
      return result.rows.length > 0;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = PostComment;