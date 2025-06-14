const pool = require('../config/database');

class DogPark {
  static async findAll() {
    const query = `
      SELECT 
        id, name, description, address,
        ST_X(location) as longitude, ST_Y(location) as latitude,
        amenities, rules, hours_open, hours_close,
        website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
        created_at, updated_at
      FROM dog_parks 
      ORDER BY name
    `;
    const result = await pool.query(query);
    return result.rows.map(park => this.formatPark(park));
  }

  static async findById(parkId) {
    const query = `
      SELECT 
        id, name, description, address,
        ST_X(location) as longitude, ST_Y(location) as latitude,
        amenities, rules, hours_open, hours_close,
        website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
        created_at, updated_at
      FROM dog_parks 
      WHERE id = $1
    `;
    const result = await pool.query(query, [parkId]);
    return result.rows[0] ? this.formatPark(result.rows[0]) : null;
  }

  static async findNearby(latitude, longitude, radiusKm = 10) {
    // Using PostGIS for distance calculation
    const query = `
      SELECT 
        id, name, description, address,
        ST_X(location) as longitude, ST_Y(location) as latitude,
        amenities, rules, hours_open, hours_close,
        website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
        ST_DistanceSphere(
          location,
          ST_SetSRID(ST_MakePoint($2, $1), 4326)
        ) / 1000.0 as distance_km,
        created_at, updated_at
      FROM dog_parks 
      WHERE ST_DistanceSphere(
        location,
        ST_SetSRID(ST_MakePoint($2, $1), 4326)
      ) / 1000.0 <= $3
      ORDER BY distance_km
    `;
    const result = await pool.query(query, [latitude, longitude, radiusKm]);
    return result.rows.map(park => this.formatPark(park));
  }

  static async create(parkData) {
    const {
      name,
      description,
      address,
      latitude,
      longitude,
      amenities,
      rules,
      hoursOpen,
      hoursClose
    } = parkData;

    const query = `
      INSERT INTO dog_parks (
        name, description, address, latitude, longitude, amenities, rules, hours_open, hours_close
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, name, description, address, latitude, longitude,
                amenities, rules, hours_open, hours_close,
                created_at, updated_at
    `;

    const values = [
      name, description, address, latitude, longitude,
      amenities || null, rules, hoursOpen, hoursClose
    ];

    const result = await pool.query(query, values);
    return this.formatPark(result.rows[0]);
  }

  static async update(parkId, updates) {
    const allowedFields = [
      'name', 'description', 'address', 'latitude', 'longitude', 
      'amenities', 'rules', 'hours_open', 'hours_close'
    ];

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
    values.push(parkId);

    const query = `
      UPDATE dog_parks 
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, name, description, address, latitude, longitude,
                amenities, rules, hours_open, hours_close,
                created_at, updated_at
    `;

    const result = await pool.query(query, values);
    return result.rows[0] ? this.formatPark(result.rows[0]) : null;
  }

  static async delete(parkId) {
    const query = 'DELETE FROM dog_parks WHERE id = $1 RETURNING *';
    const result = await pool.query(query, [parkId]);
    return result.rows[0] ? this.formatPark(result.rows[0]) : null;
  }

  static async search(searchQuery) {
    const query = `
      SELECT 
        id, name, description, address,
        ST_X(location) as longitude, ST_Y(location) as latitude,
        amenities, rules, hours_open, hours_close,
        created_at, updated_at, website, phone, rating, 
        review_count, surface_type, has_seating, zipcode, borough
      FROM dog_parks 
      WHERE 
        name ILIKE $1 OR 
        description ILIKE $1 OR 
        address ILIKE $1 OR
        borough ILIKE $1
      ORDER BY 
        CASE 
          WHEN name ILIKE $1 THEN 1
          WHEN description ILIKE $1 THEN 2
          WHEN address ILIKE $1 THEN 3
          ELSE 4
        END,
        name
      LIMIT 50
    `;
    const searchTerm = `%${searchQuery}%`;
    const result = await pool.query(query, [searchTerm]);
    return result.rows.map(park => this.formatPark(park));
  }

  static async searchWithLocation(searchQuery, latitude, longitude) {
    const query = `
      SELECT 
        id, name, description, address,
        ST_X(location) as longitude, ST_Y(location) as latitude,
        amenities, rules, hours_open, hours_close,
        ST_DistanceSphere(
          location,
          ST_SetSRID(ST_MakePoint($3, $2), 4326)
        ) / 1000.0 as distance_km,
        created_at, updated_at, website, phone, rating, 
        review_count, surface_type, has_seating, zipcode, borough
      FROM dog_parks 
      WHERE 
        name ILIKE $1 OR 
        description ILIKE $1 OR 
        address ILIKE $1 OR
        borough ILIKE $1
      ORDER BY 
        CASE 
          WHEN name ILIKE $1 THEN 1
          WHEN description ILIKE $1 THEN 2
          WHEN address ILIKE $1 THEN 3
          ELSE 4
        END,
        distance_km
      LIMIT 50
    `;
    const searchTerm = `%${searchQuery}%`;
    const result = await pool.query(query, [searchTerm, latitude, longitude]);
    return result.rows.map(park => this.formatPark(park));
  }

  // Get current activity level based on active check-ins
  static async getActivityLevel(parkId) {
    const query = `
      SELECT COUNT(*) as active_checkins
      FROM checkins 
      WHERE dog_park_id = $1 AND checked_out_at IS NULL
    `;
    const result = await pool.query(query, [parkId]);
    const count = parseInt(result.rows[0].active_checkins);
    
    // Simple activity level calculation
    if (count === 0) return 'quiet';
    if (count <= 3) return 'low';
    if (count <= 8) return 'moderate';
    return 'busy';
  }

  // Helper method to format park data for API responses
  static formatPark(park) {
    if (!park) return null;

    return {
      id: park.id,
      name: park.name,
      description: park.description,
      address: park.address,
      latitude: parseFloat(park.latitude),
      longitude: parseFloat(park.longitude),
      amenities: park.amenities || [],
      rules: park.rules,
      hoursOpen: park.hours_open,
      hoursClose: park.hours_close,
      distanceKm: park.distance_km ? parseFloat(park.distance_km) : undefined,
      createdAt: park.created_at,
      updatedAt: park.updated_at,
      website: park.website,
      phone: park.phone,
      rating: park.rating ? parseFloat(park.rating) : undefined,
      reviewCount: park.review_count,
      surfaceType: park.surface_type,
      hasSeating: park.has_seating,
      zipcode: park.zipcode,
      borough: park.borough
    };
  }
}

module.exports = DogPark;