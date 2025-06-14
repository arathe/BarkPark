-- Safe update dogs table migration that checks for existing columns and constraints
-- This handles both fresh and partially migrated databases

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

-- Handle the description -> bio rename if description exists
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'dogs' AND column_name = 'description') THEN
        ALTER TABLE dogs RENAME COLUMN description TO bio;
    END IF;
END $$;

-- Handle the is_friendly column if it exists
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'dogs' AND column_name = 'is_friendly') THEN
        -- Add temporary column for conversion
        ALTER TABLE dogs ADD COLUMN IF NOT EXISTS friendliness_dogs_old BOOLEAN;
        UPDATE dogs SET friendliness_dogs_old = is_friendly;
        
        -- Update friendliness_dogs from boolean to integer scale
        UPDATE dogs SET friendliness_dogs = CASE 
          WHEN friendliness_dogs_old = true THEN 4 
          ELSE 2 
        END WHERE friendliness_dogs_old IS NOT NULL;
        
        -- Drop the old columns
        ALTER TABLE dogs DROP COLUMN IF EXISTS is_friendly;
        ALTER TABLE dogs DROP COLUMN IF EXISTS friendliness_dogs_old;
    END IF;
END $$;

-- Remove age column if it exists (we'll calculate from birthday)
ALTER TABLE dogs DROP COLUMN IF EXISTS age;

-- Add constraints only if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_gender') THEN
        ALTER TABLE dogs ADD CONSTRAINT check_gender 
          CHECK (gender IN ('male', 'female', 'unknown'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_size_category') THEN
        ALTER TABLE dogs ADD CONSTRAINT check_size_category 
          CHECK (size_category IN ('small', 'medium', 'large'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_energy_level') THEN
        ALTER TABLE dogs ADD CONSTRAINT check_energy_level 
          CHECK (energy_level IN ('low', 'medium', 'high'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_training_level') THEN
        ALTER TABLE dogs ADD CONSTRAINT check_training_level 
          CHECK (training_level IN ('puppy', 'basic', 'advanced'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_friendliness_dogs') THEN
        ALTER TABLE dogs ADD CONSTRAINT check_friendliness_dogs 
          CHECK (friendliness_dogs BETWEEN 1 AND 5);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_friendliness_people') THEN
        ALTER TABLE dogs ADD CONSTRAINT check_friendliness_people 
          CHECK (friendliness_people BETWEEN 1 AND 5);
    END IF;
END $$;