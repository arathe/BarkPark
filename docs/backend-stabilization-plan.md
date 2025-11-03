# Backend Stabilization Plan

This document captures the phased plan to resolve the current backend test failures while keeping the schema and API surface consistent across local, staging, and production environments.

## Phase 1 – Critical Fixes

### Notifications Schema Alignment
- Migration `013_fix_notifications_schema.sql` (already in the repo) introduces a `data JSONB DEFAULT '{}'::jsonb NOT NULL` column—confirm it has been applied in your environment.  
  - It retains the existing scalar columns (`actor_id`, `post_id`, `comment_id`) to preserve current foreign key enforcement, so keep the model writing to both the JSONB payload and scalar columns for now.
  - It backfills existing rows using `jsonb_strip_nulls(jsonb_build_object('actorId', actor_id, 'postId', post_id, 'commentId', comment_id))` whenever `data` was empty.
- Standardize the read flag. Either rename `is_read` to `read` in the migration or update all code to use `is_read`. The model, routes, and tests must agree on the chosen name.
- Update `backend/models/Notification.js`, notification route handlers, and related services to read/write the final column set.  
- Expand notification test coverage:  
  - Verify JSON payload structure, read/unread toggling, and bulk creation.  
  - Add assertions to `backend/tests/database-integrity.test.js` to guarantee the presence and types of the new columns.

### Friends API Contract Consistency
- Adopt camelCase response keys (`requesterId`, `addresseeId`) as the canonical API contract (matches current route output and iOS expectations).  
- Update `backend/tests/routes/friends.test.js` and any other assertions to match camelCase responses; document the contract in test comments to avoid regressions.  
- Ensure error payloads are also validated with the same casing for completeness.

## Phase 2 – Important Fixes

### Password Reset Expiration Handling
- Migration `014_update_reset_token_expires.sql` converts `users.reset_token_expires` to `TIMESTAMPTZ`, normalizing existing rows via `ALTER TABLE … USING reset_token_expires AT TIME ZONE 'UTC'`; ensure this migration is applied in every environment.  
- Update `User.generatePasswordResetToken` to persist UTC timestamps (e.g., via `new Date().toISOString()`), and ensure `User.findByResetToken`/`resetPassword` operate correctly with the new type.  
- Extend password reset tests to cover token creation, expiration, and verification using mocked `Date` objects to simulate expiry.

### Injectable S3 Configuration
- Refactor `backend/config/s3.js` so bucket name and credentials are read lazily or via an exported factory, allowing tests to override environment variables after module load.  
- Adjust `backend/tests/utils/s3-upload.test.js` to verify that mocked AWS calls receive the overridden bucket/key, ensuring the configuration is properly injected.

## Phase 3 – Optional / Follow-up Improvements

### PostGIS Documentation Note
- Add a short note (README or inline comments) explaining the coexistence of geography and scalar latitude/longitude columns, and the rationale for retaining both for compatibility. No code changes required unless we later decide to drop the scalar fields.

### Index Verification
- Enhance `backend/tests/database-integrity.test.js` to assert the exact index names currently expected (e.g., containing `user_id` / `friend_id`). Only create new migrations if the existing names do not meet clarity or convention requirements.
- Migration `015_rename_friendship_indexes.sql` renames the friendships index and unique constraint to match the user/friend column naming; apply it wherever 013/014 have been run.

## Guardrails & Validation
- For each new migration:  
  - Update integrity tests to cover new columns/constraints.  
  - Run `npm run db:migrate:status` and `npm run db:migrate:verify` locally before pushing.
- Document rollback instructions alongside each migration (even if the rollback is manual SQL).
- After completing each phase, run the full Jest suite prior to attempting `npm run deploy-staging`.
