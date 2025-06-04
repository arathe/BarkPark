const pool = require('../config/database');

class Dog {
  static async create(dogData) {
    const {
      userId,
      name,
      breed,
      birthday,
      weight,
      gender,
      sizeCategory,
      energyLevel,
      friendlinessDogs,
      friendlinessPeople,
      trainingLevel,
      favoriteActivities,
      isVaccinated,
      isSpayedNeutered,
      specialNeeds,
      bio,
      profileImageUrl
    } = dogData;

    const query = `
      INSERT INTO dogs (
        user_id, name, breed, birthday, weight, gender, size_category,
        energy_level, friendliness_dogs, friendliness_people, training_level,
        favorite_activities, is_vaccinated, is_spayed_neutered, special_needs,
        bio, profile_image_url
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
      RETURNING *
    `;

    const values = [
      userId, name, breed, birthday, weight, gender, sizeCategory,
      energyLevel, friendlinessDogs, friendlinessPeople, trainingLevel,
      JSON.stringify(favoriteActivities || []), isVaccinated, isSpayedNeutered,
      specialNeeds, bio, profileImageUrl
    ];

    const result = await pool.query(query, values);
    return this.formatDog(result.rows[0]);
  }

  static async findByUserId(userId) {
    const query = 'SELECT * FROM dogs WHERE user_id = $1 ORDER BY created_at DESC';
    const result = await pool.query(query, [userId]);
    return result.rows.map(dog => this.formatDog(dog));
  }

  static async findById(dogId) {
    const query = 'SELECT * FROM dogs WHERE id = $1';
    const result = await pool.query(query, [dogId]);
    return result.rows[0] ? this.formatDog(result.rows[0]) : null;
  }

  static async findByIdAndUser(dogId, userId) {
    const query = 'SELECT * FROM dogs WHERE id = $1 AND user_id = $2';
    const result = await pool.query(query, [dogId, userId]);
    return result.rows[0] ? this.formatDog(result.rows[0]) : null;
  }

  static async update(dogId, userId, updates) {
    const allowedFields = [
      'name', 'breed', 'birthday', 'weight', 'gender', 'size_category',
      'energy_level', 'friendliness_dogs', 'friendliness_people', 'training_level',
      'favorite_activities', 'is_vaccinated', 'is_spayed_neutered', 'special_needs',
      'bio', 'profile_image_url', 'gallery_images'
    ];

    const fields = [];
    const values = [];
    let paramCount = 1;

    Object.keys(updates).forEach(key => {
      if (allowedFields.includes(key) && updates[key] !== undefined) {
        fields.push(`${key} = $${paramCount}`);
        
        // Handle JSON fields
        if (key === 'favorite_activities' || key === 'gallery_images') {
          values.push(JSON.stringify(updates[key]));
        } else {
          values.push(updates[key]);
        }
        paramCount++;
      }
    });

    if (fields.length === 0) {
      throw new Error('No valid fields to update');
    }

    fields.push('updated_at = CURRENT_TIMESTAMP');
    values.push(dogId, userId);

    const query = `
      UPDATE dogs 
      SET ${fields.join(', ')}
      WHERE id = $${paramCount} AND user_id = $${paramCount + 1}
      RETURNING *
    `;

    const result = await pool.query(query, values);
    return result.rows[0] ? this.formatDog(result.rows[0]) : null;
  }

  static async delete(dogId, userId) {
    const query = 'DELETE FROM dogs WHERE id = $1 AND user_id = $2 RETURNING *';
    const result = await pool.query(query, [dogId, userId]);
    return result.rows[0] ? this.formatDog(result.rows[0]) : null;
  }

  static async addGalleryImage(dogId, userId, imageUrl) {
    // Get current gallery images
    const dog = await this.findByIdAndUser(dogId, userId);
    if (!dog) return null;

    const currentGallery = dog.galleryImages || [];
    const updatedGallery = [...currentGallery, imageUrl];

    return await this.update(dogId, userId, { gallery_images: updatedGallery });
  }

  static async removeGalleryImage(dogId, userId, imageUrl) {
    const dog = await this.findByIdAndUser(dogId, userId);
    if (!dog) return null;

    const currentGallery = dog.galleryImages || [];
    const updatedGallery = currentGallery.filter(url => url !== imageUrl);

    return await this.update(dogId, userId, { gallery_images: updatedGallery });
  }

  // Helper method to format dog data for API responses
  static formatDog(dog) {
    if (!dog) return null;

    // Calculate age from birthday
    const age = dog.birthday ? this.calculateAge(dog.birthday) : null;

    return {
      id: dog.id,
      userId: dog.user_id,
      name: dog.name,
      breed: dog.breed,
      birthday: dog.birthday,
      age: age,
      weight: dog.weight,
      gender: dog.gender,
      sizeCategory: dog.size_category,
      energyLevel: dog.energy_level,
      friendlinessDogs: dog.friendliness_dogs,
      friendlinessPeople: dog.friendliness_people,
      trainingLevel: dog.training_level,
      favoriteActivities: this.parseJSON(dog.favorite_activities),
      isVaccinated: dog.is_vaccinated,
      isSpayedNeutered: dog.is_spayed_neutered,
      specialNeeds: dog.special_needs,
      bio: dog.bio,
      profileImageUrl: dog.profile_image_url,
      galleryImages: this.parseJSON(dog.gallery_images),
      createdAt: dog.created_at,
      updatedAt: dog.updated_at
    };
  }

  static calculateAge(birthday) {
    const today = new Date();
    const birthDate = new Date(birthday);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    
    return age;
  }

  static parseJSON(jsonData) {
    if (!jsonData) return [];
    
    // If it's already an object/array, return it
    if (typeof jsonData === 'object') {
      return jsonData;
    }
    
    // If it's a string, try to parse it
    try {
      return JSON.parse(jsonData);
    } catch (error) {
      return [];
    }
  }
}

module.exports = Dog;