# CLAUDE.md

This file provides guidance for AI assistants working with the BarkPark codebase. It contains project context, development protocols, and current status.

## 🐕 Project Overview

**BarkPark** is a dog social network application featuring:
- **Backend**: Node.js/Express REST API with JWT authentication
- **Database**: PostgreSQL with PostGIS for 103 dog parks
- **Frontend**: iOS SwiftUI app (iOS 17+)
- **Deployment**: Railway PaaS (backend), TestFlight (iOS)
- **Production API**: `https://barkpark-production.up.railway.app/api`
- **Local/Dev API**: Development is done on a locally hosted API

### Current Features
- 🔐 JWT authentication with privacy controls
- 🐕 Dog profile management with photos
- 📍 Park discovery with real-time activity
- 👥 Friend connections (search + QR codes)
- ✅ Check-in system for park visits
- 🗺️ Dynamic map with location-based search
- 📰 Social feed with posts, likes, and comments
- 🔔 Real-time notifications for social interactions
- 🔑 Password reset with 5-digit alphanumeric codes via email

## 📱 iOS App Architecture

### Key Components
- **APIService**: Singleton pattern (`APIService.shared`) for all network requests
  - Base URL: `https://barkpark-production.up.railway.app/api`
  - Uses native URLSession, no third-party networking libraries
  - JWT token stored in UserDefaults with key "auth_token"
- **ViewModels**: Follow `@MainActor` pattern with `ObservableObject`
  - Always use `@Published` for UI state properties
  - Error handling via `error.localizedDescription`
  - Standard properties: `isLoading`, `errorMessage`
- **Error Types**: Use `APIError` enum (not NetworkError)
  - `.invalidResponse`, `.decodingError`, `.authenticationFailed(String)`, `.validationFailed(String)`, `.serverError`

### UI Component Patterns
- **Naming**: Avoid generic names that may conflict (e.g., use `UserProfileDogCard` instead of `DogCard`)
- **Design System**: Always use `BarkParkDesign` values
  - Colors: `.dogPrimary`, `.dogSecondary`, `.primaryText`, `.secondaryText`
  - Typography: `.title`, `.headline`, `.body`, `.caption`
  - Spacing: `.xs` (4), `.sm` (8), `.md` (16), `.lg` (24), `.xl` (32)
  - CornerRadius: `.small` (6), `.medium` (8), `.large` (12), `.extraLarge` (16)

### Complex Model Patterns
- **Mixed Media Support**: Use separate arrays for different media types (see `PostMedia` model)
- **Date Formatting**: Use `RelativeDateTimeFormatter` for "time ago" displays
- **Optimistic UI**: Update local state immediately, then sync with API (see `FeedViewModel.toggleLike`)
- **Pagination**: Use `limit`/`offset` with `hasMore` flag for infinite scrolling

### Navigation Patterns
- Use `NavigationLink` for push navigation
- Use `.sheet()` for modal presentations
- Navigation is already wrapped in `NavigationView` at root level

## 💻 Local Development Setup

### Backend Server Management
- **Starting the server**: `npm run dev` (runs with nodemon for auto-reload)
- **Running in background**: `npm run dev > server.log 2>&1 &`
- **Checking server status**: `ps aux | grep "node.*server" | grep -v grep`
- **Viewing logs**: `tail -f server.log` (if running in background)
- **Default port**: 3000 (configurable via PORT env variable)

### iOS Development Configuration
- **IP Address Setup**:
  1. Find your machine's IP: `ifconfig | grep -E "inet.*broadcast" | awk '{print $2}'`
  2. Update `APIService.swift` baseURL: `http://YOUR_IP:3000/api`
  3. Rebuild iOS app after IP changes (Clean Build: Cmd+Shift+K)
- **Common Issues**:
  - iOS Simulator can't reach localhost - must use machine IP
  - IP addresses change when switching networks
  - Firewall may block port 3000 - check system preferences
- **Testing Connection**: `curl http://YOUR_IP:3000/health`

### Development Workflow Best Practices
1. Always start backend server before iOS development
2. Keep server logs visible in separate terminal
3. Update IP address in APIService when network changes
4. Use `git status` before commits to avoid server.log
5. Test API endpoints with curl before iOS integration

## 🛠️ Development Protocols

### Core Principles
1. **Read First**: Examine existing patterns before implementing
2. **Schema Safety**: Always verify database alignment before migrations
3. **Security First**: Never expose secrets, validate all input
4. **Match Patterns**: Follow existing code conventions
5. **Test based development**: We are following a test-based development approach. tests should be written for all new functionality and used through the development process to ensure functionality.


### Production Database Testing Patterns
- **Test Data Management**:
  - Use distinctive test data (e.g., "TEST_" prefix)
  - Create cleanup scripts for test data
  - Document test user accounts
- **Debug Endpoints**:
  - Create `/api/test/*` endpoints for development
  - Include raw database queries for debugging
  - Remove or secure before production release
- **Monitoring During Development**:
  - Keep Railway logs open while testing
  - Use `console.log` strategically in development
  - Check migration status after each deployment

### Git Commit Format
```
<type>: <subject> (50 chars max)

<body> (optional, wrap at 72 chars)

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Pre-commit Checklist
- ⚠️ Never commit: node_modules/, .env files, temporary scripts
- 📝 **ALWAYS** run `git status` before ANY `git add` command
- 🎯 Stage specific files individually - avoid `git add -A` or `git add .`
- 👀 Check for unintended files (especially node_modules, build artifacts)
- 🔍 Use `git diff --staged` to verify changes before committing
- 🧹 Remove debug logs (console.log, print statements) unless specifically needed
- ✅ Ensure no test data or mock values remain in production code
- 🚫 If too many files staged accidentally, use `git reset HEAD` to unstage all

## 🗄️ Database Management

### Unified Migration System
- **Runner**: `scripts/unified-migrate.js`
- **Files**: `migrations/00X_*.sql` (numbered sequence)
- **Tracking**: `schema_migrations` table with checksums
- **Auto-deploy**: Runs on Railway deployment

### Migration Commands
```bash
npm run db:migrate          # Run pending migrations
npm run db:migrate:status   # Check migration status
npm run db:migrate:verify   # Verify schema integrity
npm run db:schema:compare   # Compare production vs local
npm run db:schema:sync      # Compare & generate migration SQL
npm run db:schema:sync:verbose  # Detailed schema comparison
```

### Schema Validation Endpoints
- `GET /api/schema/compare` - PostGIS-aware schema comparison
- `GET /api/schema/compare/raw` - Raw schema information
- `POST /api/schema/compare/environments` - Compare specific environments
- `GET /api/schema/validate` - Quick validation check

### PostGIS Schema Management
- **Comparison Tool**: `utils/schema-compare.js` - Handles PostGIS type normalization
- **Sync Script**: `scripts/schema-sync.js` - Generates migration SQL
- **Documentation**: `docs/POSTGIS_MIGRATION_GUIDE.md` - Complete migration guide

### Migration Best Practices
- Never modify existing migrations
- Test against production-like data
- Use rollback scripts in `migrations/rollback/`
- Run `db:migrate:status` before pushing code
- Document manual interventions immediately
- Always check existing database state before creating migrations
- Use IF EXISTS/IF NOT EXISTS clauses for safety
- Handle both development and production scenarios
- Test migrations with fresh database and existing data
- Document rollback procedures for each migration

## 🐛 Debugging Methodology

### Systematic Debugging Approach
When encountering errors, follow this systematic approach:
1. **Capture Exact Error**: Don't assume - get the full error message and stack trace
2. **Create Minimal Test Case**: Build debug endpoints or views to isolate the issue
3. **Test Incrementally**: Test each hypothesis one at a time
4. **Document Findings**: Keep notes on what you've tried and results
5. **Avoid Assumptions**: Don't guess at root causes - prove them with evidence

Example from Session 17:
- ❌ Wrong: Assumed date format was the issue without checking
- ✅ Right: Created FeedDebugView to capture exact decoding error, revealing missing CodingKeys

### Production Issues
1. **Check logs first**: Railway dashboard, server logs
2. **Verify schema**: Compare local vs production database
3. **Test with real data**: Use actual tokens and requests
4. **Create diagnostics**: Build admin endpoints as needed
5. **Document findings**: Update this file with solutions

### Production Deployment Failures
1. **Check uncommitted files**: `git status` - ensure all required files are in repo
2. **Verify environment parity**: Compare local vs production configurations
3. **Log analysis sequence**: 
   - Application logs → Database logs → Infrastructure logs
4. **Schema verification**: Always compare local vs production schemas
5. **Migration state**: Check schema_migrations table consistency
6. **Test startup locally**: Simulate production startup command

### Environment Variables
**Required for Production:**
- `DATABASE_URL` - Railway PostgreSQL connection
- `JWT_SECRET` - Token signing secret
- `NODE_ENV` - Set to "production"
- `ADMIN_KEY` - For protected admin endpoints
- `SMTP_HOST` - Email server hostname (e.g., smtp.sendgrid.net)
- `SMTP_PORT` - Email server port (typically 587)
- `SMTP_SECURE` - Use TLS (true/false)
- `SMTP_USER` - SMTP username (for SendGrid: "apikey")
- `SMTP_PASS` - SMTP password/API key
- `SMTP_FROM` - Sender email address (must be verified)
- `APP_URL` - Application URL for email links
- `AWS_ACCESS_KEY_ID` - AWS access key for S3
- `AWS_SECRET_ACCESS_KEY` - AWS secret key for S3
- `AWS_REGION` - AWS region (defaults to us-east-1)
- `S3_BUCKET_NAME` - S3 bucket name for image storage

**Important S3 Configuration Notes:**
- ALL photo uploads (user profiles and dog photos) require S3 credentials
- Without S3 credentials, uploads will fail with "Failed to upload image"
- Default bucket name is 'barkpark-images' if not specified
- No local file storage fallback exists - S3 is mandatory for photo features

### Common Issues
- **Schema mismatch**: Run `npm run db:schema:compare`
- **Migration errors**: Check `schema_migrations` table
- **Auth failures**: Verify JWT_SECRET matches
- **Connection issues**: Check Railway logs and limits

### Common iOS/Backend Integration Issues
- **Type Mismatches**:
  - PostgreSQL COUNT() returns numeric strings - cast with `::int`
  - Example: `COUNT(DISTINCT pl.id)::int as like_count`
- **Date Formatting**:
  - PostgreSQL timestamps: `2025-06-18T05:10:42.093Z`
  - Use custom JSONDecoder with multiple format support
  - Keep dates as strings if parsing fails repeatedly
- **Field Naming**:
  - Backend uses snake_case: `user_id`, `created_at`
  - iOS uses camelCase: `userId`, `createdAt`
  - Always map in CodingKeys enum
- **Null vs Optional**:
  - PostgreSQL NULL → Swift nil
  - Ensure optional types match database schema

### Common iOS Issues
- **Blank Screen Debugging**:
  1. Add temporary debug logs to check view states: `isLoading`, `errorMessage`, data presence
  2. Verify `onAppear` is being called with correct parameters
  3. Check Xcode console for API errors or decoding failures
  4. Ensure navigation is properly set up (NavigationLink/NavigationView)
  5. Verify ViewModel is properly initialized with `@StateObject`
- **Build Errors**:
  1. Clean Build Folder (Cmd+Shift+K) for cached errors
  2. Check for naming conflicts between files
  3. Verify all models conform to required protocols (Codable, Identifiable)
- **API Integration**:
  1. Check if new endpoints are added to APIService
  2. Verify response models match backend exactly (case-sensitive)
  3. Ensure proper error handling in ViewModels

## 🧠 AI Assistant Guidelines

### Do's
- ✅ Test API changes thoroughly
- ✅ Follow existing code patterns
- ✅ Update documentation after changes
- ✅ Use migration system for schema changes
- ✅ Check production logs before assuming issues
- ✅ When implementing new features, first study existing similar implementations
- ✅ Use Task tool to explore codebase when uncertain about patterns
- ✅ In future when we make changes to the ios app, you should test the build succeeds

### Don'ts
- ❌ Modify production data directly
- ❌ Create files unless necessary
- ❌ Skip error handling
- ❌ Make assumptions without checking
- ❌ Deploy without testing

### Technical Decision Points
When facing architectural choices:
1. **Evaluate long-term implications** over quick fixes
2. **Consider production stability** and migration complexity
3. **Ask for strategic direction** when multiple valid paths exist
4. **Document the decision** and reasoning in code comments
5. **Prefer established patterns** (e.g., PostGIS for geo data)

### Session Management
When user says **"wrap this session"**:
1. Update session notes with:
   - Key problems solved
   - Technical decisions made
   - Files modified (with line numbers)
   - Next steps or pending tasks
2. Create descriptive git commit:
   - List all changes in commit body
   - Reference issue numbers if applicable
   - Include migration warnings if schema changed
3. Update known issues or features
4. Clear completed todos from session

## 📋 Session Notes

### Quick Reference
```bash
# Test production API endpoints
curl -H "Authorization: Bearer $TOKEN" https://barkpark-production.up.railway.app/api/parks
curl -H "Authorization: Bearer $TOKEN" https://barkpark-production.up.railway.app/api/posts/feed
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"content":"Test post","visibility":"friends"}' \
  https://barkpark-production.up.railway.app/api/posts

# Check migration status (requires production database connection)
# Note: This won't work locally without Railway database credentials

# Monitor deployment
# Use Railway dashboard for logs and deployment status
```

### PostGIS Reference
```sql
-- Store location: ST_MakePoint(longitude, latitude)::geography
-- Extract coords: ST_X(location::geometry), ST_Y(location::geometry)
-- Find nearby: ST_DWithin(location, point, distance_meters)
-- Calculate distance: ST_Distance(location1, location2)
```

## 📚 Technical Implementation References

*Note: Detailed session summaries below contain technical learnings and implementation patterns that may be useful for future development. For progress tracking, see git commit history.*

### Session 21 - Threaded Comments Implementation

#### Features Implemented
- **Backend Changes**:
  - Removed comment editing functionality (users can only delete) - backend/routes/posts.js:348
  - Added cascade deletion for child comments using recursive CTE - backend/models/PostComment.js:165-216
  - Created comprehensive test suite - backend/tests/comments.test.js

- **iOS Implementation**:
  - Created Comment model with nested reply support - ios/BarkPark/BarkPark/Models/Comment.swift
  - Built CommentView for recursive comment display - ios/BarkPark/BarkPark/Features/Feed/Views/CommentView.swift
  - Created CommentsSheetView with composition UI - ios/BarkPark/BarkPark/Features/Feed/Views/CommentsSheetView.swift
  - Added CommentViewModel for state management - ios/BarkPark/BarkPark/Features/Feed/ViewModels/CommentViewModel.swift
  - Updated APIService with comment endpoints - ios/BarkPark/BarkPark/Core/Network/APIService.swift:1087-1180
  - Integrated real-time comment count updates - ios/BarkPark/BarkPark/Features/Feed/ViewModels/FeedViewModel.swift:16-75

### Technical Decisions
- Limited comment nesting to 3 levels for UI clarity
- Used cascade deletion instead of soft delete for data integrity
- Implemented optimistic UI updates for comment counts
- Added NotificationCenter for cross-view state synchronization

### Build Issues Fixed
- Resolved @objc selector compilation errors with Foundation.Notification
- Fixed Post model initialization in preview providers
- Corrected variable mutability warnings

### Next Steps
- Consider adding comment reactions/likes
- Implement comment reporting/moderation
- Add push notifications for comment replies
- Create comment search functionality

### Session 22 - Password Reset Implementation

#### Features Implemented
- **Backend Password Reset**:
  - Database migration adding reset_token and reset_token_expires to users table - backend/migrations/008_add_password_reset.sql
  - Email service with nodemailer integration - backend/services/emailService.js
  - Three new auth endpoints: /forgot-password, /reset-password, /verify-reset-token - backend/routes/auth.js:236-360
  - User model methods for token generation and validation - backend/models/User.js:85-161
  - Comprehensive test suite with 12 passing tests - backend/tests/password-reset.test.js
  - Support for both development (Ethereal Email) and production (SMTP) email delivery

- **iOS Password Reset**:
  - Password reset API methods in APIService - ios/BarkPark/BarkPark/Core/Network/APIService.swift:1184-1278
  - PasswordResetViewModel with validation logic - ios/BarkPark/BarkPark/Features/Authentication/ViewModels/PasswordResetViewModel.swift
  - ForgotPasswordView for email input - ios/BarkPark/BarkPark/Features/Authentication/Views/ForgotPasswordView.swift
  - ResetPasswordView with token and password fields - ios/BarkPark/BarkPark/Features/Authentication/Views/ResetPasswordView.swift
  - Response models for API communication - ios/BarkPark/BarkPark/Models/PasswordReset.swift
  - "Forgot Password?" link in LoginView - ios/BarkPark/BarkPark/Features/Authentication/Views/LoginView.swift:111-117

### Technical Issues & Solutions
- **Nodemailer Import Error**: Fixed by correcting function name from `createTransporter` to `createTransport` (common mistake)
- **Nodemailer Version**: Downgraded from v7 to v6.10.1 for compatibility
- **iOS onChange Deprecation**: Updated to new iOS 17 syntax with two-parameter closure
- **Test Database Migration**: Applied password reset migration directly to test database using psql
- **Migration Runner**: Added migration 008 to unified-migrate.js migrations array

### Email Configuration
- **Development**: Automatically uses Ethereal Email when SMTP vars not set (shows preview URLs in console)
- **Production**: Requires SMTP environment variables in Railway dashboard:
  - SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_USER, SMTP_PASS, SMTP_FROM
- **SendGrid Setup**: 
  - Use `apikey` as SMTP_USER
  - API key as SMTP_PASS
  - Requires verified sender email
- **Security Note**: SMTP credentials should NEVER be committed - use environment variables only

### Important Patterns Learned
- **iOS API Error Handling**: Always check exact function names in URLSession patterns
- **Environment-Specific Config**: Use .env for local only, Railway dashboard for production
- **Test Database Sync**: Remember to apply migrations to both development and test databases

### Session 23 - Password Reset UX Improvements

#### Changes Made
- **Shorter Reset Codes**: Changed from 32-char hex to 5-digit alphanumeric (e.g., "A3B7K")
- **Manual Login Flow**: Removed auto-login after reset - users must login with new password
- **iOS Navigation Fix**: Used binding pattern to dismiss multiple sheets properly
  - Pass `@Binding var shouldDismissAll: Bool` between nested sheets
  - Parent sheet watches binding with `.onChange(of:)` to dismiss when true

#### Key Learning
- **iOS Sheet Dismissal**: When presenting multiple sheets (A → B → C), dismissing C only closes C, not the entire stack. Use binding communication to coordinate dismissal of the entire flow.

### Session 24 - Account Management & Profile Photos

#### Features Implemented
- **Account Management**:
  - AccountSettingsView for editing user profile (first name, last name, email, phone) - ios/BarkPark/BarkPark/Features/Profile/Views/AccountSettingsView.swift
  - Change password functionality within account settings
  - Profile photo upload with PhotosPicker
  - Navigation from ProfileView (tap user info section)
  
- **Profile Photo Upload**:
  - Backend endpoints: `POST /api/auth/me/profile-photo`, `DELETE /api/auth/me/profile-photo` - backend/routes/auth.js:216-296
  - Uses same S3 infrastructure as dog photos
  - Image processing with automatic resize and compression
  - Multipart form data upload from iOS

- **Profile Display Updates**:
  - ProfileView now shows user's actual profile photo - ios/BarkPark/BarkPark/Features/Profile/Views/ProfileView.swift:44-66
  - AsyncImage with circular clipping and border styling
  - Falls back to person.circle.fill icon when no photo

#### Technical Patterns
- **Photo Upload Flow**: PhotosPicker → Data → ImageProcessor → S3 → Update User Profile
- **State Management**: Profile updates trigger AuthenticationManager.updateCurrentUser()
- **Error Handling**: Separate photo upload from profile data update for better error recovery

#### Key Learnings
- **S3 Credentials Required**: Photo uploads will not work without AWS credentials in .env
- **No Local Storage**: There is no fallback for development - S3 is mandatory
- **Profile Image Display**: Must use AsyncImage with proper URL handling for S3 images
- **Update Sequencing**: Upload photo first, then update profile to avoid overwriting photo URL

---
*For detailed session history, see git commits. This file maintains current project state and essential protocols.*