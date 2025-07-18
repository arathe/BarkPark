# Staging Database - Dog Parks Data Import Guide

This guide helps you import the 103 dog parks into your Railway staging database.

## Prerequisites

You need the DATABASE_URL from your Railway staging environment. To get it:
1. Log into Railway dashboard
2. Click on your staging project
3. Click on the PostgreSQL database service
4. Go to the "Connect" tab
5. Copy the DATABASE_URL (it starts with `postgresql://`)

## Step 1: Check Current State

First, check what's currently in the staging database:

```bash
cd backend
DATABASE_URL="your-staging-database-url" node scripts/check-staging-data.js
```

This will show you:
- Current dog parks count
- Migration status
- Whether seed migrations have been run
- PostGIS installation status

## Step 2: Run Migrations with Seed Data

If the check shows 0 dog parks or missing seed migrations, run:

```bash
cd backend
DATABASE_URL="your-staging-database-url" node scripts/migrate-staging.js --seed
```

This will:
- Run all schema migrations (001-008)
- Run seed migrations (005 and 006) which add the 103 dog parks
- Update the migration tracking table

## Step 3: Verify Import

After running migrations, verify the data was imported:

```bash
DATABASE_URL="your-staging-database-url" node scripts/check-staging-data.js
```

You should see:
- 📊 Dog parks in database: 103
- ✅ 005_seed_initial_parks migration applied
- ✅ 006_seed_nyc_parks migration applied

## Alternative Method: Direct SQL Import

If migrations fail or you prefer a direct import:

### Export from local database:
```bash
pg_dump -h localhost -U austinrathe -d barkpark \
  --data-only \
  -t dog_parks \
  --no-owner \
  --no-privileges \
  > dog_parks_data.sql
```

### Import to staging:
```bash
psql "your-staging-database-url" < dog_parks_data.sql
```

## Troubleshooting

### Module Not Found Error
If you get "Cannot find module 'pg'" error, try these alternatives:

#### Option 1: Simple Node Script
```bash
cd backend
DATABASE_URL="postgresql://..." node check-staging-simple.js
```

#### Option 2: Direct SQL (no Node required)
```bash
cd backend
psql "postgresql://your-staging-url" -f check-staging.sql
```

#### Option 3: Manual psql commands
```bash
psql "postgresql://your-staging-url" -c "SELECT COUNT(*) FROM dog_parks;"
```

Common causes:
1. Not in backend directory (`cd backend`)
2. Node modules not installed (`npm install`)
3. Node version incompatibility (try `nvm use 20`)

### SSL Connection Error
If you get SSL errors, the scripts already handle this with `ssl: { rejectUnauthorized: false }`

### Migration Already Applied
If migrations show as already applied but parks are missing:
1. The seed migrations might have been skipped
2. Run with `--force` flag (be careful!): `DATABASE_URL="..." node scripts/migrate-staging.js --seed --force`

### PostGIS Not Installed
If PostGIS is missing, you'll need to enable it in Railway:
1. Connect to the database: `psql "your-staging-database-url"`
2. Run: `CREATE EXTENSION IF NOT EXISTS postgis;`

## Security Notes

- **NEVER** commit the DATABASE_URL to git
- Always use environment variables for database credentials
- The staging database URL is different from production

## Quick Commands Reference

```bash
# Check status
DATABASE_URL="..." node scripts/check-staging-data.js

# Run migrations with seeds
DATABASE_URL="..." node scripts/migrate-staging.js --seed

# Check migration status only
DATABASE_URL="..." node scripts/migrate-staging.js --status

# Verify schema integrity
DATABASE_URL="..." node scripts/migrate-staging.js --verify
```

## Expected Result

After successful import, your staging database should have:
- 12 parks near Piermont, NY (from migration 005)
- 91 NYC dog runs (from migration 006)
- Total: 103 dog parks

The iOS app should then be able to display all parks when connected to the staging API.