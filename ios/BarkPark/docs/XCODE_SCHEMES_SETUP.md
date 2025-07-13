# Xcode Build Schemes Setup Guide

This guide walks you through creating and configuring Xcode schemes for different BarkPark environments.

## Overview

We'll create three schemes:
1. **BarkPark (Local)** - Default development scheme
2. **BarkPark (Staging)** - For testing against staging server
3. **BarkPark (Production)** - For future production releases

## Step-by-Step Setup

### 1. Open Scheme Manager

1. Open `BarkPark.xcodeproj` in Xcode
2. Go to **Product → Scheme → Manage Schemes...**
3. You should see the default "BarkPark" scheme

### 2. Create Local Development Scheme

This is typically your default scheme, but let's ensure it's properly configured:

1. Select "BarkPark" scheme and click "Edit..."
2. Go to **Run → Arguments → Environment Variables**
3. Add these variables (click + button):
   - `BARKPARK_ENVIRONMENT` = `local`
   - `LOCAL_API_URL` = `http://YOUR_IP:3000/api` (replace YOUR_IP)

### 3. Create Staging Scheme

1. In Scheme Manager, select "BarkPark" and click "Duplicate"
2. Name it "BarkPark (Staging)"
3. Make sure "Shared" is checked
4. Click "Edit Scheme..."
5. Configure as follows:

**Run Configuration:**
- Build Configuration: `Debug`
- Arguments → Environment Variables:
  - `BARKPARK_ENVIRONMENT` = `staging`

**Test Configuration:**
- Build Configuration: `Debug`
- Keep same environment variables

**Archive Configuration:**
- Build Configuration: `Release`
- The Release build will automatically use staging (as configured in code)

### 4. Create Production Scheme (Future)

1. Duplicate "BarkPark" scheme again
2. Name it "BarkPark (Production)"
3. Configure:

**Run Configuration:**
- Build Configuration: `Debug`
- Arguments → Environment Variables:
  - `BARKPARK_ENVIRONMENT` = `production`

**Archive Configuration:**
- Build Configuration: `Release`
- Will use production URL when code is updated

## Build Configurations

### Understanding Build Configurations

Xcode provides two default configurations:
- **Debug**: Development builds with debugging enabled
- **Release**: Optimized builds for TestFlight/App Store

Our environment system works with both:
- Debug builds can target any environment via variables
- Release builds default to staging (will be production later)

### Configuration Settings

To view/edit build configurations:
1. Select project in navigator
2. Select "BarkPark" project (not target)
3. Go to "Info" tab
4. See "Configurations" section

## Scheme Usage Guide

### For Local Development

```bash
# Use when developing with local backend
Scheme: BarkPark (Local)
Backend: npm run dev
URL: http://YOUR_IP:3000/api
```

### For Staging Testing

```bash
# Use when testing against Railway staging
Scheme: BarkPark (Staging)  
Backend: Railway staging environment
URL: https://barkpark-staging.up.railway.app/api
```

### For TestFlight Builds

```bash
# Archive with staging scheme
1. Select "BarkPark (Staging)" scheme
2. Product → Archive
3. Upload to App Store Connect
4. Distribute via TestFlight
```

## Managing IP Address Changes

When your local IP changes:

### Option 1: Update Scheme (Recommended)
1. Edit "BarkPark (Local)" scheme
2. Update `LOCAL_API_URL` environment variable
3. Clean build folder (Cmd+Shift+K)

### Option 2: Create Personal Scheme
1. Duplicate "BarkPark (Local)"
2. Name it "BarkPark (Your Name)"
3. Set your specific IP
4. Don't share this scheme (uncheck "Shared")

## Sharing Schemes

### Make Schemes Shareable

1. In Manage Schemes, check "Shared" for schemes to share
2. Schemes are stored in: `BarkPark.xcodeproj/xcshareddata/xcschemes/`
3. Commit these files to git

### Gitignore Personal Schemes

Add to `.gitignore`:
```
*.xcodeproj/xcuserdata/
!*.xcodeproj/xcshareddata/
```

## Switching Between Environments

### Quick Switch
1. Click scheme selector in Xcode toolbar
2. Choose desired scheme
3. Build and run (Cmd+R)

### Verify Active Environment
Check Xcode console for:
```
🌍 BarkPark Environment: staging
🔗 API Base URL: https://barkpark-staging.up.railway.app/api
```

## TestFlight Configuration

### Staging Builds
1. Use "BarkPark (Staging)" scheme
2. Archive with Release configuration
3. Upload to TestFlight
4. Test with real devices against staging server

### Production Builds (Future)
1. Update `APIConfiguration.swift` to use production in Release
2. Use "BarkPark (Production)" scheme
3. Follow same archive process

## Troubleshooting

### Scheme Not Appearing
1. Quit and restart Xcode
2. Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Check if scheme file exists in project

### Environment Not Switching
1. Clean build folder (Cmd+Shift+K)
2. Check environment variable spelling
3. Verify scheme is selected before building

### Can't Connect to Backend
1. Verify backend is running
2. Check IP address is correct
3. Test with curl: `curl http://YOUR_IP:3000/api/health`
4. Check firewall settings

## CI/CD Integration

For automated builds:

### Fastlane Configuration
```ruby
lane :staging do
  build_app(
    scheme: "BarkPark (Staging)",
    configuration: "Release"
  )
end

lane :production do
  build_app(
    scheme: "BarkPark (Production)",
    configuration: "Release"
  )
end
```

### Xcode Cloud
1. Configure workflow for each scheme
2. Set environment variables in workflow
3. Archive and distribute automatically

## Best Practices

1. **Use Descriptive Names**: Clear scheme names prevent confusion
2. **Share Common Schemes**: Share staging/production schemes
3. **Keep Personal Schemes Local**: Don't share IP-specific schemes
4. **Document Changes**: Update this guide when adding schemes
5. **Test Each Environment**: Verify each scheme works before committing

## Next Steps

1. Create the schemes as described
2. Test each scheme with appropriate backend
3. Share staging scheme with team
4. Set up TestFlight for staging builds
5. Plan production rollout strategy