-- Add NYC enrichment fields to dog_parks table
-- These fields support the enhanced park data from NYC dog runs

ALTER TABLE dog_parks
ADD COLUMN IF NOT EXISTS website VARCHAR(500),
ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS rating DECIMAL(2,1),
ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS surface_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS has_seating BOOLEAN,
ADD COLUMN IF NOT EXISTS zipcode VARCHAR(10),
ADD COLUMN IF NOT EXISTS borough VARCHAR(20);

-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS idx_dog_parks_borough ON dog_parks(borough);
CREATE INDEX IF NOT EXISTS idx_dog_parks_zipcode ON dog_parks(zipcode);
CREATE INDEX IF NOT EXISTS idx_dog_parks_rating ON dog_parks(rating);

-- Add constraints for valid values
DO $$ 
BEGIN
    -- Add rating constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_rating_range'
    ) THEN
        ALTER TABLE dog_parks ADD CONSTRAINT check_rating_range 
        CHECK (rating IS NULL OR (rating >= 1.0 AND rating <= 5.0));
    END IF;
    
    -- Add surface type constraint
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_surface_type'
    ) THEN
        ALTER TABLE dog_parks ADD CONSTRAINT check_surface_type 
        CHECK (surface_type IS NULL OR surface_type IN (
            'Natural', 'Synthetic', 'Concrete', 'Sand', 'Asphalt', 
            'Gravel', 'Wood Chips', 'Rubber', 'Mixed'
        ));
    END IF;
    
    -- Add borough constraint for NYC
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_borough'
    ) THEN
        ALTER TABLE dog_parks ADD CONSTRAINT check_borough 
        CHECK (borough IS NULL OR borough IN (
            'Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island',
            'Westchester', 'Other'
        ));
    END IF;
END $$;

-- Add helpful comments
COMMENT ON COLUMN dog_parks.rating IS 'Average rating 1.0-5.0 from Google/Yelp';
COMMENT ON COLUMN dog_parks.review_count IS 'Number of reviews contributing to rating';
COMMENT ON COLUMN dog_parks.surface_type IS 'Ground surface material in the dog run';
COMMENT ON COLUMN dog_parks.has_seating IS 'Whether benches/seating are available';
COMMENT ON COLUMN dog_parks.borough IS 'NYC borough or surrounding area';