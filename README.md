# BarkPark Backend

Backend API for the BarkPark dog social network application.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Set up PostgreSQL database:
```bash
# Create database
createdb barkpark

# Run database initialization script
psql -d barkpark -f scripts/init-db.sql
```

3. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your database credentials
```

4. Start development server:
```bash
npm run dev
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user profile (requires JWT)
- `PUT /api/auth/me` - Update user profile (requires JWT)

### Dogs & Memberships
- `GET /api/dogs` - List dogs for the authenticated user. Responses now include an `owners` array describing active members and their roles.
- `GET /api/dogs/:id/members` - View active members and pending invitations for a dog you belong to.
- `POST /api/dogs/:id/members` - Invite a co-owner/viewer (by `userId` or email). Primary owners only.
- `POST /api/dogs/:id/members/:invitationId/respond` - Accept or decline an invitation using the emailed token.
- `PATCH /api/dogs/:id/members/:memberId` - Update a member's role (primary owners only).
- `DELETE /api/dogs/:id/members/:memberId` - Remove a member (primary owners only, at least one primary must remain).

Roles determine permissions: `primary_owner` can perform destructive actions and manage membership; `co_owner` can edit profiles and media; `viewer` has read-only access. Invitations remain `pending` until accepted or declined and are delivered via email with a tokenized link that callers must provide when responding.

### Testing Authentication

```bash
# Register a new user
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+1234567890"
  }'

# Login
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Get profile (use token from login response)
curl -X GET http://localhost:4000/api/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## PostGIS & Coordinate Fields

Park coordinates are stored in both the PostGIS `geography(Point, 4326)` column (`dog_parks.location`) and the legacy scalar columns (`latitude`, `longitude`). Keep these values in sync on writes: the geography column powers distance queries, while the scalars remain for clients that have not yet migrated to PostGIS-aware payloads. When running migrations locally, make sure the PostGIS extension is enabled so the geography column stays authoritative.
