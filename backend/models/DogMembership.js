const pool = require('../config/database');

const ACTIVE_STATUS = 'active';
const INVITED_STATUS = 'invited';
const MANAGER_ROLES = ['owner', 'manager', 'editor'];

class DogMembership {
  static getQueryClient(client) {
    return client || pool;
  }

  static async create({ dogId, userId, role = 'owner', status = ACTIVE_STATUS, invitedBy = null }, client) {
    const db = this.getQueryClient(client);
    const query = `
      INSERT INTO dog_memberships (dog_id, user_id, role, status, invited_by)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (dog_id, user_id) DO UPDATE
      SET role = EXCLUDED.role,
          status = EXCLUDED.status,
          invited_by = EXCLUDED.invited_by,
          updated_at = CURRENT_TIMESTAMP
      RETURNING *
    `;
    const values = [dogId, userId, role, status, invitedBy];
    const result = await db.query(query, values);
    return result.rows[0];
  }

  static async inviteOwner({ dogId, invitedUserId, invitedBy, role = 'owner' }, client) {
    return this.create({
      dogId,
      userId: invitedUserId,
      role,
      status: INVITED_STATUS,
      invitedBy
    }, client);
  }

  static async acceptInvite(dogId, userId, client) {
    const db = this.getQueryClient(client);
    const query = `
      UPDATE dog_memberships
      SET status = $3, updated_at = CURRENT_TIMESTAMP
      WHERE dog_id = $1 AND user_id = $2 AND status = $4
      RETURNING *
    `;
    const values = [dogId, userId, ACTIVE_STATUS, INVITED_STATUS];
    const result = await db.query(query, values);
    return result.rows[0] || null;
  }

  static async findMembership(dogId, userId, { roles, statuses } = {}, client) {
    const db = this.getQueryClient(client);
    const conditions = ['dog_id = $1', 'user_id = $2'];
    const values = [dogId, userId];
    let paramIndex = values.length + 1;

    if (roles && roles.length) {
      conditions.push(`role = ANY($${paramIndex}::text[])`);
      values.push(roles);
      paramIndex += 1;
    }

    if (statuses && statuses.length) {
      conditions.push(`status = ANY($${paramIndex}::text[])`);
      values.push(statuses);
    }

    const query = `
      SELECT *
      FROM dog_memberships
      WHERE ${conditions.join(' AND ')}
      LIMIT 1
    `;
    const result = await db.query(query, values);
    return result.rows[0] || null;
  }

  static async findActiveMembership(dogId, userId, client) {
    return this.findMembership(dogId, userId, { statuses: [ACTIVE_STATUS] }, client);
  }

  static async findManagerMembership(dogId, userId, client) {
    return this.findMembership(
      dogId,
      userId,
      { statuses: [ACTIVE_STATUS], roles: MANAGER_ROLES },
      client
    );
  }

  static async canManage(dogId, userId, client) {
    const membership = await this.findManagerMembership(dogId, userId, client);
    return Boolean(membership);
  }

  static async remove(dogId, userId, client) {
    const db = this.getQueryClient(client);
    const query = `
      DELETE FROM dog_memberships
      WHERE dog_id = $1 AND user_id = $2
      RETURNING *
    `;
    const result = await db.query(query, [dogId, userId]);
    return result.rows[0] || null;
  }

  static async listOwners(dogId, client) {
    const ownersByDog = await this.listOwnersForDogs([dogId], client);
    return ownersByDog[dogId] || [];
  }

  static async listOwnersForDogs(dogIds, client) {
    if (!dogIds || dogIds.length === 0) {
      return {};
    }

    const db = this.getQueryClient(client);
    const query = `
      SELECT
        dm.dog_id,
        dm.role,
        dm.status,
        dm.invited_by,
        dm.created_at,
        dm.updated_at,
        u.id AS user_id,
        u.first_name,
        u.last_name,
        u.profile_image_url
      FROM dog_memberships dm
      JOIN users u ON u.id = dm.user_id
      WHERE dm.dog_id = ANY($1::int[])
        AND dm.status = $2
      ORDER BY dm.dog_id, u.first_name, u.last_name
    `;
    const result = await db.query(query, [dogIds, ACTIVE_STATUS]);

    return result.rows.reduce((acc, row) => {
      if (!acc[row.dog_id]) {
        acc[row.dog_id] = [];
      }
      acc[row.dog_id].push(this.serializeMembershipRow(row));
      return acc;
    }, {});
  }

  static serializeMembershipRow(row) {
    if (!row) return null;
    return {
      id: row.user_id,
      firstName: row.first_name,
      lastName: row.last_name,
      profileImageUrl: row.profile_image_url,
      role: row.role,
      status: row.status,
      invitedBy: row.invited_by,
      joinedAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}

DogMembership.ACTIVE_STATUS = ACTIVE_STATUS;
DogMembership.INVITED_STATUS = INVITED_STATUS;
DogMembership.MANAGER_ROLES = MANAGER_ROLES;

module.exports = DogMembership;
