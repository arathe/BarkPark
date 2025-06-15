-- Add extended fields to dogs table
-- This migration adds all the modern dog profile fields

-- Add new columns
ALTER TABLE dogs 
ADD COLUMN IF NOT EXISTS birthday DATE,
ADD COLUMN IF NOT EXISTS gender VARCHAR(20) DEFAULT 'unknown',
ADD COLUMN IF NOT EXISTS size_category VARCHAR(20) DEFAULT 'medium',
ADD COLUMN IF NOT EXISTS energy_level VARCHAR(20) DEFAULT 'medium',
ADD COLUMN IF NOT EXISTS friendliness_dogs INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS friendliness_people INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS training_level VARCHAR(20) DEFAULT 'basic',
ADD COLUMN IF NOT EXISTS favorite_activities JSON DEFAULT '[]'::json,
ADD COLUMN IF NOT EXISTS is_spayed_neutered BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS special_needs TEXT,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS gallery_images JSON DEFAULT '[]'::json;

-- If there's an old 'description' column, migrate its data to 'bio'
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'dogs' 
        AND column_name = 'description'
    ) THEN
        -- Copy data from description to bio if bio is empty
        UPDATE dogs 
        SET bio = description 
        WHERE bio IS NULL 
        AND description IS NOT NULL;
        
        -- Drop the old column
        ALTER TABLE dogs DROP COLUMN description;
    END IF;
END $$;

-- If there's an old 'is_friendly' boolean column, convert it
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'dogs' 
        AND column_name = 'is_friendly'
        AND data_type = 'boolean'
    ) THEN
        -- Convert boolean to integer scale (true = 4, false = 2)
        UPDATE dogs 
        SET friendliness_dogs = CASE 
            WHEN is_friendly = true THEN 4 
            ELSE 2 
        END;
        
        -- Drop the old column
        ALTER TABLE dogs DROP COLUMN is_friendly;
    END IF;
END $$;

-- If there's an old 'age' column, drop it (we calculate from birthday)
ALTER TABLE dogs DROP COLUMN IF EXISTS age;

-- Add constraints for valid values
DO $$ 
BEGIN
    -- Add gender constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_gender'
    ) THEN
        ALTER TABLE dogs ADD CONSTRAINT check_gender 
        CHECK (gender IN ('male', 'female', 'unknown'));
    END IF;
    
    -- Add size category constraint
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_size_category'
    ) THEN
        ALTER TABLE dogs ADD CONSTRAINT check_size_category 
        CHECK (size_category IN ('small', 'medium', 'large'));
    END IF;
    
    -- Add energy level constraint
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_energy_level'
    ) THEN
        ALTER TABLE dogs ADD CONSTRAINT check_energy_level 
        CHECK (energy_level IN ('low', 'medium', 'high'));
    END IF;
    
    -- Add training level constraint
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_training_level'
    ) THEN
        ALTER TABLE dogs ADD CONSTRAINT check_training_level 
        CHECK (training_level IN ('puppy', 'basic', 'advanced'));
    END IF;
    
    -- Add friendliness constraints
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_friendliness_dogs'
    ) THEN
        ALTER TABLE dogs ADD CONSTRAINT check_friendliness_dogs 
        CHECK (friendliness_dogs BETWEEN 1 AND 5);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_friendliness_people'
    ) THEN
        ALTER TABLE dogs ADD CONSTRAINT check_friendliness_people 
        CHECK (friendliness_people BETWEEN 1 AND 5);
    END IF;
END $$;

-- Add helpful comments
COMMENT ON COLUMN dogs.birthday IS 'Dog birth date - age calculated from this';
COMMENT ON COLUMN dogs.friendliness_dogs IS 'Scale 1-5: 1=aggressive, 3=neutral, 5=very friendly';
COMMENT ON COLUMN dogs.friendliness_people IS 'Scale 1-5: 1=aggressive, 3=neutral, 5=very friendly';
COMMENT ON COLUMN dogs.favorite_activities IS 'JSON array of activity strings';
COMMENT ON COLUMN dogs.gallery_images IS 'JSON array of image URLs';