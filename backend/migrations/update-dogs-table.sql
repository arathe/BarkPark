-- Update dogs table with comprehensive profile fields
-- Run this script to add new columns to existing dogs table

-- Add new columns if they don't exist
ALTER TABLE dogs 
ADD COLUMN IF NOT EXISTS birthday DATE,
ADD COLUMN IF NOT EXISTS gender VARCHAR(20) DEFAULT 'unknown',
ADD COLUMN IF NOT EXISTS size_category VARCHAR(20) DEFAULT 'medium',
ADD COLUMN IF NOT EXISTS energy_level VARCHAR(20) DEFAULT 'medium',
ADD COLUMN IF NOT EXISTS friendliness_dogs INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS friendliness_people INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS training_level VARCHAR(20) DEFAULT 'basic',
ADD COLUMN IF NOT EXISTS favorite_activities JSON DEFAULT '[]',
ADD COLUMN IF NOT EXISTS is_spayed_neutered BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS special_needs TEXT,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS gallery_images JSON DEFAULT '[]';

-- Rename existing columns to match new naming convention
-- ALTER TABLE dogs RENAME COLUMN description TO bio;
ALTER TABLE dogs RENAME COLUMN is_friendly TO friendliness_dogs_old;

-- Update friendliness_dogs from boolean to integer scale
UPDATE dogs SET friendliness_dogs = CASE 
  WHEN friendliness_dogs_old = true THEN 4 
  ELSE 2 
END WHERE friendliness_dogs IS NULL;

-- Drop the old boolean column
ALTER TABLE dogs DROP COLUMN IF EXISTS friendliness_dogs_old;

-- Remove age column since we'll calculate it from birthday
ALTER TABLE dogs DROP COLUMN IF EXISTS age;

-- Add constraints for enum-like fields
ALTER TABLE dogs ADD CONSTRAINT check_gender 
  CHECK (gender IN ('male', 'female', 'unknown'));

ALTER TABLE dogs ADD CONSTRAINT check_size_category 
  CHECK (size_category IN ('small', 'medium', 'large'));

ALTER TABLE dogs ADD CONSTRAINT check_energy_level 
  CHECK (energy_level IN ('low', 'medium', 'high'));

ALTER TABLE dogs ADD CONSTRAINT check_training_level 
  CHECK (training_level IN ('puppy', 'basic', 'advanced'));

ALTER TABLE dogs ADD CONSTRAINT check_friendliness_dogs 
  CHECK (friendliness_dogs BETWEEN 1 AND 5);

ALTER TABLE dogs ADD CONSTRAINT check_friendliness_people 
  CHECK (friendliness_people BETWEEN 1 AND 5);