-- Rollback script for 004_add_user_privacy.sql

-- Remove privacy settings from users table
ALTER TABLE users
DROP COLUMN IF EXISTS is_searchable;

-- Drop the index if it exists
DROP INDEX IF EXISTS idx_users_searchable;