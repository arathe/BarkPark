const pool = require('../config/database');

class DogPark {
  // Check if we're using PostGIS (location column) or simple lat/lng
  static async usesPostGIS() {
    try {
      const result = await pool.query(`
        SELECT column_name FROM information_schema.columns 
        WHERE table_name = 'dog_parks' AND column_name = 'location'
      `);
      return result.rows.length > 0;
    } catch (error) {
      return false;
    }
  }

  static async findAll() {
    const isPostGIS = await this.usesPostGIS();
    
    const query = isPostGIS ? `
      SELECT 
        id, name, description, address,
        ST_X(location) as longitude, ST_Y(location) as latitude,
        amenities, rules, hours_open, hours_close,
        website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
        created_at, updated_at
      FROM dog_parks 
      ORDER BY name
    ` : `
      SELECT 
        id, name, description, address, latitude, longitude,
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
    const isPostGIS = await this.usesPostGIS();
    
    const query = isPostGIS ? `
      SELECT 
        id, name, description, address,
        ST_X(location) as longitude, ST_Y(location) as latitude,
        amenities, rules, hours_open, hours_close,
        website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
        created_at, updated_at
      FROM dog_parks 
      WHERE id = $1
    ` : `
      SELECT 
        id, name, description, address, latitude, longitude,
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
    const isPostGIS = await this.usesPostGIS();
    
    if (isPostGIS) {
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
    } else {
      // Using simple lat/lng with Haversine approximation
      const query = `
        SELECT 
          id, name, description, address, latitude, longitude,
          amenities, rules, hours_open, hours_close,
          website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
          (6371 * acos(cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2)) + sin(radians($1)) * sin(radians(latitude)))) as distance_km,
          created_at, updated_at
        FROM dog_parks 
        WHERE (6371 * acos(cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2)) + sin(radians($1)) * sin(radians(latitude)))) <= $3
        ORDER BY distance_km
      `;
      const result = await pool.query(query, [latitude, longitude, radiusKm]);
      return result.rows.map(park => this.formatPark(park));
    }
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

    const isPostGIS = await this.usesPostGIS();

    if (isPostGIS) {
      const query = `
        INSERT INTO dog_parks (
          name, description, address, location, amenities, rules, hours_open, hours_close
        )
        VALUES ($1, $2, $3, ST_SetSRID(ST_MakePoint($5, $4), 4326), $6, $7, $8, $9)
        RETURNING id, name, description, address,
                  ST_X(location) as longitude, ST_Y(location) as latitude,
                  amenities, rules, hours_open, hours_close,
                  created_at, updated_at
      `;

      const values = [
        name, description, address, latitude, longitude,
        amenities || null, rules, hoursOpen, hoursClose
      ];

      const result = await pool.query(query, values);
      return this.formatPark(result.rows[0]);
    } else {
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
  }

  static async update(parkId, updates) {
    const allowedFields = [
      'name', 'description', 'address', 'latitude', 'longitude', 
      'amenities', 'rules', 'hours_open', 'hours_close'
    ];

    const isPostGIS = await this.usesPostGIS();
    const fields = [];
    const values = [];
    let paramCount = 1;
    let hasLocation = false;
    let latitude, longitude;

    Object.keys(updates).forEach(key => {
      if (allowedFields.includes(key) && updates[key] !== undefined) {
        if (key === 'latitude') {
          latitude = updates[key];
          hasLocation = true;
        } else if (key === 'longitude') {
          longitude = updates[key];
          hasLocation = true;
        } else {
          fields.push(`${key} = $${paramCount}`);
          values.push(updates[key]);
          paramCount++;
        }
      }
    });

    // Handle location update
    if (hasLocation && latitude !== undefined && longitude !== undefined) {
      if (isPostGIS) {
        fields.push(`location = ST_SetSRID(ST_MakePoint($${paramCount + 1}, $${paramCount}), 4326)`);
        values.push(latitude, longitude);
        paramCount += 2;
      } else {
        fields.push(`latitude = $${paramCount}`, `longitude = $${paramCount + 1}`);
        values.push(latitude, longitude);
        paramCount += 2;
      }
    }

    if (fields.length === 0) {
      throw new Error('No valid fields to update');
    }

    fields.push('updated_at = CURRENT_TIMESTAMP');
    values.push(parkId);

    const query = isPostGIS ? `
      UPDATE dog_parks 
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, name, description, address,
                ST_X(location) as longitude, ST_Y(location) as latitude,
                amenities, rules, hours_open, hours_close,
                created_at, updated_at
    ` : `
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
    const isPostGIS = await this.usesPostGIS();
    
    const query = isPostGIS ? `
      DELETE FROM dog_parks WHERE id = $1 
      RETURNING id, name, description, address,
                ST_X(location) as longitude, ST_Y(location) as latitude,
                amenities, rules, hours_open, hours_close,
                website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
                created_at, updated_at
    ` : `
      DELETE FROM dog_parks WHERE id = $1 
      RETURNING id, name, description, address, latitude, longitude,
                amenities, rules, hours_open, hours_close,
                website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
                created_at, updated_at
    `;
    
    const result = await pool.query(query, [parkId]);
    return result.rows[0] ? this.formatPark(result.rows[0]) : null;
  }

  static async search(searchQuery) {
    const isPostGIS = await this.usesPostGIS();
    
    const query = isPostGIS ? `
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
    ` : `
      SELECT 
        id, name, description, address, latitude, longitude,
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
    const isPostGIS = await this.usesPostGIS();
    
    if (isPostGIS) {
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
    } else {
      const query = `
        SELECT 
          id, name, description, address, latitude, longitude,
          amenities, rules, hours_open, hours_close,
          (6371 * acos(cos(radians($2)) * cos(radians(latitude)) * cos(radians(longitude) - radians($3)) + sin(radians($2)) * sin(radians(latitude)))) as distance_km,
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