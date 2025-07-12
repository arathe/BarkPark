const pool = require('../config/database');

// Compatible version of DogPark model that works with both PostGIS and non-PostGIS databases
class DogParkCompat {
  static hasPostGIS = null;

  static async checkPostGIS() {
    if (this.hasPostGIS !== null) return this.hasPostGIS;
    
    try {
      await pool.query("SELECT PostGIS_Version()");
      this.hasPostGIS = true;
    } catch {
      this.hasPostGIS = false;
    }
    
    return this.hasPostGIS;
  }

  static async findAll() {
    const hasPostGIS = await this.checkPostGIS();
    
    let query;
    if (hasPostGIS) {
      query = `
        SELECT 
          id, name, description, address,
          ST_X(location::geometry) as longitude, 
          ST_Y(location::geometry) as latitude,
          amenities, rules, hours_open, hours_close,
          website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
          created_at, updated_at
        FROM dog_parks 
        ORDER BY name
      `;
    } else {
      query = `
        SELECT 
          id, name, description, address,
          longitude, latitude,
          amenities, rules, hours_open, hours_close,
          website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
          created_at, updated_at
        FROM dog_parks 
        ORDER BY name
      `;
    }
    
    const result = await pool.query(query);
    return result.rows.map(park => this.formatPark(park));
  }

  static async findById(parkId) {
    const hasPostGIS = await this.checkPostGIS();
    
    let query;
    if (hasPostGIS) {
      query = `
        SELECT 
          id, name, description, address,
          ST_X(location::geometry) as longitude, 
          ST_Y(location::geometry) as latitude,
          amenities, rules, hours_open, hours_close,
          website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
          created_at, updated_at
        FROM dog_parks 
        WHERE id = $1
      `;
    } else {
      query = `
        SELECT 
          id, name, description, address,
          longitude, latitude,
          amenities, rules, hours_open, hours_close,
          website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
          created_at, updated_at
        FROM dog_parks 
        WHERE id = $1
      `;
    }
    
    const result = await pool.query(query, [parkId]);
    return result.rows[0] ? this.formatPark(result.rows[0]) : null;
  }

  static async findNearby(latitude, longitude, radiusKm = 10) {
    const hasPostGIS = await this.checkPostGIS();
    
    if (hasPostGIS) {
      // Use PostGIS for accurate distance calculations
      const query = `
        SELECT 
          id, name, description, address,
          ST_X(location::geometry) as longitude, 
          ST_Y(location::geometry) as latitude,
          amenities, rules, hours_open, hours_close,
          website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
          ST_Distance(
            location::geography,
            ST_MakePoint($2, $1)::geography
          ) / 1000.0 as distance_km,
          created_at, updated_at
        FROM dog_parks 
        WHERE ST_DWithin(
          location::geography,
          ST_MakePoint($2, $1)::geography,
          $3::numeric * 1000
        )
        ORDER BY distance_km
      `;
      
      const result = await pool.query(query, [latitude, longitude, radiusKm]);
      return result.rows.map(park => this.formatPark(park));
    } else {
      // Fallback to Haversine formula for non-PostGIS databases
      const query = `
        SELECT 
          id, name, description, address,
          longitude, latitude,
          amenities, rules, hours_open, hours_close,
          website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
          (
            6371 * acos(
              cos(radians($1)) * cos(radians(latitude)) * 
              cos(radians(longitude) - radians($2)) + 
              sin(radians($1)) * sin(radians(latitude))
            )
          ) as distance_km,
          created_at, updated_at
        FROM dog_parks 
        WHERE latitude IS NOT NULL AND longitude IS NOT NULL
        AND (
          6371 * acos(
            cos(radians($1)) * cos(radians(latitude)) * 
            cos(radians(longitude) - radians($2)) + 
            sin(radians($1)) * sin(radians(latitude))
          )
        ) <= $3
        ORDER BY distance_km
      `;
      
      const result = await pool.query(query, [latitude, longitude, radiusKm]);
      return result.rows.map(park => this.formatPark(park));
    }
  }

  static async create(parkData) {
    const hasPostGIS = await this.checkPostGIS();
    const {
      name, description, address, latitude, longitude,
      amenities, rules, hoursOpen, hoursClose,
      website, phone, rating, reviewCount,
      surfaceType, hasSeating, zipcode, borough
    } = parkData;

    let query;
    let values;
    
    if (hasPostGIS) {
      query = `
        INSERT INTO dog_parks (
          name, description, address, location, amenities, rules, 
          hours_open, hours_close, website, phone, rating, review_count,
          surface_type, has_seating, zipcode, borough
        )
        VALUES ($1, $2, $3, ST_MakePoint($5, $4)::geography, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
        RETURNING id, name, description, address,
                  ST_X(location::geometry) as longitude, 
                  ST_Y(location::geometry) as latitude,
                  amenities, rules, hours_open, hours_close,
                  website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
                  created_at, updated_at
      `;
      values = [
        name, description || null, address, latitude, longitude,
        amenities || null, rules || null, hoursOpen || null, hoursClose || null,
        website || null, phone || null, rating || null, reviewCount || null, 
        surfaceType || null, hasSeating || false, zipcode || null, borough || null
      ];
    } else {
      query = `
        INSERT INTO dog_parks (
          name, description, address, latitude, longitude, amenities, rules, 
          hours_open, hours_close, website, phone, rating, review_count,
          surface_type, has_seating, zipcode, borough
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
        RETURNING id, name, description, address, longitude, latitude,
                  amenities, rules, hours_open, hours_close,
                  website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
                  created_at, updated_at
      `;
      values = [
        name, description || null, address, latitude, longitude,
        amenities || null, rules || null, hoursOpen || null, hoursClose || null,
        website || null, phone || null, rating || null, reviewCount || null, 
        surfaceType || null, hasSeating || false, zipcode || null, borough || null
      ];
    }

    const result = await pool.query(query, values);
    return this.formatPark(result.rows[0]);
  }

  static async findWithinBounds(northEast, southWest) {
    const hasPostGIS = await this.checkPostGIS();
    
    if (hasPostGIS) {
      const query = `
        SELECT 
          id, name, description, address,
          ST_X(location::geometry) as longitude, 
          ST_Y(location::geometry) as latitude,
          amenities, rules, hours_open, hours_close,
          website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
          created_at, updated_at
        FROM dog_parks 
        WHERE location && ST_MakeEnvelope($1, $2, $3, $4, 4326)::geography
        ORDER BY name
      `;
      
      const values = [
        southWest.longitude, southWest.latitude,
        northEast.longitude, northEast.latitude
      ];
      
      const result = await pool.query(query, values);
      return result.rows.map(park => this.formatPark(park));
    } else {
      // Fallback for non-PostGIS
      const query = `
        SELECT 
          id, name, description, address,
          longitude, latitude,
          amenities, rules, hours_open, hours_close,
          website, phone, rating, review_count, surface_type, has_seating, zipcode, borough,
          created_at, updated_at
        FROM dog_parks 
        WHERE latitude BETWEEN $1 AND $2
          AND longitude BETWEEN $3 AND $4
        ORDER BY name
      `;
      
      const values = [
        Math.min(southWest.latitude, northEast.latitude),
        Math.max(southWest.latitude, northEast.latitude),
        Math.min(southWest.longitude, northEast.longitude),
        Math.max(southWest.longitude, northEast.longitude)
      ];
      
      const result = await pool.query(query, values);
      return result.rows.map(park => this.formatPark(park));
    }
  }

  static async search(searchQuery) {
    const hasPostGIS = await this.checkPostGIS();
    const searchTerm = `%${searchQuery}%`;
    
    if (hasPostGIS) {
      const query = `
        SELECT 
          id, name, description, address,
          ST_X(location::geometry) as longitude, 
          ST_Y(location::geometry) as latitude,
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
      
      const result = await pool.query(query, [searchTerm]);
      return result.rows.map(park => this.formatPark(park));
    } else {
      const query = `
        SELECT 
          id, name, description, address,
          longitude, latitude,
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
      
      const result = await pool.query(query, [searchTerm]);
      return result.rows.map(park => this.formatPark(park));
    }
  }

  static async searchWithLocation(searchQuery, latitude, longitude) {
    const hasPostGIS = await this.checkPostGIS();
    const searchTerm = `%${searchQuery}%`;
    
    if (hasPostGIS) {
      const query = `
        SELECT 
          id, name, description, address,
          ST_X(location::geometry) as longitude, 
          ST_Y(location::geometry) as latitude,
          amenities, rules, hours_open, hours_close,
          ST_Distance(
            location::geography,
            ST_MakePoint($3, $2)::geography
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
      
      const result = await pool.query(query, [searchTerm, latitude, longitude]);
      return result.rows.map(park => this.formatPark(park));
    } else {
      // Fallback with Haversine
      const query = `
        SELECT 
          id, name, description, address,
          longitude, latitude,
          amenities, rules, hours_open, hours_close,
          (
            6371 * acos(
              cos(radians($2)) * cos(radians(latitude)) * 
              cos(radians(longitude) - radians($3)) + 
              sin(radians($2)) * sin(radians(latitude))
            )
          ) as distance_km,
          created_at, updated_at, website, phone, rating, 
          review_count, surface_type, has_seating, zipcode, borough
        FROM dog_parks 
        WHERE 
          (name ILIKE $1 OR 
           description ILIKE $1 OR 
           address ILIKE $1 OR
           borough ILIKE $1)
          AND latitude IS NOT NULL 
          AND longitude IS NOT NULL
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
      
      const result = await pool.query(query, [searchTerm, latitude, longitude]);
      return result.rows.map(park => this.formatPark(park));
    }
  }

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
    if (count <= 3) return 'moderate';
    if (count <= 6) return 'busy';
    return 'very busy';
  }

  static async getActiveCheckIns(parkId) {
    const query = `
      SELECT 
        c.id, c.user_id, c.checked_in_at, c.dogs,
        u.first_name, u.last_name, u.profile_image_url,
        ARRAY_AGG(
          JSON_BUILD_OBJECT(
            'id', d.id,
            'name', d.name,
            'breed', d.breed,
            'profile_image_url', d.profile_image_url
          )
        ) FILTER (WHERE d.id IS NOT NULL) as dog_details
      FROM checkins c
      LEFT JOIN users u ON c.user_id = u.id
      LEFT JOIN dogs d ON d.id = ANY(c.dogs) AND d.user_id = c.user_id
      WHERE c.dog_park_id = $1 AND c.checked_out_at IS NULL
      GROUP BY c.id, u.id
      ORDER BY c.checked_in_at DESC
    `;
    
    const result = await pool.query(query, [parkId]);
    return result.rows;
  }
}

module.exports = DogParkCompat;