-- Migration: Add password reset attempts tracking
-- Description: Create table to track password reset attempts for rate limiting

-- Create password reset attempts table
CREATE TABLE IF NOT EXISTS password_reset_attempts (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(45)
);

-- Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_reset_attempts_email_time 
ON password_reset_attempts(email, attempted_at);

-- Add comment for documentation
COMMENT ON TABLE password_reset_attempts IS 'Tracks password reset attempts for rate limiting';