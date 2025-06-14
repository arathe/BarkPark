-- Extend dog_parks table with NYC dog runs data fields
-- Run this before importing NYC dog runs data

ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS website VARCHAR(500);
ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS phone VARCHAR(20);  
ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS rating DECIMAL(2,1);
ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS review_count INTEGER;
ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS surface_type VARCHAR(50);
ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS has_seating BOOLEAN;
ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS zipcode VARCHAR(10);
ALTER TABLE dog_parks ADD COLUMN IF NOT EXISTS borough VARCHAR(20);

-- Add index for common queries
CREATE INDEX IF NOT EXISTS idx_dog_parks_borough ON dog_parks(borough);
CREATE INDEX IF NOT EXISTS idx_dog_parks_zipcode ON dog_parks(zipcode);
CREATE INDEX IF NOT EXISTS idx_dog_parks_rating ON dog_parks(rating);