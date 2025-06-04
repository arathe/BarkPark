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
**Current Status**: JWT auth system completed and tested

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
```

**Environment Variables**:
- Copy `.env.example` to `.env`
- Set `DB_USER` to your macOS username (not 'postgres')
- Leave `DB_PASSWORD` empty for local development
- JWT_SECRET is set for development

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

**API Endpoints**:
- `POST /api/auth/register` - Create new user account
- `POST /api/auth/login` - Authenticate and get JWT token
- `GET /api/auth/me` - Get current user profile (protected)
- `PUT /api/auth/me` - Update user profile (protected)

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
```

## Pending Features

- Dog profile CRUD operations
- Dog park geospatial queries (needs PostGIS)
- Friend connections and social features
- Real-time messaging with Socket.io
- Park administrator notices
- Image upload to AWS S3

## Database Notes

Currently using simplified schema without PostGIS due to installation complexity. Dog parks table uses `latitude/longitude` columns instead of `GEOMETRY` type. When PostGIS is installed later, migrate to use `scripts/init-db.sql` for proper geospatial support.

## Deployment

Repository: https://github.com/arathe/BarkPark
Ready for Railway/Render deployment with environment variable configuration.