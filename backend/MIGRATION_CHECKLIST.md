# BarkPark Database Migration Checklist

This checklist ensures database schema consistency between local development and production environments.

## Pre-Deployment Migration Checklist

### 1. Local Development
- [ ] Run migration status check: `npm run db:migrate:status`
- [ ] Apply any pending migrations: `npm run db:migrate --seed`
- [ ] Verify schema is complete: `npm run db:migrate:verify`
- [ ] Test all API endpoints locally
- [ ] Check schema validation endpoint: `curl localhost:3000/api/schema/validate`

### 2. Before Railway Deployment
- [ ] Commit all migration files to git
- [ ] Review migration files for syntax errors
- [ ] Ensure migration files are numbered sequentially
- [ ] Check that new migrations have unique IDs
- [ ] Verify migrations are idempotent (safe to run multiple times)

### 3. Production Migration
```bash
# Connect to Railway project
railway link

# Check current production schema
railway run npm run db:migrate:status

# Run migrations on production
railway run npm run db:migrate --seed

# Verify production schema
railway run npm run db:migrate:verify
```

### 4. Post-Migration Verification
- [ ] Test production health endpoint
- [ ] Verify schema validation: `curl https://barkpark-production.up.railway.app/api/schema/validate`
- [ ] Test critical API endpoints (auth, dogs, parks)
- [ ] Check Railway logs for any errors
- [ ] Compare schemas: `curl https://barkpark-production.up.railway.app/api/schema/compare`

## Migration System Overview

### Unified Migration System
- **Location**: `/backend/scripts/unified-migrate.js`
- **Migration Files**: `/backend/migrations/00X_*.sql`
- **Tracking Table**: `schema_migrations`

### Migration Commands
```bash
# Run schema migrations only
npm run db:migrate

# Run migrations with seed data
npm run db:migrate:seed

# Check migration status
npm run db:migrate:status

# Verify schema integrity
npm run db:migrate:verify

# Force re-run migrations
npm run db:migrate:force
```

### Migration File Naming Convention
```
001_create_initial_schema.sql     # Base tables
002_add_dogs_extended_fields.sql  # Dog profile enhancements
003_add_parks_extended_fields.sql # NYC park fields
004_add_user_privacy.sql          # Privacy settings
005_seed_initial_parks.sql        # 12 original parks
006_seed_nyc_parks.sql            # 91 NYC dog runs
```

## Common Issues and Solutions

### Schema Mismatch
**Symptom**: API errors like "column does not exist"
**Solution**: 
1. Run `npm run db:migrate:status` to check missing migrations
2. Apply migrations with `npm run db:migrate`
3. Use schema validation endpoint to verify

### Migration Already Applied
**Symptom**: Migration skipped with "already applied" message
**Solution**: 
- Normal behavior - migrations track completion
- Use `--force` flag only if migration was modified

### Production Migration Failed
**Symptom**: Railway deployment works but API fails
**Solution**:
1. Check Railway logs for migration errors
2. Use admin endpoints to diagnose schema
3. Run migrations manually via Railway CLI

## Emergency Procedures

### Rollback Migration
Currently not automated. To rollback:
1. Manually reverse schema changes via SQL
2. Remove entry from `schema_migrations` table
3. Fix migration file
4. Re-run migration

### Schema Comparison
Use the schema comparison endpoint to diagnose differences:
```bash
# Local schema
curl localhost:3000/api/schema/compare > local-schema.json

# Production schema  
curl https://barkpark-production.up.railway.app/api/schema/compare > prod-schema.json

# Compare files to find differences
```

## Best Practices

1. **Always Test Locally First**: Run migrations on local database before production
2. **Use IF NOT EXISTS**: Make migrations idempotent 
3. **No Data Loss**: Never drop columns without data backup
4. **Document Changes**: Update CLAUDE.md with migration notes
5. **Monitor After Deploy**: Check logs and test endpoints after migration

## Migration Log

Track production migrations here:

| Date | Migration ID | Description | Status |
|------|--------------|-------------|---------|
| 2025-06-14 | fix-dogs-columns | Emergency fix for dogs table | ✅ Applied via admin endpoint |
| TBD | 001-006 | Unified migration system | ⏳ Pending |