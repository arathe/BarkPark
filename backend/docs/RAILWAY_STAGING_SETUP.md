# Railway Staging Environment Setup Guide

This guide walks you through setting up a staging environment on Railway for BarkPark to enable real iOS device testing.

## Prerequisites

- Railway account with existing BarkPark production service
- Access to Railway dashboard
- GitHub repository connected to Railway

## Step 1: Create Staging Service

### Option A: Duplicate Existing Service (Recommended)

1. **Log into Railway Dashboard**
   - Navigate to your BarkPark project
   
2. **Duplicate the Service**
   - Click on your existing `barkpark` service
   - Click the three dots menu (⋯) in the top right
   - Select "Duplicate Service"
   - Name it `barkpark-staging`

3. **Update Service Settings**
   - Click on the new `barkpark-staging` service
   - Go to Settings tab
   - Update the service name to clearly indicate staging

### Option B: Create New Service

1. **Add New Service**
   - In your Railway project, click "New Service"
   - Select "GitHub Repo"
   - Choose your BarkPark repository
   - Name it `barkpark-staging`

## Step 2: Configure PostgreSQL for Staging

1. **Add PostgreSQL Database**
   - Click "New Service" in your project
   - Select "Database" → "PostgreSQL"
   - Name it `barkpark-staging-db`

2. **Connect Database to Staging Service**
   - Click on `barkpark-staging` service
   - Go to "Variables" tab
   - Add: `DATABASE_URL` = (copy from the PostgreSQL service's connection string)

## Step 3: Configure Environment Variables

Copy all variables from production, but update these specifically for staging:

```bash
# Core Settings
NODE_ENV=staging
RAILWAY_ENVIRONMENT=staging

# Database (automatically set if you used Railway PostgreSQL)
DATABASE_URL=postgresql://...your-staging-db-url...

# JWT Secret (use a different one for staging)
JWT_SECRET=staging_jwt_secret_change_this_value

# Admin Key (different from production)
ADMIN_KEY=staging_admin_key_change_this

# Email Settings (can use same SMTP or different)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=your-staging-api-key
SMTP_FROM=staging@barkpark.us

# Application URL
APP_URL=https://barkpark-staging.up.railway.app

# AWS S3 (recommend separate bucket or folder)
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_REGION=us-east-2
S3_BUCKET_NAME=barkpark-images-staging
```

## Step 4: Configure Deployment Settings

1. **Set Deployment Branch**
   - In `barkpark-staging` service settings
   - Go to "Deploys" section
   - Set "Deployment Trigger" to `staging` branch
   - Enable "Automatic Deploys"

2. **Verify Build Settings**
   - Ensure `railway.json` settings are applied:
   ```json
   {
     "build": {
       "builder": "NIXPACKS"
     },
     "deploy": {
       "startCommand": "node scripts/start-with-migration.js",
       "healthcheckPath": "/health"
     }
   }
   ```

## Step 5: Create Staging Branch

In your local repository:

```bash
# Create staging branch from main
git checkout main
git pull origin main
git checkout -b staging
git push -u origin staging
```

## Step 6: Deploy to Staging

1. **Initial Deployment**
   - Railway should automatically deploy when you push to staging branch
   - Monitor the deployment logs in Railway dashboard

2. **Verify Deployment**
   ```bash
   # Check health endpoint
   curl https://barkpark-staging.up.railway.app/api/health
   
   # Check migration status
   curl https://barkpark-staging.up.railway.app/api/schema/validate
   ```

## Step 7: Configure Custom Domain (Optional)

1. **Add Custom Domain**
   - In service settings, go to "Networking"
   - Add custom domain like `staging.barkpark.us`
   - Configure DNS as instructed

## Step 8: Set Up Monitoring

1. **Enable Logs**
   - Logs are automatically available in Railway dashboard
   - Consider setting up log alerts for errors

2. **Health Checks**
   - Railway automatically monitors the `/health` endpoint
   - Set up additional monitoring if needed

## Deployment Workflow

### Deploying to Staging

```bash
# 1. Checkout staging branch
git checkout staging

# 2. Merge changes from your feature branch
git merge feature/your-feature

# 3. Push to trigger deployment
git push origin staging

# 4. Monitor deployment in Railway dashboard
```

### Promoting to Production

```bash
# 1. After testing in staging
git checkout main

# 2. Merge staging changes
git merge staging

# 3. Push to production
git push origin main
```

## Environment URLs

After setup, you'll have:

- **Local**: http://localhost:3000/api
- **Staging**: https://barkpark-staging.up.railway.app/api
- **Production**: https://barkpark-production.up.railway.app/api

## Troubleshooting

### Migrations Not Running

1. Check deployment logs for migration errors
2. Verify DATABASE_URL is set correctly
3. Manually run: `railway run npm run db:migrate --service=barkpark-staging`

### Environment Variables Missing

1. Double-check all required variables are set
2. Restart the service after adding variables
3. Check logs for specific missing variable errors

### Database Connection Issues

1. Verify PostgreSQL service is running
2. Check DATABASE_URL format
3. Ensure SSL settings match (rejectUnauthorized for production)

## Best Practices

1. **Keep Staging in Sync**
   - Regularly merge main → staging to prevent drift
   - Run same migrations in same order

2. **Test Everything in Staging First**
   - All features
   - All migrations
   - All configuration changes

3. **Use Separate Resources**
   - Different JWT secrets
   - Different S3 buckets/folders
   - Different email addresses

4. **Monitor Both Environments**
   - Set up alerts for both staging and production
   - Compare performance metrics
   - Track deployment success rates

## Next Steps

1. Update iOS app to support staging URL
2. Configure TestFlight for staging builds
3. Set up CI/CD pipeline for automated testing
4. Document staging-specific test accounts