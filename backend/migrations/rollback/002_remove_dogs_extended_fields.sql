-- Rollback script for 002_add_dogs_extended_fields.sql

-- Remove extended fields from dogs table
ALTER TABLE dogs
DROP COLUMN IF EXISTS energy_level,
DROP COLUMN IF EXISTS social_level,
DROP COLUMN IF EXISTS bio,
DROP COLUMN IF EXISTS favorite_activities,
DROP COLUMN IF EXISTS birthday,
DROP COLUMN IF EXISTS weight;