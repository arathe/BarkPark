-- Rollback script for 001_create_initial_schema.sql
-- WARNING: This will delete all data!

-- Drop tables in reverse order of creation (due to foreign key constraints)
DROP TABLE IF EXISTS check_ins CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS dogs CASCADE;
DROP TABLE IF EXISTS dog_parks CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop any custom types or extensions
DROP TYPE IF EXISTS friendship_status CASCADE;