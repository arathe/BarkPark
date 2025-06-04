# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BarkPark is a dog social network application consisting of:
- Node.js/Express backend API with PostgreSQL database
- iOS app frontend (to be built)
- Features: user auth, dog profiles, park finder, social messaging, check-ins

## Architecture

```
/config - Database connection and configuration
/models - Database models (User, Dog, DogPark, etc.)
/routes - API route handlers
/middleware - Authentication and validation middleware  
/scripts - Database initialization and utility scripts
```

**Database**: PostgreSQL with simplified schema (PostGIS not yet installed for geospatial)
**Authentication**: JWT tokens with bcrypt password hashing
**Image Storage**: AWS S3 for profile and gallery images
**Current Status**: JWT auth system and dog profiles completed and tested

## Environment Setup

**PostgreSQL Setup** (macOS with Homebrew):
```bash
# Install PostgreSQL 15
brew install postgresql@15
export PATH="/usr/local/opt/postgresql@15/bin:$PATH"

# Start service
brew services start postgresql@15

# Create database
createdb barkpark

# Initialize schema (use simple version for now)
psql -d barkpark -f scripts/init-db-simple.sql

# Update dogs table with comprehensive profile fields (run once)
psql -d barkpark -f scripts/update-dogs-table.sql
```

**Environment Variables**:
- Copy `.env.example` to `.env`
- Set `DB_USER` to your macOS username (not 'postgres')
- Leave `DB_PASSWORD` empty for local development
- JWT_SECRET is set for development
- AWS S3 credentials required for image uploads (set in .env)

## Development Commands

```bash
# Install dependencies
npm install

# Start development server with auto-reload
npm run dev

# Start production server
npm start

# Test server is running
curl http://localhost:3000/health
```

## Completed Features

**✅ JWT Authentication System**:
- User registration with validation
- Login with password verification
- JWT token generation and validation
- Protected routes with Bearer token auth
- Password hashing with bcrypt

**✅ Dog Profile System**:
- Complete CRUD operations for dog profiles
- Comprehensive profile data (personality, health, activities)
- AWS S3 image upload (profile photo + gallery)
- JSON field support for activities and gallery images
- Age calculation from birthday
- User ownership validation and security

**Authentication API Endpoints**:
- `POST /api/auth/register` - Create new user account
- `POST /api/auth/login` - Authenticate and get JWT token
- `GET /api/auth/me` - Get current user profile (protected)
- `PUT /api/auth/me` - Update user profile (protected)

**Dog Profile API Endpoints**:
- `GET /api/dogs` - Get all user's dogs
- `POST /api/dogs` - Create new dog profile
- `GET /api/dogs/:id` - Get specific dog
- `PUT /api/dogs/:id` - Update dog profile
- `DELETE /api/dogs/:id` - Delete dog profile
- `POST /api/dogs/:id/profile-image` - Upload profile photo
- `POST /api/dogs/:id/gallery` - Upload gallery photos (up to 5)
- `DELETE /api/dogs/:id/gallery` - Remove gallery photo

## Testing

```bash
# Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","firstName":"John","lastName":"Doe"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Access protected route (use token from login response)
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Create dog profile
curl -X POST http://localhost:3000/api/dogs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "name": "Buddy",
    "breed": "Golden Retriever",
    "birthday": "2020-05-15",
    "weight": 65.5,
    "gender": "male",
    "sizeCategory": "large",
    "energyLevel": "high",
    "friendlinessDogs": 5,
    "friendlinessPeople": 4,
    "trainingLevel": "advanced",
    "favoriteActivities": ["fetch", "swimming", "hiking"],
    "isVaccinated": true,
    "isSpayedNeutered": true,
    "bio": "Buddy is a friendly and energetic Golden Retriever"
  }'

# Get all dogs for user
curl -X GET http://localhost:3000/api/dogs \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Pending Features

- Dog park geospatial queries (needs PostGIS installation)
- Friend connections and social features
- Real-time messaging with Socket.io
- Park administrator notices
- Check-in functionality for dogs visiting parks

## Database Notes

**Schema Evolution:**
- Started with simplified schema (`scripts/init-db-simple.sql`)
- Dogs table enhanced with comprehensive profile fields (`scripts/update-dogs-table.sql`)
- Currently using `latitude/longitude` columns instead of PostGIS `GEOMETRY` type
- When PostGIS is installed later, migrate to use `scripts/init-db.sql` for proper geospatial support

**Dog Profile Data Structure:**
- Core: name, breed, birthday (age calculated), weight, gender, size
- Personality: energy level, friendliness scales (1-5), training level, activities (JSON array)
- Health: vaccination status, spay/neuter status, special needs
- Media: profile image URL, gallery images (JSON array)
- All images stored in AWS S3 with automatic cleanup on deletion

**Key Technical Notes:**
- PostgreSQL JSON fields require special parsing in Node.js model layer
- S3 integration handles file uploads with unique naming and organized folder structure
- Database constraints enforce valid enum values and friendliness scale ranges

## Deployment

Repository: https://github.com/arathe/BarkPark
Ready for Railway/Render deployment with environment variable configuration.