const pool = require('../config/database');
const bcrypt = require('bcrypt');

class User {
  static async create({ email, password, firstName, lastName, phone }) {
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const query = `
      INSERT INTO users (email, password_hash, first_name, last_name, phone)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, email, first_name, last_name, phone, profile_image_url, is_searchable, created_at
    `;
    
    const values = [email, hashedPassword, firstName, lastName, phone];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async findByEmail(email) {
    const query = 'SELECT * FROM users WHERE email = $1';
    const result = await pool.query(query, [email]);
    return result.rows[0];
  }

  static async findById(id) {
    const query = `
      SELECT id, email, first_name, last_name, phone, profile_image_url, is_searchable, created_at
      FROM users WHERE id = $1
    `;
    const result = await pool.query(query, [id]);
    return result.rows[0];
  }

  static async validatePassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  static async updateProfile(id, updates) {
    const allowedFields = ['first_name', 'last_name', 'phone', 'profile_image_url', 'is_searchable'];
    const fields = [];
    const values = [];
    let paramCount = 1;

    Object.keys(updates).forEach(key => {
      if (allowedFields.includes(key) && updates[key] !== undefined) {
        fields.push(`${key} = $${paramCount}`);
        values.push(updates[key]);
        paramCount++;
      }
    });

    if (fields.length === 0) {
      throw new Error('No valid fields to update');
    }

    fields.push('updated_at = CURRENT_TIMESTAMP');
    values.push(id);

    const query = `
      UPDATE users 
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, email, first_name, last_name, phone, profile_image_url, is_searchable, updated_at
    `;

    const result = await pool.query(query, values);
    return result.rows[0];
  }
}

module.exports = User;