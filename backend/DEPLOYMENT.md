# BarkPark Backend Deployment Guide - Railway

This guide walks through deploying the BarkPark backend to Railway, a modern platform-as-a-service that simplifies deployment with automatic builds, database provisioning, and SSL certificates.

## Prerequisites

- Railway account (sign up at https://railway.app)
- GitHub account with the BarkPark repository
- AWS account for S3 image storage (or alternative storage solution)
- Railway CLI installed (optional): `npm install -g @railway/cli`

## Step 1: Create Railway Project

1. Log in to Railway Dashboard (https://railway.app/dashboard)
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Connect your GitHub account if not already connected
5. Select the BarkPark repository
6. Choose the `main` branch

## Step 2: Provision PostgreSQL Database

1. In your Railway project, click "New Service"
2. Select "Database" → "PostgreSQL"
3. Railway will automatically create a PostgreSQL instance
4. Click on the PostgreSQL service to view connection details

### Enable PostGIS Extension

Railway doesn't provide a built-in query interface. Use one of these methods:

#### Method 1: Using Railway CLI (Recommended)

1. Install Railway CLI if not already installed:
   ```bash
   npm install -g @railway/cli
   ```

2. Login and link your project:
   ```bash
   railway login
   railway link
   ```

3. Connect to the database:
   ```bash
   railway connect postgres
   ```

4. Once connected, run:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;
   ```

#### Method 2: Using psql with Connection String

1. Copy the DATABASE_URL from your Railway PostgreSQL Variables tab
2. Connect using psql:
   ```bash
   psql "$DATABASE_URL"
   ```
3. Run:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;
   ```

#### Method 3: Using a GUI Tool

1. Use a PostgreSQL GUI tool like:
   - TablePlus
   - pgAdmin
   - DBeaver
   - Postico (Mac)

2. Create a new connection using the credentials from Railway's Variables tab:
   - Host: From PGHOST variable
   - Port: From PGPORT variable (usually 5432)
   - Database: From PGDATABASE variable
   - Username: From PGUSER variable
   - Password: From PGPASSWORD variable
   - Enable SSL

3. Once connected, run:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;
   ```

## Step 3: Configure Environment Variables

In your Railway project settings, add the following environment variables:

### Required Variables

```bash
# JWT Configuration
JWT_SECRET=<generate-a-secure-random-string>
JWT_EXPIRES_IN=7d

# AWS S3 (for image uploads)
AWS_ACCESS_KEY_ID=<your-aws-access-key>
AWS_SECRET_ACCESS_KEY=<your-aws-secret>
AWS_REGION=us-east-1
S3_BUCKET_NAME=<your-s3-bucket-name>

# Node Environment
NODE_ENV=production
```

### Automatic Variables

Railway automatically provides these for the PostgreSQL service:
- `DATABASE_URL` - Full connection string
- `PGHOST` - Database host
- `PGPORT` - Database port
- `PGUSER` - Database user
- `PGPASSWORD` - Database password
- `PGDATABASE` - Database name

## Step 4: Run Database Migrations

### Option A: Using Railway CLI (Recommended)

1. Install Railway CLI: `npm install -g @railway/cli`
2. Login: `railway login`
3. Link your project: `railway link`
4. Run migrations:
   ```bash
   # Run schema migrations
   railway run npm run migrate
   
   # Run migrations with seed data
   railway run npm run migrate:seed
   ```

### Option B: Using Railway Shell

1. In Railway dashboard, click on your backend service
2. Go to "Settings" → "Shell"
3. Run:
   ```bash
   npm run migrate:seed
   ```

### Option C: Manual Database Connection

1. Get database credentials from Railway PostgreSQL service
2. Connect using your preferred PostgreSQL client
3. Run migrations in order:
   - `migrations/init-db.sql`
   - `migrations/update-dogs-table.sql`
   - `migrations/extend-parks-schema.sql`
   - `migrations/add-privacy-settings.sql`
   - `migrations/seed-parks.sql` (optional)
   - `migrations/dog_runs_import.sql` (optional)

## Step 5: Deploy the Application

### Initial Deployment

1. Railway will automatically deploy when you connect the GitHub repository
2. Monitor the deployment logs in the Railway dashboard
3. Check for any build or runtime errors

### Deployment Settings

Railway uses the `railway.json` configuration:
- Node.js version: 18.17.0 (from `.nvmrc`)
- Start command: `npm run start:prod`
- Health check: `/health` endpoint
- Auto-restart on failure

## Step 6: Verify Deployment

1. Get your deployment URL from Railway (format: `https://your-app.up.railway.app`)
2. Test the health endpoint:
   ```bash
   curl https://your-app.up.railway.app/health
   ```
3. Expected response:
   ```json
   {
     "status": "healthy",
     "timestamp": "2025-01-12T..."
   }
   ```

## Step 7: Update iOS App Configuration

Update your iOS app to use the production API:

1. In Xcode, update the API base URL:
   ```swift
   let baseURL = "https://your-app.up.railway.app/api"
   ```
2. Ensure HTTPS is used for all API calls

## Monitoring and Maintenance

### Logs

- View logs in Railway dashboard under your service
- Use Railway CLI: `railway logs`

### Database Backups

Railway provides automatic daily backups for PostgreSQL. You can also:
- Create manual backups via the dashboard
- Set up additional backup strategies

### Scaling

- Railway allows easy vertical scaling (more resources)
- Horizontal scaling available on higher-tier plans

## Troubleshooting

### Common Issues

1. **PostGIS not enabled**
   - Error: "type geography does not exist"
   - Solution: Run `CREATE EXTENSION postgis;` in database

2. **Migration failures**
   - Check database connection in logs
   - Ensure migrations run in correct order
   - Verify PostGIS is enabled before running migrations

3. **Image upload failures**
   - Verify AWS credentials are correct
   - Check S3 bucket permissions
   - Ensure bucket exists in specified region

4. **CORS errors from iOS app**
   - Add iOS app domain to CORS whitelist
   - Check `CORS_ORIGIN` environment variable

### Debug Commands

```bash
# Check deployment status
railway status

# View environment variables
railway variables

# Run one-off commands
railway run node -e "console.log(process.env.DATABASE_URL)"

# Access logs
railway logs --tail
```

## Security Checklist

- [ ] Generate strong JWT_SECRET (minimum 32 characters)
- [ ] Verify PostgreSQL is not publicly accessible
- [ ] S3 bucket has proper access policies
- [ ] Environment variables don't contain sensitive data in logs
- [ ] HTTPS is enforced for all endpoints

## Next Steps

1. Set up custom domain (optional)
2. Configure monitoring/alerting
3. Implement CI/CD pipeline
4. Add error tracking (e.g., Sentry)
5. Set up staging environment

## Support

- Railway Documentation: https://docs.railway.app
- Railway Discord: https://discord.gg/railway
- BarkPark Issues: https://github.com/[your-username]/BarkPark/issues