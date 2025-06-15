-- Add privacy settings to users table
-- This allows users to control their visibility in search results

-- Add is_searchable column
ALTER TABLE users
ADD COLUMN IF NOT EXISTS is_searchable BOOLEAN NOT NULL DEFAULT true;

-- Create index for efficient searchable user queries
CREATE INDEX IF NOT EXISTS idx_users_searchable 
ON users(is_searchable) 
WHERE is_searchable = true;

-- Add helpful comment
COMMENT ON COLUMN users.is_searchable IS 'Controls whether user appears in search results - QR code connections always work';