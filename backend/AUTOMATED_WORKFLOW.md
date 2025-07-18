# BarkPark Automated Workflow Guide

## Quick Start

You now have a fully automated workflow that prevents database sync issues and simplifies deployment!

### Daily Development

1. **Start your day:**
   ```bash
   cd backend
   npm run dev              # Start local backend
   npm run sync-check       # Verify DB is in sync (optional)
   ```

2. **Make changes directly on staging branch:**
   - No feature branches needed
   - iOS app automatically uses local backend in debug mode

3. **Commit your changes:**
   ```bash
   git add -p               # Review changes
   git commit -m "feat: your feature"
   ```
   
   The pre-commit hook automatically:
   - ✅ Checks database migration status
   - ✅ Runs database integrity tests
   - ✅ Scans for console.logs
   - ✅ Blocks .env and credential commits
   - ✅ Runs critical tests

4. **Deploy to staging:**
   ```bash
   npm run deploy-staging
   ```
   
   This single command:
   - Verifies you're on staging branch
   - Pulls latest changes
   - Runs all tests
   - Pushes to staging
   - Monitors deployment
   - Verifies health check

### Database Changes

When you need to modify the database schema:

1. Create migration file: `migrations/0XX_your_change.sql`
2. Add to `scripts/unified-migrate.js` migrations array
3. Run locally: `npm run db:migrate`
4. Commit as normal - pre-commit hook will verify

### Helper Commands

```bash
npm run sync-check       # Check DB sync status
npm run quick-check      # Run critical tests only
npm run monitor-staging  # Check staging health
npm run precommit        # Manually run pre-commit checks
```

### TestFlight Deployment

After staging is deployed and tested:

1. Open Xcode
2. Select "BarkPark (Staging)" scheme
3. Product → Archive
4. Upload to App Store Connect

### Troubleshooting

**Pre-commit hook fails:**
- Check the specific error message
- Usually means unapplied migrations: `npm run db:migrate`

**Deployment script fails:**
- Ensure you're on staging branch: `git checkout staging`
- Check test failures: `npm test`
- Verify Railway dashboard for deployment logs

**Health check fails after deployment:**
- May still be deploying - wait a minute and try: `npm run monitor-staging`
- Check Railway logs for errors

### Important Notes

- **Never make manual database changes** - always use migrations
- **Always work on staging branch** for this workflow
- **Pre-commit hook prevents most issues** automatically
- **One-command deployment** with `npm run deploy-staging`

That's it! Simple, automated, and safe. 🚀