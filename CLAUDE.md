# CLAUDE.md

This file provides guidance for AI assistants working with the BarkPark codebase. It contains project context, development protocols, and current status.

## 🐕 Project Overview

**BarkPark** is a dog social network application featuring:
- **Backend**: Node.js/Express REST API with JWT authentication
- **Database**: PostgreSQL with 103 dog parks (lat/lng coordinates)
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

### Best Practices
- Never modify existing migrations
- Test against production-like data
- Use rollback scripts in `migrations/rollback/`
- Run `db:migrate:status` before pushing code
- Document manual interventions immediately

## 🐛 Debugging Methodology

### Production Issues
1. **Check logs first**: Railway dashboard, server logs
2. **Verify schema**: Compare local vs production database
3. **Test with real data**: Use actual tokens and requests
4. **Create diagnostics**: Build admin endpoints as needed
5. **Document findings**: Update this file with solutions

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

### Session Management
When user says **"wrap this session"**:
1. Update session notes in this file
2. Create descriptive git commit
3. Include all modified files
4. Update status tracking

## 📋 Session Notes

### Recent Changes (Session 12)
- Implemented unified migration system
- Added schema drift prevention
- Created rollback scripts
- Enhanced deployment safeguards

### Known Working Features
- All authentication endpoints
- Park search and discovery
- Friend connections with QR codes
- Check-in system
- Privacy controls

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

---
*For detailed session history, see git commits. This file maintains current project state and essential protocols.*