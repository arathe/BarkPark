# CLAUDE.md

This file provides guidance for AI assistants working with the BarkPark codebase. It contains project context, development protocols, and current status.

## 🐕 Project Overview

**BarkPark** is a dog social network application featuring:
- **Backend**: Node.js/Express REST API with JWT authentication
- **Database**: PostgreSQL with PostGIS for 103 dog parks
- **Frontend**: iOS SwiftUI app (iOS 17+)
- **Deployment**: Railway PaaS (backend), TestFlight (iOS)
- **Production API**: `https://barkpark-production.up.railway.app/api`

### Current Features
- 🔐 JWT authentication with privacy controls
- 🐕 Dog profile management with photos
- 📍 Park discovery with real-time activity
- 👥 Friend connections (search + QR codes)
- ✅ Check-in system for park visits
- 🗺️ Dynamic map with location-based search

### Project Status
- ✅ Backend: Production-ready on Railway
- ✅ iOS App: Feature-complete, ready for App Store
- ✅ Database: Fully migrated with unified system
- ✅ Social Features: Privacy settings, QR codes, friend management

## 🛠️ Development Protocols

### Core Principles
1. **Read First**: Examine existing patterns before implementing
2. **Test Locally**: Use local database for development
3. **Schema Safety**: Always verify database alignment
4. **Security First**: Never expose secrets, validate all input
5. **Match Patterns**: Follow existing code conventions

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
- 📝 Review with `git status` before staging
- 🎯 Stage specific files rather than using `git add -A` when possible
- 🔍 Use `git diff --staged` to verify changes

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
```

### Schema Validation Endpoints
- `GET /api/schema/compare` - Full schema comparison
- `GET /api/schema/validate` - Quick validation check

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

## 🧠 AI Assistant Guidelines

### Do's
- ✅ Test API changes thoroughly
- ✅ Follow existing code patterns
- ✅ Update documentation after changes
- ✅ Use migration system for schema changes
- ✅ Check production logs before assuming issues

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

### Recent Changes (Session 14)
- Fixed iOS navigation from sheet to push presentation (RootView.swift, ProfileView.swift, MainTabView.swift)
- Resolved security issue with hardcoded JWT secret (backend/scripts/update-local-env.sh:7)
- Migrated entire codebase to PostGIS from lat/lng columns:
  - Updated all migrations to use GEOGRAPHY(POINT, 4326)
  - Rewrote DogPark.js model with PostGIS queries (backend/models/DogPark.js)
  - Converted 103+ park seed data to ST_MakePoint format
  - Maintained API compatibility by extracting lat/lng in queries
- Enhanced migration system with better error handling (backend/scripts/unified-migrate.js)
- Improved CLAUDE.md with technical decision guidance and PostGIS reference

**Next Steps**: Test all location-based features with new PostGIS implementation

### Previous Sessions
- Session 13: Persistent check-in UI across all views
- Session 12: Unified migration system implementation

### Known Working Features
- All authentication endpoints
- Park search and discovery
- Friend connections with QR codes
- Check-in system with persistent UI
- Privacy controls
- Active check-in display across app

### Quick Reference
```bash
# Test production API
curl -H "Authorization: Bearer $TOKEN" https://barkpark-production.up.railway.app/api/parks

# Check local database
npm run db:migrate:status

# Compare schemas
npm run db:schema:compare

# Generate test token
node scripts/generate-test-token.js
```

### PostGIS Reference
```sql
-- Store location: ST_MakePoint(longitude, latitude)::geography
-- Extract coords: ST_X(location::geometry), ST_Y(location::geometry)
-- Find nearby: ST_DWithin(location, point, distance_meters)
-- Calculate distance: ST_Distance(location1, location2)
```

---
*For detailed session history, see git commits. This file maintains current project state and essential protocols.*