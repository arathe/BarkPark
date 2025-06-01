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

Database uses PostgreSQL with PostGIS extension for geospatial queries.
Authentication uses JWT tokens with bcrypt password hashing.

## Development Commands

```bash
# Install dependencies
npm install

# Start development server with auto-reload
npm run dev

# Start production server
npm start

# Initialize database (run once)
createdb barkpark
psql -d barkpark -f scripts/init-db.sql
```

## Testing Authentication

Use the curl examples in README.md to test the auth endpoints:
- POST /api/auth/register
- POST /api/auth/login  
- GET /api/auth/me
- PUT /api/auth/me