-- BarkPark Complete Database Schema
-- This is a consolidated schema file for Railway deployment
-- It creates all tables with their final structure in one go

-- Enable PostGIS extension for geospatial functionality
CREATE EXTENSION IF NOT EXISTS postgis;

-- Users table with privacy settings
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_image_url VARCHAR(500),
    is_searchable BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dogs table
CREATE TABLE dogs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    breed VARCHAR(100),
    age INTEGER,
    weight DECIMAL(5,2),
    description TEXT,
    profile_image_url VARCHAR(500),
    is_friendly BOOLEAN DEFAULT true,
    is_vaccinated BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dog parks table with NYC enrichment fields
CREATE TABLE dog_parks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    address VARCHAR(500) NOT NULL,
    location GEOMETRY(POINT, 4326) NOT NULL,
    amenities TEXT[],
    rules TEXT,
    hours_open TIME,
    hours_close TIME,
    admin_user_id INTEGER REFERENCES users(id),
    website VARCHAR(500),
    phone VARCHAR(20),
    rating DECIMAL(2,1),
    review_count INTEGER,
    surface_type VARCHAR(50),
    has_seating BOOLEAN,
    zipcode VARCHAR(10),
    borough VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Friendships table
CREATE TABLE friendships (
    id SERIAL PRIMARY KEY,
    requester_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    addressee_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, declined
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(requester_id, addressee_id)
);

-- Check-ins table
CREATE TABLE checkins (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    dog_park_id INTEGER REFERENCES dog_parks(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checked_out_at TIMESTAMP,
    dogs_present INTEGER[] -- array of dog IDs that came along
);

-- Messages table
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    recipient_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Park notices table
CREATE TABLE park_notices (
    id SERIAL PRIMARY KEY,
    dog_park_id INTEGER REFERENCES dog_parks(id) ON DELETE CASCADE,
    admin_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migration tracking table
CREATE TABLE schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_searchable ON users(is_searchable) WHERE is_searchable = true;
CREATE INDEX idx_dogs_user_id ON dogs(user_id);
CREATE INDEX idx_dog_parks_location ON dog_parks USING GIST(location);
CREATE INDEX idx_dog_parks_borough ON dog_parks(borough);
CREATE INDEX idx_dog_parks_zipcode ON dog_parks(zipcode);
CREATE INDEX idx_dog_parks_rating ON dog_parks(rating);
CREATE INDEX idx_friendships_users ON friendships(requester_id, addressee_id);
CREATE INDEX idx_checkins_user_park ON checkins(user_id, dog_park_id);
CREATE INDEX idx_checkins_active ON checkins(dog_park_id) WHERE checked_out_at IS NULL;
CREATE INDEX idx_messages_conversation ON messages(sender_id, recipient_id);
CREATE INDEX idx_park_notices_active ON park_notices(dog_park_id) WHERE is_active = true;

-- Add helpful comments
COMMENT ON COLUMN users.is_searchable IS 'Controls whether user appears in search results for other users';
COMMENT ON TABLE schema_migrations IS 'Tracks which migrations have been applied to prevent re-running';

-- Record this migration
INSERT INTO schema_migrations (version) VALUES ('001_create_schema');