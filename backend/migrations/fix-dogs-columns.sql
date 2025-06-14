-- Simple migration to add missing columns to dogs table
-- This handles the case where the table exists but is missing new columns

-- Add birthday column if it doesn't exist
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS birthday DATE;

-- Add other missing columns
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS gender VARCHAR(20) DEFAULT 'unknown';
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS size_category VARCHAR(20) DEFAULT 'medium';
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS energy_level VARCHAR(20) DEFAULT 'medium';
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS friendliness_dogs INTEGER DEFAULT 3;
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS friendliness_people INTEGER DEFAULT 3;
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS training_level VARCHAR(20) DEFAULT 'basic';
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS favorite_activities JSON DEFAULT '[]';
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS is_spayed_neutered BOOLEAN DEFAULT false;
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS special_needs TEXT;
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE dogs ADD COLUMN IF NOT EXISTS gallery_images JSON DEFAULT '[]';