# iOS Environment Configuration Guide

This guide explains how to configure the BarkPark iOS app for different environments (Local, Staging, Production).

## Environment Structure

The app supports three environments:
- **Local**: For development with local backend server
- **Staging**: For TestFlight testing with staging backend
- **Production**: For App Store release with production backend

## Configuration Methods

### 1. Automatic Environment Detection

The app automatically selects the environment based on build configuration:

- **Debug builds**: Default to `local` environment
- **Release builds**: Default to `staging` environment (will change to `production` when ready)
- **SwiftUI Previews**: Always use `local` environment

### 2. Environment Variable Override

You can override the environment using Xcode scheme environment variables:

1. Edit your scheme in Xcode (Product → Scheme → Edit Scheme)
2. Select "Run" on the left
3. Go to "Arguments" tab
4. Add environment variable:
   - Name: `BARKPARK_ENVIRONMENT`
   - Value: `local`, `staging`, or `production`

### 3. Custom Local API URL

For local development with different IP addresses:

1. Add environment variable:
   - Name: `LOCAL_API_URL`
   - Value: `http://YOUR_IP:3000/api`

This is useful when:
- Your machine's IP changes
- Multiple developers with different IPs
- Using a different port

## Build Configurations

### Debug Configuration (Development)
- Default environment: `local`
- API URL: `http://192.168.86.67:3000/api` (or custom via `LOCAL_API_URL`)
- Can override with `BARKPARK_ENVIRONMENT`

### Release Configuration (TestFlight/App Store)
- Default environment: `staging`
- API URL: `https://barkpark-staging.up.railway.app/api`
- Will change to `production` URL when ready for App Store

## Setting Up Xcode Schemes

### Create Staging Scheme

1. **Duplicate Debug Scheme**
   - In Xcode, go to Product → Scheme → Manage Schemes
   - Select "BarkPark" scheme and click "Duplicate"
   - Name it "BarkPark (Staging)"

2. **Configure for Staging**
   - Edit the new scheme
   - Under "Run" → "Arguments" → "Environment Variables"
   - Add: `BARKPARK_ENVIRONMENT` = `staging`

3. **Use Debug Build Configuration**
   - Stay in Debug mode for easier debugging
   - The environment variable will point to staging

### Create Local Scheme with Custom IP

1. **Duplicate Debug Scheme**
   - Name it "BarkPark (Local - Custom IP)"

2. **Add Environment Variables**
   - `LOCAL_API_URL` = `http://YOUR_IP:3000/api`

## Verifying Configuration

The app logs the current environment on startup:

```
🌍 BarkPark Environment: local
🔗 API Base URL: http://192.168.86.67:3000/api
```

Check Xcode console to verify the correct environment is being used.

## Common Scenarios

### Scenario 1: Local Development
- Use default "BarkPark" scheme
- Update `LOCAL_API_URL` if your IP changes
- Backend running on `npm run dev`

### Scenario 2: Testing with Staging
- Use "BarkPark (Staging)" scheme
- Connects to Railway staging environment
- Good for testing with real network conditions

### Scenario 3: TestFlight Build
- Archive with Release configuration
- Automatically uses staging environment
- No manual configuration needed

### Scenario 4: Multiple Developers
Each developer can:
1. Create their own scheme
2. Set their machine's IP in `LOCAL_API_URL`
3. Share schemes via git (optional)

## Troubleshooting

### App Can't Connect to Local Backend

1. **Check IP Address**
   ```bash
   # Find your current IP
   ifconfig | grep -E "inet.*broadcast" | awk '{print $2}'
   ```

2. **Update Environment Variable**
   - Edit scheme → Arguments → Environment Variables
   - Update `LOCAL_API_URL` with new IP

3. **Verify Backend is Running**
   ```bash
   curl http://YOUR_IP:3000/api/health
   ```

### Wrong Environment in TestFlight

1. Verify you archived with Release configuration
2. Check that staging URL is correct in APIConfiguration
3. Test staging URL directly:
   ```bash
   curl https://barkpark-staging.up.railway.app/api/health
   ```

### Environment Not Switching

1. Clean build folder (Cmd+Shift+K)
2. Delete app from simulator/device
3. Verify environment variable spelling
4. Check for typos in environment value

## Best Practices

1. **Don't Hardcode IPs**: Use environment variables
2. **Test All Environments**: Before releasing, test local → staging → production flow
3. **Document IP Changes**: When network changes, update your scheme
4. **Use Schemes**: Create separate schemes for different test scenarios
5. **Log Environment**: Always verify which environment you're connected to

## Future Production Setup

When ready for App Store release:

1. Update `APIConfiguration.swift`:
   ```swift
   #else
   // Release builds use production
   return .production
   #endif
   ```

2. Ensure production URL is correct:
   ```swift
   case .production:
       return "https://barkpark-production.up.railway.app/api"
   ```

3. Create separate TestFlight build for staging testing if needed