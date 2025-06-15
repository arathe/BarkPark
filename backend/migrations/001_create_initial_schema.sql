-- BarkPark Initial Database Schema
-- Creates base tables and relationships
-- Note: This uses simple lat/lng columns instead of PostGIS for Railway compatibility

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dogs table (basic structure - extended fields added in migration 002)
CREATE TABLE IF NOT EXISTS dogs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    breed VARCHAR(100),
    weight DECIMAL(5,2),
    profile_image_url VARCHAR(500),
    is_vaccinated BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dog parks table (basic structure - NYC fields added in migration 003)
CREATE TABLE IF NOT EXISTS dog_parks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    address VARCHAR(500) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    amenities TEXT[],
    rules TEXT,
    hours_open TIME,
    hours_close TIME,
    admin_user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Friendships table
CREATE TABLE IF NOT EXISTS friendships (
    id SERIAL PRIMARY KEY,
    requester_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    addressee_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, declined
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(requester_id, addressee_id)
);

-- Check-ins table
CREATE TABLE IF NOT EXISTS checkins (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    dog_park_id INTEGER REFERENCES dog_parks(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checked_out_at TIMESTAMP,
    dogs_present INTEGER[] -- array of dog IDs that came along
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    recipient_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Park notices table
CREATE TABLE IF NOT EXISTS park_notices (
    id SERIAL PRIMARY KEY,
    dog_park_id INTEGER REFERENCES dog_parks(id) ON DELETE CASCADE,
    admin_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_dogs_user_id ON dogs(user_id);
CREATE INDEX IF NOT EXISTS idx_dog_parks_location ON dog_parks(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_friendships_users ON friendships(requester_id, addressee_id);
CREATE INDEX IF NOT EXISTS idx_checkins_user_park ON checkins(user_id, dog_park_id);
CREATE INDEX IF NOT EXISTS idx_checkins_active ON checkins(dog_park_id) WHERE checked_out_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(sender_id, recipient_id);
CREATE INDEX IF NOT EXISTS idx_park_notices_active ON park_notices(dog_park_id) WHERE is_active = true;