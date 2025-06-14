-- Clean up old columns from dogs table
-- Remove columns that are no longer used after migration

-- Drop old columns if they exist
ALTER TABLE dogs DROP COLUMN IF EXISTS age;
ALTER TABLE dogs DROP COLUMN IF EXISTS description;
ALTER TABLE dogs DROP COLUMN IF EXISTS is_friendly;