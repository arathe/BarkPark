#!/bin/bash

# BarkPark Local Database Setup Script
# This script sets up a local PostgreSQL database that mirrors production
# Works without PostGIS by using lat/lng columns

echo "🚀 BarkPark Local Database Setup"
echo "================================"

# Configuration
DB_USER="${DB_USER:-austinrathe}"
DB_NAME="${DB_NAME:-barkpark}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

# PostgreSQL commands path (adjust if needed)
PSQL="/usr/local/opt/postgresql@15/bin/psql"
CREATEDB="/usr/local/opt/postgresql@15/bin/createdb"
DROPDB="/usr/local/opt/postgresql@15/bin/dropdb"

echo "📋 Configuration:"
echo "   Database: $DB_NAME"
echo "   User: $DB_USER"
echo "   Host: $DB_HOST:$DB_PORT"
echo ""

# Step 1: Drop existing database if requested
if [ "$1" = "--fresh" ]; then
    echo "⚠️  Dropping existing database..."
    $DROPDB -U $DB_USER -h $DB_HOST -p $DB_PORT $DB_NAME 2>/dev/null || true
fi

# Step 2: Create database if it doesn't exist
echo "📦 Creating database..."
$CREATEDB -U $DB_USER -h $DB_HOST -p $DB_PORT $DB_NAME 2>/dev/null || echo "   Database already exists"

# Step 3: Create schema without PostGIS
echo "🏗️  Creating schema..."
$PSQL -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME <<'EOF'
-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_image_url VARCHAR(500),
    is_searchable BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dogs table with extended fields
CREATE TABLE IF NOT EXISTS dogs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    breed VARCHAR(100),
    weight DECIMAL(5,2),
    profile_image_url VARCHAR(500),
    is_vaccinated BOOLEAN DEFAULT false,
    birthday DATE,
    gender VARCHAR(20),
    is_neutered BOOLEAN DEFAULT false,
    personality_traits TEXT[],
    bio TEXT,
    energy_level VARCHAR(20),
    size_category VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dog parks table with lat/lng
CREATE TABLE IF NOT EXISTS dog_parks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    address VARCHAR(500) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    amenities TEXT[],
    rules TEXT,
    hours_open TIME,
    hours_close TIME,
    zipcode VARCHAR(10),
    borough VARCHAR(50),
    website VARCHAR(500),
    phone VARCHAR(20),
    rating DECIMAL(3,2),
    review_count INTEGER DEFAULT 0,
    surface_type VARCHAR(50),
    has_seating BOOLEAN DEFAULT false,
    admin_user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Friendships table
CREATE TABLE IF NOT EXISTS friendships (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    friend_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, friend_id),
    CHECK (user_id != friend_id)
);

-- Check-ins table
CREATE TABLE IF NOT EXISTS checkins (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    dog_park_id INTEGER REFERENCES dog_parks(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checked_out_at TIMESTAMP,
    dogs INTEGER[],
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT
);

-- Activity logs table
CREATE TABLE IF NOT EXISTS activity_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id INTEGER,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Social feed tables
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    post_type VARCHAR(20) NOT NULL DEFAULT 'status',
    visibility VARCHAR(20) DEFAULT 'friends',
    check_in_id INTEGER REFERENCES checkins(id),
    shared_post_id INTEGER REFERENCES posts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS post_media (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    media_type VARCHAR(10) NOT NULL,
    media_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    width INTEGER,
    height INTEGER,
    duration INTEGER,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS post_likes (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    reaction_type VARCHAR(20) DEFAULT 'like',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id)
);

CREATE TABLE IF NOT EXISTS post_comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    parent_comment_id INTEGER REFERENCES post_comments(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    data JSONB NOT NULL,
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migration tracking table
CREATE TABLE IF NOT EXISTS schema_migrations (
    id VARCHAR(255) PRIMARY KEY,
    checksum VARCHAR(64) NOT NULL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_dog_parks_location ON dog_parks (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_dogs_user_id ON dogs(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_checkins_user_id ON checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_checkins_dog_park_id ON checkins(dog_park_id);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
\$\$ language 'plpgsql';

-- Create triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dogs_updated_at BEFORE UPDATE ON dogs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dog_parks_updated_at BEFORE UPDATE ON dog_parks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_friendships_updated_at BEFORE UPDATE ON friendships
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_post_comments_updated_at BEFORE UPDATE ON post_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF

echo "✅ Schema created"

# Step 4: Mark migrations as completed
echo "📝 Recording migrations..."
$PSQL -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME <<'EOF'
INSERT INTO schema_migrations (id, checksum) VALUES 
    ('001_create_initial_schema', 'local_setup'),
    ('002_add_dogs_extended_fields', 'local_setup'),
    ('003_add_parks_extended_fields', 'local_setup'),
    ('004_add_user_privacy', 'local_setup'),
    ('007_add_social_feed', 'local_setup')
ON CONFLICT (id) DO NOTHING;
EOF

echo "✅ Migrations recorded"

# Step 5: Get park data from Railway if requested
if [ "$2" = "--import-parks" ]; then
    echo ""
    echo "📥 Importing park data from production..."
    echo "⚠️  This requires the Railway CLI and production access"
    echo "   Run: railway run npm run db:export-parks"
    echo "   Then import the exported file"
else
    echo ""
    echo "📊 Database Summary:"
    $PSQL -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) || ' dog parks' FROM dog_parks;"
    $PSQL -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT COUNT(*) || ' users' FROM users;"
    
    echo ""
    echo "✅ Local database setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. To seed park data, run: cd backend && node scripts/seed-parks-local.js"
    echo "2. Start the backend: cd backend && npm run dev"
    echo "3. Update iOS app to use http://localhost:3000/api"
fi