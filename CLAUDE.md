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

## Session 21 Summary - Threaded Comments Implementation

### Features Implemented
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

---
*For detailed session history, see git commits. This file maintains current project state and essential protocols.*