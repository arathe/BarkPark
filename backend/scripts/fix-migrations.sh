#!/bin/bash

# Script to clean up duplicate and improperly named migration files

echo "🧹 Cleaning up migration files..."

cd /Users/austinrathe/Documents/Developer/BarkPark/backend/migrations

# Remove duplicate files (keeping the ones referenced in unified-migrate.js)
echo "Removing duplicate migration files..."

# These are the duplicates not used in unified-migrate.js
rm -f 001_create_schema.sql
rm -f 002_seed_data.sql
rm -f 003_nyc_dog_runs.sql
rm -f 004_complete_nyc_parks.sql

# Remove the improperly named file (since 004_add_user_privacy.sql already exists)
rm -f add-privacy-settings.sql

# Remove other non-numbered migration files that aren't part of the system
echo "Removing non-standard migration files..."
rm -f cleanup-dogs-columns.sql
rm -f extend-parks-schema.sql
rm -f fix-dogs-columns.sql
rm -f update-dogs-table-safe.sql
rm -f update-dogs-table.sql

echo "✅ Migration cleanup complete!"
echo ""
echo "Remaining migration files:"
ls -la *.sql | grep -E "^[0-9]{3}_"