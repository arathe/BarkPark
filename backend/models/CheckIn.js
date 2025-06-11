const pool = require('../config/database');

class CheckIn {
  static async create(checkInData) {
    const {
      userId,
      dogParkId,
      dogsPresent
    } = checkInData;

    const query = `
      INSERT INTO checkins (user_id, dog_park_id, dogs_present)
      VALUES ($1, $2, $3)
      RETURNING *
    `;

    const values = [userId, dogParkId, dogsPresent || []];
    const result = await pool.query(query, values);
    return this.formatCheckIn(result.rows[0]);
  }

  static async findActiveByUser(userId) {
    const query = `
      SELECT c.*, dp.name as park_name, dp.address as park_address
      FROM checkins c
      LEFT JOIN dog_parks dp ON c.dog_park_id = dp.id
      WHERE c.user_id = $1 AND c.checked_out_at IS NULL
      ORDER BY c.checked_in_at DESC
    `;
    const result = await pool.query(query, [userId]);
    return result.rows.map(checkIn => this.formatCheckIn(checkIn));
  }

  static async findActiveByPark(dogParkId) {
    const query = `
      SELECT c.*, u.first_name, u.last_name, u.profile_image_url
      FROM checkins c
      LEFT JOIN users u ON c.user_id = u.id
      WHERE c.dog_park_id = $1 AND c.checked_out_at IS NULL
      ORDER BY c.checked_in_at DESC
    `;
    const result = await pool.query(query, [dogParkId]);
    return result.rows.map(checkIn => this.formatCheckIn(checkIn));
  }

  static async findById(checkInId) {
    const query = 'SELECT * FROM checkins WHERE id = $1';
    const result = await pool.query(query, [checkInId]);
    return result.rows[0] ? this.formatCheckIn(result.rows[0]) : null;
  }

  static async findByUserAndPark(userId, dogParkId) {
    const query = `
      SELECT * FROM checkins 
      WHERE user_id = $1 AND dog_park_id = $2 AND checked_out_at IS NULL
      ORDER BY checked_in_at DESC
      LIMIT 1
    `;
    const result = await pool.query(query, [userId, dogParkId]);
    return result.rows[0] ? this.formatCheckIn(result.rows[0]) : null;
  }

  static async checkOut(checkInId, userId) {
    const query = `
      UPDATE checkins 
      SET checked_out_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND user_id = $2 AND checked_out_at IS NULL
      RETURNING *
    `;
    const result = await pool.query(query, [checkInId, userId]);
    return result.rows[0] ? this.formatCheckIn(result.rows[0]) : null;
  }

  static async checkOutByPark(userId, dogParkId) {
    const query = `
      UPDATE checkins 
      SET checked_out_at = CURRENT_TIMESTAMP
      WHERE user_id = $1 AND dog_park_id = $2 AND checked_out_at IS NULL
      RETURNING *
    `;
    const result = await pool.query(query, [userId, dogParkId]);
    return result.rows[0] ? this.formatCheckIn(result.rows[0]) : null;
  }

  static async getRecentHistory(userId, limit = 10) {
    const query = `
      SELECT c.*, dp.name as park_name, dp.address as park_address
      FROM checkins c
      LEFT JOIN dog_parks dp ON c.dog_park_id = dp.id
      WHERE c.user_id = $1
      ORDER BY c.checked_in_at DESC
      LIMIT $2
    `;
    const result = await pool.query(query, [userId, limit]);
    return result.rows.map(checkIn => this.formatCheckIn(checkIn));
  }

  static async getParkActivityStats(dogParkId, hoursBack = 24) {
    const query = `
      SELECT 
        COUNT(*) as total_checkins,
        COUNT(CASE WHEN checked_out_at IS NULL THEN 1 END) as current_checkins,
        AVG(EXTRACT(EPOCH FROM (COALESCE(checked_out_at, CURRENT_TIMESTAMP) - checked_in_at))/60) as avg_visit_minutes
      FROM checkins 
      WHERE dog_park_id = $1 
        AND checked_in_at >= CURRENT_TIMESTAMP - INTERVAL '${hoursBack} hours'
    `;
    const result = await pool.query(query, [dogParkId]);
    const stats = result.rows[0];
    
    return {
      totalCheckIns: parseInt(stats.total_checkins) || 0,
      currentCheckIns: parseInt(stats.current_checkins) || 0,
      averageVisitMinutes: parseFloat(stats.avg_visit_minutes) || 0
    };
  }

  // Get friends currently at a specific park (requires friendship data)
  static async getFriendsAtPark(userId, dogParkId) {
    const query = `
      SELECT c.*, u.first_name, u.last_name, u.profile_image_url
      FROM checkins c
      LEFT JOIN users u ON c.user_id = u.id
      LEFT JOIN friendships f1 ON (f1.requester_id = $1 AND f1.addressee_id = c.user_id AND f1.status = 'accepted')
      LEFT JOIN friendships f2 ON (f2.addressee_id = $1 AND f2.requester_id = c.user_id AND f2.status = 'accepted')
      WHERE c.dog_park_id = $2 
        AND c.checked_out_at IS NULL
        AND c.user_id != $1
        AND (f1.id IS NOT NULL OR f2.id IS NOT NULL)
      ORDER BY c.checked_in_at DESC
    `;
    const result = await pool.query(query, [userId, dogParkId]);
    return result.rows.map(checkIn => this.formatCheckIn(checkIn));
  }

  // Helper method to format check-in data for API responses
  static formatCheckIn(checkIn) {
    if (!checkIn) return null;

    return {
      id: checkIn.id,
      userId: checkIn.user_id,
      dogParkId: checkIn.dog_park_id,
      dogsPresent: checkIn.dogs_present || [],
      checkedInAt: checkIn.checked_in_at,
      checkedOutAt: checkIn.checked_out_at,
      parkName: checkIn.park_name,
      parkAddress: checkIn.park_address,
      user: checkIn.first_name ? {
        firstName: checkIn.first_name,
        lastName: checkIn.last_name,
        profileImageUrl: checkIn.profile_image_url
      } : undefined
    };
  }
}

module.exports = CheckIn;