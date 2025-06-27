-- Migration: Add password reset functionality
-- Description: Add fields to users table for password reset tokens and expiration

-- Add password reset fields to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS reset_token VARCHAR(255),
ADD COLUMN IF NOT EXISTS reset_token_expires TIMESTAMP;

-- Create index for faster token lookups
CREATE INDEX IF NOT EXISTS idx_users_reset_token ON users(reset_token);

-- Add comment for documentation
COMMENT ON COLUMN users.reset_token IS 'Secure token for password reset functionality';
COMMENT ON COLUMN users.reset_token_expires IS 'Expiration timestamp for reset token';