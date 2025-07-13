# BarkPark Deployment Workflow

This document describes the complete deployment workflow for BarkPark across all environments.

## Environment Overview

We use a three-environment setup:

1. **Local Development** → Your machine
2. **Staging** → Railway (TestFlight testing)
3. **Production** → Railway (App Store - future)

```
Developer Machine → GitHub → Railway Staging → Railway Production
     (local)        (git)      (auto-deploy)     (manual deploy)
```

## Workflow Stages

### 1. Local Development

**Setup:**
```bash
# Backend
cd backend
npm install
npm run dev

# iOS
# Update APIConfiguration with your IP
# Use "BarkPark (Local)" scheme
# Build and run
```

**Before committing:**
```bash
# Run tests
npm test

# Check for secrets
git status  # Ensure no .env files
git diff    # Review changes
```

### 2. Feature Development

**Create feature branch:**
```bash
git checkout -b feature/your-feature-name
```

**Development cycle:**
1. Write code
2. Test locally
3. Run backend tests: `npm test`
4. Test iOS app with local backend
5. Commit changes

**Commit guidelines:**
```bash
git add specific-files.js
git commit -m "feat: Add user notification preferences

- Add notification settings to user model
- Create API endpoints for updating preferences
- Add iOS UI for notification settings

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 3. Deploy to Staging

**Merge to staging branch:**
```bash
# Ensure tests pass
npm test

# Merge feature to staging
git checkout staging
git merge feature/your-feature-name
git push origin staging
```

**Automatic deployment:**
- Railway detects push to staging branch
- Runs migrations automatically
- Deploys new version
- Available at: https://barkpark-staging.up.railway.app

**Verify deployment:**
```bash
# Check health
curl https://barkpark-staging.up.railway.app/api/health

# Check migration status
./scripts/deploy-helper.sh status staging

# Monitor logs (if you have Railway CLI)
railway logs --service=barkpark-staging
```

### 4. iOS TestFlight Testing

**Build for TestFlight:**
1. Select "BarkPark (Staging)" scheme
2. Product → Archive
3. Distribute → App Store Connect → TestFlight
4. Upload build

**Test on real devices:**
- Install from TestFlight
- Test all features against staging backend
- Report issues

### 5. Production Deployment

**Prerequisites:**
- All tests pass in staging
- TestFlight testing complete
- No critical issues

**Deploy to production:**
```bash
# Merge staging to main
git checkout main
git merge staging
git push origin main

# Railway auto-deploys to production
```

**Post-deployment verification:**
```bash
# Check health
curl https://barkpark-production.up.railway.app/api/health

# Verify schema
npm run db:schema:compare -- --target=production

# Monitor for errors
# Check Railway dashboard logs
```

## Database Migration Workflow

### Creating Migrations

1. **Make schema changes locally**
2. **Create migration file:**
   ```bash
   # Create next numbered migration
   touch backend/migrations/010_your_migration.sql
   ```

3. **Write migration SQL:**
   ```sql
   -- migrations/010_add_user_preferences.sql
   BEGIN;
   
   ALTER TABLE users 
   ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{}';
   
   COMMIT;
   ```

4. **Create rollback script:**
   ```sql
   -- migrations/rollback/010_remove_user_preferences.sql
   BEGIN;
   
   ALTER TABLE users 
   DROP COLUMN IF EXISTS notification_preferences;
   
   COMMIT;
   ```

5. **Update migration runner:**
   - Add to migrations array in `unified-migrate.js`

### Testing Migrations

**Local testing:**
```bash
# Run migration
npm run db:migrate

# Verify
npm run db:migrate:status

# Test rollback (if needed)
psql $DATABASE_URL -f migrations/rollback/010_*.sql
```

**Staging testing:**
- Push to staging branch
- Migrations run automatically
- Verify in logs

## Environment-Specific Configurations

### Backend Environment Variables

**Local (.env):**
```
NODE_ENV=development
DATABASE_URL=postgresql://...
JWT_SECRET=local_secret
```

**Staging (Railway):**
```
NODE_ENV=staging
DATABASE_URL=<auto-provided>
JWT_SECRET=staging_secret
```

**Production (Railway):**
```
NODE_ENV=production
DATABASE_URL=<auto-provided>
JWT_SECRET=production_secret
```

### iOS Build Configurations

**Debug builds:**
- Can target any environment via scheme
- Use for development and testing

**Release builds:**
- Staging: Auto-selected for TestFlight
- Production: Future App Store builds

## Rollback Procedures

### Quick Rollback (< 5 minutes)

**Railway Dashboard:**
1. Go to deployments tab
2. Find last working deployment
3. Click "Redeploy"

### Database Rollback

**If schema changed:**
```bash
# Connect to affected environment
railway run psql $DATABASE_URL --service=barkpark-staging

# Run rollback
\i migrations/rollback/010_*.sql
```

### Git Rollback

**Last resort:**
```bash
git checkout main
git reset --hard <last-good-commit>
git push --force origin main
```

## Monitoring & Debugging

### Health Checks

**Endpoints to monitor:**
- `/api/health` - Basic health
- `/api/schema/validate` - Schema integrity
- `/api/diagnostic/check` - Detailed diagnostics

### Common Issues

**Migration failures:**
```bash
# Check migration status
railway run npm run db:migrate:status --service=barkpark-staging

# Run manually if needed
railway run npm run db:migrate --service=barkpark-staging
```

**iOS can't connect:**
1. Verify environment in Xcode console
2. Check backend health endpoint
3. Verify Railway deployment succeeded

**Schema drift:**
```bash
# Compare environments
npm run db:schema:compare -- --source=staging --target=production
```

## Best Practices

### Do's
- ✅ Always test in staging first
- ✅ Run migrations in order
- ✅ Keep staging close to production
- ✅ Monitor logs during deployment
- ✅ Use deployment helper script

### Don'ts
- ❌ Skip staging deployment
- ❌ Make manual database changes
- ❌ Deploy directly to production
- ❌ Ignore test failures
- ❌ Forget to update iOS environment

## Quick Reference

### Deployment Commands
```bash
# Deploy to staging
./scripts/deploy-helper.sh deploy staging

# Check status
./scripts/deploy-helper.sh status staging

# View rollback instructions
./scripts/deploy-helper.sh rollback
```

### Migration Commands
```bash
# Run migrations
npm run db:migrate

# Check status
npm run db:migrate:status

# Compare schemas
npm run db:schema:compare
```

### iOS Build Commands
```bash
# Clean build
Cmd+Shift+K

# Archive for TestFlight
Product → Archive

# Switch schemes
Ctrl+0 (zero)
```

## Emergency Contacts

- **On-call rotation**: [Your rotation]
- **Railway support**: [Support link]
- **iOS TestFlight**: [Apple support]

Remember: When in doubt, test in staging first!