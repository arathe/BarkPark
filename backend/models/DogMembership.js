const pool = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const EmailService = require('../services/emailService');
const User = require('./User');

const ROLE_PERMISSIONS = {
  primary_owner: new Set(['view', 'edit', 'manage', 'delete']),
  co_owner: new Set(['view', 'edit']),
  viewer: new Set(['view'])
};

class MembershipError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.statusCode = statusCode;
  }
}

class DogMembership {
  static get emailService() {
    if (!this._emailService) {
      this._emailService = new EmailService();
    }
    return this._emailService;
  }

  static hasPermission(role, permission) {
    const allowed = ROLE_PERMISSIONS[role] || new Set();
    return allowed.has(permission);
  }

  static async getActiveMembership(userId, dogId, client = pool) {
    const executor = client;
    const result = await executor.query(
      `SELECT * FROM dog_memberships WHERE dog_id = $1 AND user_id = $2 AND status = 'active'`,
      [dogId, userId]
    );
    return result.rows[0] || null;
  }

  static async authorize(userId, dogId, permission = 'view', client = pool) {
    const membership = await this.getActiveMembership(userId, dogId, client);

    if (!membership) {
      throw new MembershipError('Dog not found or access denied', 404);
    }

    if (!this.hasPermission(membership.role, permission)) {
      throw new MembershipError('Insufficient permissions for this action', 403);
    }

    return membership;
  }

  static async listMembers(dogId, { includeInvitations = true } = {}, client = pool) {
    const executor = client;

    const membersResult = await executor.query(
      `
        SELECT
          dm.*, 
          u.email AS user_email,
          u.first_name AS user_first_name,
          u.last_name AS user_last_name,
          u.profile_image_url AS user_profile_image_url
        FROM dog_memberships dm
        JOIN users u ON u.id = dm.user_id
        WHERE dm.dog_id = $1 AND dm.status = 'active'
        ORDER BY
          CASE dm.role
            WHEN 'primary_owner' THEN 0
            WHEN 'co_owner' THEN 1
            ELSE 2
          END,
          u.first_name,
          u.last_name
      `,
      [dogId]
    );

    let invitations = [];
    if (includeInvitations) {
      const inviteResult = await executor.query(
        `
          SELECT
            di.*, 
            u.email AS invited_user_email,
            u.first_name AS invited_user_first_name,
            u.last_name AS invited_user_last_name,
            u.profile_image_url AS invited_user_profile_image_url
          FROM dog_membership_invitations di
          LEFT JOIN users u ON u.id = di.invited_user_id
          WHERE di.dog_id = $1 AND di.status = 'pending'
          ORDER BY di.created_at DESC
        `,
        [dogId]
      );
      invitations = inviteResult.rows.map(row => this.formatInvitationRow(row));
    }

    return {
      members: membersResult.rows.map(row => this.formatMemberRow(row)),
      invitations
    };
  }

  static formatMemberRow(row) {
    return {
      membershipId: row.id,
      dogId: row.dog_id,
      userId: row.user_id,
      role: row.role,
      status: row.status,
      invitedBy: row.invited_by,
      joinedAt: row.created_at,
      updatedAt: row.updated_at,
      isPrimaryOwner: row.role === 'primary_owner',
      user: {
        id: row.user_id,
        email: row.user_email,
        firstName: row.user_first_name,
        lastName: row.user_last_name,
        fullName: [row.user_first_name, row.user_last_name].filter(Boolean).join(' ').trim(),
        profileImageUrl: row.user_profile_image_url
      }
    };
  }

  static formatInvitationRow(row) {
    const invitedEmail = row.email || row.invited_user_email;
    const firstName = row.invited_user_first_name;
    const lastName = row.invited_user_last_name;
    return {
      id: row.id,
      dogId: row.dog_id,
      invitedUserId: row.invited_user_id,
      email: invitedEmail,
      role: row.role,
      status: row.status,
      invitedBy: row.invited_by,
      expiresAt: row.expires_at,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      user: row.invited_user_id
        ? {
            id: row.invited_user_id,
            email: invitedEmail,
            firstName,
            lastName,
            fullName: [firstName, lastName].filter(Boolean).join(' ').trim(),
            profileImageUrl: row.invited_user_profile_image_url
          }
        : null
    };
  }

  static async addMembership({ dogId, userId, role = 'co_owner', invitedBy }, client = pool) {
    const executor = client;
    const result = await executor.query(
      `
        INSERT INTO dog_memberships (dog_id, user_id, role, status, invited_by)
        VALUES ($1, $2, $3, 'active', $4)
        ON CONFLICT (dog_id, user_id) DO UPDATE
        SET role = EXCLUDED.role,
            status = 'active',
            invited_by = EXCLUDED.invited_by,
            updated_at = CURRENT_TIMESTAMP
        RETURNING *
      `,
      [dogId, userId, role, invitedBy]
    );
    return result.rows[0];
  }

  static async inviteMember({
    dogId,
    inviterId,
    role = 'co_owner',
    targetUserId = null,
    email = null,
    dogName,
    inviterName
  }, client = pool) {
    const executor = client;

    if (!['co_owner', 'viewer', 'primary_owner'].includes(role)) {
      throw new MembershipError('Invalid role specified for invitation', 400);
    }

    if (!targetUserId && !email) {
      throw new MembershipError('Either userId or email is required to invite a member', 400);
    }

    let targetUser = null;
    if (targetUserId) {
      const result = await executor.query(
        `SELECT id, email, first_name, last_name FROM users WHERE id = $1`,
        [targetUserId]
      );
      targetUser = result.rows[0];
      if (!targetUser) {
        throw new MembershipError('Target user not found', 404);
      }
      email = targetUser.email;
    } else {
      const normalizedEmail = email.trim().toLowerCase();
      email = normalizedEmail;
      const existingUser = await User.findByEmail(normalizedEmail);
      if (existingUser) {
        targetUser = existingUser;
      }
    }

    // Prevent inviting someone who is already an active member
    if (targetUser) {
      const existingMembership = await executor.query(
        `SELECT 1 FROM dog_memberships WHERE dog_id = $1 AND user_id = $2 AND status = 'active'`,
        [dogId, targetUser.id]
      );
      if (existingMembership.rows.length > 0) {
        throw new MembershipError('User is already an active member of this dog profile', 409);
      }
    }

    // Prevent duplicate pending invitations
    const pendingInviteCheck = await executor.query(
      `
        SELECT 1
        FROM dog_membership_invitations
        WHERE dog_id = $1
          AND status = 'pending'
          AND (
            ($2::INT IS NOT NULL AND invited_user_id = $2)
            OR (LOWER(email) = LOWER($3) AND $3 IS NOT NULL)
          )
      `,
      [dogId, targetUser ? targetUser.id : null, email]
    );

    if (pendingInviteCheck.rows.length > 0) {
      throw new MembershipError('An active invitation already exists for this user', 409);
    }

    const token = uuidv4();

    const insertResult = await executor.query(
      `
        INSERT INTO dog_membership_invitations (
          dog_id, email, invited_user_id, invited_by, role, token
        )
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
      `,
      [dogId, email, targetUser ? targetUser.id : null, inviterId, role, token]
    );

    const invitation = insertResult.rows[0];

    try {
      await this.emailService.sendDogInvitation({
        toEmail: email,
        dogName,
        inviterName,
        token,
        dogId,
        role
      });
    } catch (emailError) {
      console.error('Failed to send dog invitation email:', emailError);
    }

    return this.formatInvitationRow({ ...invitation, ...this._mapInviteUserFields(targetUser) });
  }

  static _mapInviteUserFields(user) {
    if (!user) return {};
    return {
      invited_user_email: user.email,
      invited_user_first_name: user.first_name,
      invited_user_last_name: user.last_name,
      invited_user_profile_image_url: user.profile_image_url
    };
  }

  static async respondToInvitation({
    dogId,
    invitationId,
    userId,
    token,
    action
  }, client = null) {
    let executor = client;
    let releaseClient = false;

    if (!executor) {
      executor = await pool.connect();
      releaseClient = true;
    }

    const lowerAction = action.toLowerCase();
    if (!['accept', 'decline'].includes(lowerAction)) {
      if (releaseClient) executor.release();
      throw new MembershipError('Action must be either accept or decline', 400);
    }

    try {
      await executor.query('BEGIN');

      const invitationResult = await executor.query(
        `
          SELECT *
          FROM dog_membership_invitations
          WHERE id = $1 AND dog_id = $2 AND status = 'pending'
          FOR UPDATE
        `,
        [invitationId, dogId]
      );

      const invitation = invitationResult.rows[0];
      if (!invitation) {
        throw new MembershipError('Invitation not found or no longer active', 404);
      }

      if (invitation.token !== token) {
        throw new MembershipError('Invalid invitation token', 403);
      }

      const userResult = await executor.query(
        `SELECT id, email, first_name, last_name, profile_image_url FROM users WHERE id = $1`,
        [userId]
      );
      const user = userResult.rows[0];
      if (!user) {
        throw new MembershipError('User not found', 404);
      }

      if (invitation.invited_user_id && invitation.invited_user_id !== userId) {
        throw new MembershipError('You are not authorized to respond to this invitation', 403);
      }

      if (!invitation.invited_user_id && invitation.email && invitation.email.toLowerCase() !== user.email.toLowerCase()) {
        throw new MembershipError('This invitation is addressed to a different email address', 403);
      }

      if (lowerAction === 'decline') {
        const updateResult = await executor.query(
          `
            UPDATE dog_membership_invitations
            SET status = 'declined', invited_user_id = $3, updated_at = CURRENT_TIMESTAMP
            WHERE id = $1 AND dog_id = $2
            RETURNING *
          `,
          [invitationId, dogId, userId]
        );

        await executor.query('COMMIT');
        return { invitation: this.formatInvitationRow(updateResult.rows[0]) };
      }

      const acceptedInviteResult = await executor.query(
        `
          UPDATE dog_membership_invitations
          SET status = 'accepted', invited_user_id = $3, updated_at = CURRENT_TIMESTAMP
          WHERE id = $1 AND dog_id = $2
          RETURNING *
        `,
        [invitationId, dogId, userId]
      );

      const inviteRow = acceptedInviteResult.rows[0];

      const membershipRow = await this.addMembership({
        dogId,
        userId,
        role: inviteRow.role,
        invitedBy: inviteRow.invited_by
      }, executor);

      await executor.query('COMMIT');

      return {
        membership: this.formatMemberRow({
          ...membershipRow,
          user_email: user.email,
          user_first_name: user.first_name,
          user_last_name: user.last_name,
          user_profile_image_url: user.profile_image_url
        })
      };
    } catch (error) {
      await executor.query('ROLLBACK');
      throw error;
    } finally {
      if (releaseClient) {
        executor.release();
      }
    }
  }

  static async updateRole({ dogId, memberId, role, actingUserId }, client = pool) {
    if (!['primary_owner', 'co_owner', 'viewer'].includes(role)) {
      throw new MembershipError('Invalid role specified', 400);
    }

    await this.authorize(actingUserId, dogId, 'manage', client);

    const executor = client;

    const membershipResult = await executor.query(
      `SELECT * FROM dog_memberships WHERE id = $1 AND dog_id = $2 AND status = 'active'`,
      [memberId, dogId]
    );

    const membership = membershipResult.rows[0];
    if (!membership) {
      throw new MembershipError('Membership not found', 404);
    }

    if (membership.role === 'primary_owner' && role !== 'primary_owner') {
      const primaryCount = await this.countActivePrimaryOwners(dogId, executor);
      if (primaryCount <= 1) {
        throw new MembershipError('Each dog must have at least one primary owner', 400);
      }
    }

    const updateResult = await executor.query(
      `
        UPDATE dog_memberships
        SET role = $3, updated_at = CURRENT_TIMESTAMP
        WHERE id = $1 AND dog_id = $2
        RETURNING *
      `,
      [memberId, dogId, role]
    );

    const updated = updateResult.rows[0];
    const user = await User.findById(updated.user_id);

    return this.formatMemberRow({
      ...updated,
      user_email: user.email,
      user_first_name: user.first_name,
      user_last_name: user.last_name,
      user_profile_image_url: user.profile_image_url
    });
  }

  static async removeMember({ dogId, memberId, actingUserId }, client = pool) {
    await this.authorize(actingUserId, dogId, 'manage', client);

    const executor = client;

    const membershipResult = await executor.query(
      `SELECT * FROM dog_memberships WHERE id = $1 AND dog_id = $2 AND status = 'active'`,
      [memberId, dogId]
    );

    const membership = membershipResult.rows[0];
    if (!membership) {
      throw new MembershipError('Membership not found', 404);
    }

    if (membership.role === 'primary_owner') {
      const primaryCount = await this.countActivePrimaryOwners(dogId, executor);
      if (primaryCount <= 1) {
        throw new MembershipError('Cannot remove the last primary owner', 400);
      }
    }

    await executor.query(
      `
        UPDATE dog_memberships
        SET status = 'revoked', updated_at = CURRENT_TIMESTAMP
        WHERE id = $1
      `,
      [memberId]
    );
  }

  static async countActivePrimaryOwners(dogId, client = pool) {
    const executor = client;
    const result = await executor.query(
      `SELECT COUNT(*) FROM dog_memberships WHERE dog_id = $1 AND status = 'active' AND role = 'primary_owner'`,
      [dogId]
    );
    return parseInt(result.rows[0].count, 10);
  }

  static async getOwners(dogId, client = pool) {
    const { members } = await this.listMembers(dogId, { includeInvitations: false }, client);
    return members;
  }
}

module.exports = { DogMembership, MembershipError };
