-- Add privacy settings to users table
-- This migration adds user privacy controls for search visibility

-- Add is_searchable column to users table (default to true for existing users)
ALTER TABLE users 
ADD COLUMN is_searchable BOOLEAN DEFAULT true;

-- Create index for efficient filtering of searchable users
CREATE INDEX idx_users_searchable ON users(is_searchable) WHERE is_searchable = true;

-- Update existing users to be searchable by default (maintaining backward compatibility)
UPDATE users SET is_searchable = true WHERE is_searchable IS NULL;

-- Add NOT NULL constraint after setting default values
ALTER TABLE users 
ALTER COLUMN is_searchable SET NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN users.is_searchable IS 'Controls whether user appears in search results for other users';