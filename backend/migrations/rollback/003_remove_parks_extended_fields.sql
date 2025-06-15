-- Rollback script for 003_add_parks_extended_fields.sql

-- Remove NYC-specific fields from dog_parks table
ALTER TABLE dog_parks
DROP COLUMN IF EXISTS website,
DROP COLUMN IF EXISTS phone,
DROP COLUMN IF EXISTS rating,
DROP COLUMN IF EXISTS review_count,
DROP COLUMN IF EXISTS surface_type,
DROP COLUMN IF EXISTS has_seating,
DROP COLUMN IF EXISTS zipcode,
DROP COLUMN IF EXISTS borough;