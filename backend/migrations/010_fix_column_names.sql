-- Migration: Fix column names to match application code
-- This migration captures manual schema changes that were made to the development database
-- to ensure staging and production databases stay in sync with the codebase

-- Fix checkins table: rename dogs_present to dogs
DO $$
BEGIN
    -- Check if the old column exists and new column doesn't
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'checkins' 
        AND column_name = 'dogs_present'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'checkins' 
        AND column_name = 'dogs'
    ) THEN
        ALTER TABLE checkins RENAME COLUMN dogs_present TO dogs;
        RAISE NOTICE 'Renamed checkins.dogs_present to checkins.dogs';
    ELSE
        RAISE NOTICE 'Skipping checkins column rename - already applied';
    END IF;
END $$;

-- Fix friendships table: rename requester_id to user_id and addressee_id to friend_id
DO $$
BEGIN
    -- Rename requester_id to user_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'friendships' 
        AND column_name = 'requester_id'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'friendships' 
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE friendships RENAME COLUMN requester_id TO user_id;
        RAISE NOTICE 'Renamed friendships.requester_id to friendships.user_id';
    ELSE
        RAISE NOTICE 'Skipping friendships.requester_id rename - already applied';
    END IF;

    -- Rename addressee_id to friend_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'friendships' 
        AND column_name = 'addressee_id'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'friendships' 
        AND column_name = 'friend_id'
    ) THEN
        ALTER TABLE friendships RENAME COLUMN addressee_id TO friend_id;
        RAISE NOTICE 'Renamed friendships.addressee_id to friendships.friend_id';
    ELSE
        RAISE NOTICE 'Skipping friendships.addressee_id rename - already applied';
    END IF;
END $$;

-- Update any indexes that might reference the old column names
-- The unique constraint will automatically be updated with the column rename
-- but we should verify the index names are consistent

-- Log the final state for verification
DO $$
DECLARE
    checkins_cols TEXT;
    friendships_cols TEXT;
BEGIN
    -- Get current column names for checkins
    SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
    INTO checkins_cols
    FROM information_schema.columns
    WHERE table_name = 'checkins'
    AND table_schema = 'public';
    
    -- Get current column names for friendships
    SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
    INTO friendships_cols
    FROM information_schema.columns
    WHERE table_name = 'friendships'
    AND table_schema = 'public';
    
    RAISE NOTICE 'Final checkins columns: %', checkins_cols;
    RAISE NOTICE 'Final friendships columns: %', friendships_cols;
END $$;