const pool = require('../config/database');
const DogMembership = require('./DogMembership');

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

    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      const insertDogQuery = `
        INSERT INTO dogs (
          primary_owner_id, name, breed, birthday, weight, gender, size_category,
          energy_level, friendliness_dogs, friendliness_people, training_level,
          favorite_activities, is_vaccinated, is_spayed_neutered, special_needs,
          bio, profile_image_url
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
        RETURNING *
      `;

      const insertDogValues = [
        userId, name, breed, birthday, weight, gender, sizeCategory,
        energyLevel, friendlinessDogs, friendlinessPeople, trainingLevel,
        JSON.stringify(favoriteActivities || []), isVaccinated, isSpayedNeutered,
        specialNeeds, bio, profileImageUrl
      ];

      const dogResult = await client.query(insertDogQuery, insertDogValues);
      const dogRow = dogResult.rows[0];

      await DogMembership.create({
        dogId: dogRow.id,
        userId,
        role: 'owner',
        status: DogMembership.ACTIVE_STATUS,
        invitedBy: userId
      }, client);

      await client.query('COMMIT');

      return await this.findById(dogRow.id);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async findByUserId(userId) {
    const query = `
      SELECT d.*
      FROM dogs d
      INNER JOIN dog_memberships dm
        ON dm.dog_id = d.id
       AND dm.user_id = $1
       AND dm.status = $2
      ORDER BY d.created_at DESC
    `;

    const result = await pool.query(query, [userId, DogMembership.ACTIVE_STATUS]);
    const dogIds = result.rows.map(row => row.id);
    const ownersByDog = await DogMembership.listOwnersForDogs(dogIds);

    return result.rows.map(dog => this.formatDog(dog, ownersByDog[dog.id]));
  }

  static async findById(dogId) {
    const query = `
      SELECT
        d.*,
        owners.members AS owners
      FROM dogs d
      LEFT JOIN LATERAL (
        SELECT json_agg(
          json_build_object(
            'membershipId', dm2.id,
            'userId', dm2.user_id,
            'role', dm2.role,
            'status', dm2.status,
            'invitedBy', dm2.invited_by,
            'isPrimaryOwner', dm2.role = 'primary_owner',
            'joinedAt', dm2.created_at,
            'updatedAt', dm2.updated_at,
            'user', json_build_object(
              'id', u2.id,
              'email', u2.email,
              'firstName', u2.first_name,
              'lastName', u2.last_name,
              'fullName', CONCAT(u2.first_name, ' ', u2.last_name),
              'profileImageUrl', u2.profile_image_url
            )
          )
          ORDER BY CASE dm2.role WHEN 'primary_owner' THEN 0 WHEN 'co_owner' THEN 1 ELSE 2 END,
            u2.first_name,
            u2.last_name
        ) AS members
        FROM dog_memberships dm2
        JOIN users u2 ON u2.id = dm2.user_id
        WHERE dm2.dog_id = d.id AND dm2.status = 'active'
      ) owners ON TRUE
      WHERE d.id = $1
    `;

    const result = await pool.query(query, [dogId]);

    if (!result.rows[0]) {
      return null;
    }

    const owners = await DogMembership.listOwners(dogId);
    return this.formatDog(result.rows[0], owners);
  }

  static async findByIdAndUser(dogId, userId) {
    const membership = await DogMembership.findManagerMembership(dogId, userId);

    if (!membership) {
      return null;
    }

    return await this.findById(dogId);
  }

  static async update(dogId, userId, updates) {
    const membership = await DogMembership.findManagerMembership(dogId, userId);
    if (!membership) {
      return null;
    }

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
    values.push(dogId);

    const query = `
      UPDATE dogs
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await pool.query(query, values);
    if (!result.rows[0]) {
      return null;
    }

    const owners = await DogMembership.listOwners(dogId);
    return this.formatDog(result.rows[0], owners);
  }

  static async delete(dogId, userId) {
    const membership = await DogMembership.findMembership(
      dogId,
      userId,
      { statuses: [DogMembership.ACTIVE_STATUS], roles: ['owner'] }
    );

    if (!membership) {
      return null;
    }

    const query = 'DELETE FROM dogs WHERE id = $1 RETURNING *';
    const result = await pool.query(query, [dogId]);
    return result.rows[0] ? this.formatDog(result.rows[0], []) : null;
  }

  static async addGalleryImage(dogId, userId, imageUrl) {
    await DogMembership.authorize(userId, dogId, 'edit');
    const dog = await this.findById(dogId);
    if (!dog) return null;

    const currentGallery = dog.galleryImages || [];
    const updatedGallery = [...currentGallery, imageUrl];

    return this.updateById(dogId, { gallery_images: updatedGallery });
  }

  static async removeGalleryImage(dogId, userId, imageUrl) {
    await DogMembership.authorize(userId, dogId, 'edit');
    const dog = await this.findById(dogId);
    if (!dog) return null;

    const currentGallery = dog.galleryImages || [];
    const updatedGallery = currentGallery.filter(url => url !== imageUrl);

    return this.updateById(dogId, { gallery_images: updatedGallery });
  }

  // Helper method to format dog data for API responses
  static formatDog(dog, ownersOverride = null) {
    if (!dog) return null;

    const age = dog.birthday ? this.calculateAge(dog.birthday) : null;

    const owners = this.normalizeOwners(ownersOverride || dog.owners);

    return {
      id: dog.id,
      userId: dog.primary_owner_id,
      primaryOwnerId: dog.primary_owner_id,
      name: dog.name,
      breed: dog.breed,
      birthday: dog.birthday,
      age,
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
      owners,
      createdAt: dog.created_at,
      updatedAt: dog.updated_at
    };
  }

  static normalizeOwners(ownersData) {
    if (!ownersData) return [];

    if (Array.isArray(ownersData)) {
      return ownersData;
    }

    if (typeof ownersData === 'object') {
      return [ownersData];
    }

    try {
      const parsed = JSON.parse(ownersData);
      return Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      return [];
    }
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

    if (typeof jsonData === 'object') {
      return jsonData;
    }

    try {
      return JSON.parse(jsonData);
    } catch (error) {
      return [];
    }
  }

  static parseOwners(ownerData) {
    if (!ownerData) return [];

    if (typeof ownerData === 'object') {
      return ownerData;
    }

    try {
      return JSON.parse(ownerData);
    } catch (error) {
      return [];
    }
  }
}

module.exports = Dog;