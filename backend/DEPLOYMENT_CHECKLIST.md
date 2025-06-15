# Deployment Checklist

Use this checklist before every deployment to prevent database schema mismatches and other issues.

## Pre-Deployment Checks

### 1. Local Development Checks
- [ ] Run `npm run db:migrate:status` to check local migration status
- [ ] Run `npm test` to ensure all tests pass
- [ ] Check for any uncommitted migration files

### 2. Schema Comparison
- [ ] Run `npm run db:schema:compare` to compare local vs production schemas
- [ ] Review any differences and determine if migrations are needed
- [ ] If differences exist, ensure migration files are created

### 3. Migration Validation
- [ ] Ensure all new migrations follow naming convention: `XXX_description.sql`
- [ ] Verify rollback scripts exist for new migrations in `migrations/rollback/`
- [ ] Test migrations locally: `npm run db:migrate`
- [ ] Test rollback locally (on test data): `psql $DATABASE_URL -f migrations/rollback/XXX_*.sql`

### 4. Code Review
- [ ] All migration files reviewed by another developer
- [ ] Model changes match migration schema changes
- [ ] API endpoints tested with new schema

## Deployment Steps

### 1. Pre-Deployment
- [ ] Create database backup: `pg_dump $PRODUCTION_DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql`
- [ ] Announce deployment in team channel
- [ ] Set up monitoring for errors

### 2. Deploy to Staging (if available)
- [ ] Push to staging branch
- [ ] Verify migrations run automatically
- [ ] Test all critical paths
- [ ] Run `npm run db:migrate:verify` on staging

### 3. Deploy to Production
- [ ] Merge to main branch
- [ ] Monitor Railway deployment logs
- [ ] Verify migrations ran: Check Railway logs for "Migration completed"
- [ ] Run `npm run db:schema:compare` to confirm schemas match

## Post-Deployment Verification

### 1. Immediate Checks (First 5 minutes)
- [ ] Check server health endpoint: `curl https://barkpark-production.up.railway.app/api/health`
- [ ] Test authentication: Login with test account
- [ ] Test critical endpoints: Create a dog, view parks, etc.
- [ ] Monitor error logs for 500 errors

### 2. Extended Monitoring (First hour)
- [ ] Check error rates in logs
- [ ] Verify database connection pool stability
- [ ] Test all major user flows
- [ ] Check performance metrics

### 3. Schema Verification
- [ ] Run `npm run db:migrate:status` against production
- [ ] Compare with local: `npm run db:schema:compare`
- [ ] Document any manual changes made

## Rollback Procedures

If issues are discovered:

### 1. Quick Rollback (< 5 minutes since deploy)
1. Redeploy previous version in Railway
2. Run rollback migration if schema changed: `psql $DATABASE_URL -f migrations/rollback/XXX_*.sql`
3. Verify system stability

### 2. Complex Rollback (> 5 minutes or with data changes)
1. Assess impact of rolling back (user data created with new schema?)
2. Create data preservation strategy if needed
3. Execute rollback with data migration plan
4. Restore from backup if necessary

## Emergency Contacts

- **Database Admin**: [Contact info]
- **Railway Support**: [Support channel]
- **On-Call Engineer**: [Rotation schedule]

## Common Issues & Solutions

### Schema Mismatch Detected
1. Run diagnostic endpoint: `curl https://barkpark-production.up.railway.app/api/diagnostic/check`
2. Compare migration status between environments
3. Use admin endpoint to run missing migrations (with ADMIN_KEY)

### Migration Failed to Run
1. Check Railway logs for migration errors
2. Verify DATABASE_URL is set correctly
3. Run migration manually via Railway CLI: `railway run npm run db:migrate`

### Connection Pool Exhaustion
1. Check current connections: Query pg_stat_activity
2. Restart Railway service if needed
3. Adjust pool settings in database.js

## Notes

- Always prefer automated migrations over manual SQL execution
- Document any manual interventions in CLAUDE.md
- Keep staging environment in sync with production schema
- Review this checklist quarterly and update as needed