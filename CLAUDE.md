# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BarkPark is a dog social network application consisting of:
- Node.js/Express backend API with PostgreSQL database
- iOS SwiftUI app with cloud-first architecture
- Features: user auth, dog profiles, park finder, social messaging, check-ins

## Architecture

**Backend (Node.js/Express):**
```
/config - Database connection and configuration
/models - Database models (User, Dog, DogPark, etc.)
/routes - API route handlers
/middleware - Authentication and validation middleware  
/scripts - Database initialization and utility scripts
```

**iOS App (SwiftUI):**
```
/iOS/BarkPark/BarkPark/
├── Core/
│   ├── Network/ - APIService with JWT authentication
│   ├── Design/ - Apple-style design system
│   ├── Authentication/ - AuthenticationManager
│   └── Navigation/ - RootView, MainTabView
├── Features/
│   ├── Authentication/ - Login/SignUp views
│   ├── DogProfiles/ - My Pack, Add Dog, Dog Detail
│   ├── DogParks/ - Parks discovery (placeholder)
│   ├── Social/ - Friends features (placeholder)
│   └── Profile/ - User settings
└── Models/ - Swift models matching backend API
```

**Database**: PostgreSQL with simplified schema (PostGIS not installed - using Haversine distance calculations)
**Authentication**: JWT tokens with bcrypt password hashing
**Image Storage**: AWS S3 for profile and gallery images
**iOS Architecture**: MVVM + Coordinator pattern, cloud-first online-only approach
**Current Status**: Backend API complete with dog parks & activity tracking + iOS app with auth & dog profiles

[... rest of existing content remains the same ...]

## ✅ Recently Completed Features (June 2025)

**🆕 Complete Dog Parks Backend API (Latest Session - June 11, 2025):**
- **Dog Park Discovery API** - Find nearby parks with distance-based filtering using Haversine formula
- **Real-time Activity Tracking** - Check-in/check-out system with park busyness levels (quiet/low/moderate/busy)
- **Social Features Foundation** - Friend detection at parks and activity statistics ready for implementation
- **Comprehensive Database Models** - DogPark and CheckIn models with full CRUD operations
- **12 Sample Parks** - Realistic park data seeded around Piermont, NY within 2-mile radius
- **Complete Test Suite** - 52 tests covering all API endpoints, error handling, and edge cases
- **Production-Ready Code** - Proper validation, authentication, and error handling throughout

**🔧 Backend API Endpoints Implemented:**
- `GET /api/parks` - Find nearby parks with latitude/longitude/radius filtering
- `GET /api/parks/:id` - Get detailed park info with activity stats and friend presence
- `GET /api/parks/:id/activity` - Real-time park activity level and visitor statistics
- `POST /api/parks/:id/checkin` - Check into park with optional dog companions list
- `PUT /api/parks/:id/checkout` - Check out with automatic visit duration tracking
- `GET /api/parks/user/history` - Personal check-in history with park details
- `GET /api/parks/user/active` - Current active check-ins across all parks
- `GET /api/parks/:id/friends` - Friends currently at specific park (foundation)
- `POST /api/parks` - Admin endpoint for creating new parks

**📊 Database Schema Additions:**
- **dog_parks table** - Name, description, address, lat/lng, amenities, rules, hours
- **checkins table** - User/park relationships with check-in/out timestamps and dog companions
- **Activity calculations** - Real-time park busyness based on active check-ins
- **Distance queries** - Haversine formula implementation for geographic proximity
- **Test database** - Automated schema initialization and data seeding for tests

**🎯 Technical Highlights:**
- **Distance Calculations** - Efficient Haversine formula without PostGIS dependency
- **Activity Levels** - Dynamic calculation: 0=quiet, 1-3=low, 4-8=moderate, 9+=busy
- **Park Statistics** - Total check-ins, current visitors, average visit duration
- **Comprehensive Testing** - Parks API (32 tests) + CheckIn model (20 tests) all passing
- **Error Handling** - Validation for coordinates, park existence, duplicate check-ins
- **Security** - JWT authentication required on all protected endpoints

**🆕 Complete Dog Profile Management (Previous Session):**
- **Full CRUD Operations** - Create, Read, Update, and Delete dog profiles with confirmation
- **Dog Deletion** - Added delete functionality with confirmation dialog and loading overlay  
- **Navigation Fix** - Dog cards in "My Pack" now properly navigate to detail view
- **Gallery Photo Management** - Immediate deletion on trash icon tap (no save required)
- **Photo Display Fix** - All gallery grids now show photos as squares to prevent overlap
- **Model Decoding Fix** - Handle PostgreSQL DECIMAL values (weight) returned as strings

**🔧 Key Technical Improvements:**
- **Dog Model** - Added custom decoder to handle weight as string or double from PostgreSQL
- **APIService** - Added `deleteDog()` method for profile deletion
- **DogProfileViewModel** - Added `deleteDog()` method with local state management
- **Gallery Management** - Changed from mark-and-save to immediate deletion workflow
- **Photo Grid Layout** - Fixed aspect ratio issues with square frames (100x100, 150x150) and `.clipped()`
- **Navigation** - Added NavigationLink wrapper to DogCard for proper detail view navigation

**📱 UI/UX Enhancements:**
- **Delete Flow** - Menu button → Delete option → Confirmation → Loading overlay → Auto-dismiss
- **Gallery Interaction** - X button marks for deletion, trash overlay deletes immediately  
- **Photo Display** - All galleries use consistent square format to prevent overlap
- **Visual Feedback** - "Tap to delete" on red overlay, proper spacing between photos
- **Error Messages** - Clear feedback for all operations with specific error handling

**🎯 Current State:**
- Dog profiles fully functional with complete CRUD operations
- Gallery management with immediate photo deletion working
- All photo displays properly formatted as squares
- Navigation working throughout the app  
- Ready for next development phase (dog parks, social features)

## 🚀 Next Development Phase: iOS Dog Park Integration

### **Phase 1: iOS Map Interface (High Priority)**
**Goal**: Implement map-based park discovery with real-time activity display

**iOS Implementation Tasks:**
1. **MapKit Integration**
   - Add MapKit framework and location permissions to iOS app
   - Implement user location services with proper privacy handling
   - Create custom park annotations with activity level indicators

2. **Park Discovery View**
   - Replace placeholder DogParksView with full MapKit implementation
   - Add floating search controls and radius filtering
   - Implement park clustering for performance with many markers

3. **Park Detail Integration**
   - Create comprehensive park detail view consuming backend API
   - Display amenities, rules, hours, current activity, and photos
   - Add check-in/check-out functionality with iOS UI

4. **APIService Extensions**
   - Add Swift models for DogPark and CheckIn matching backend schema
   - Implement all park-related API calls in APIService.swift
   - Handle location-based queries and activity updates

### **Phase 2: Social Features (Medium Priority)**
**Goal**: Enable friend discovery and social interactions at parks

**Backend Tasks:**
1. **Friendship System**
   - Implement friend request/accept API endpoints
   - Add friend discovery features (search, suggestions)
   - Enhance park friend detection with real user relationships

2. **Real-time Features**
   - Add WebSocket support for live park activity updates
   - Implement push notifications for friend check-ins
   - Create activity feed for friend park visits

**iOS Tasks:**
1. **Social Integration**
   - Add friend management views and workflows
   - Implement real-time friend presence at parks
   - Add social notifications and activity feeds

### **Phase 3: Enhanced Park Features (Future)**
**Goal**: Advanced park features and community engagement

**Potential Features:**
- Park photo uploads from users
- Park reviews and ratings system
- Event scheduling and park meetups
- Advanced park filtering (amenities, size, etc.)
- Park check-in streaks and gamification
- Weather integration for park conditions

## Development Guidelines

### **Backend Development:**
- Server runs on port 3000 - verify status at start of each session
- Use `npm test` to run comprehensive test suite (52 tests)
- Park data seeded around Piermont, NY coordinates (41.0387, -73.9215)
- Distance calculations use Haversine formula (no PostGIS required)
- All park endpoints require JWT authentication

### **iOS Development:**
- Dog weight values come from PostgreSQL as strings - custom decoder handles this
- All gallery photos should display as squares with fixed dimensions to prevent overlap
- Delete operations use immediate deletion pattern for better UX
- Navigation uses NavigationLink with proper EnvironmentObject passing
- Location services will require proper Info.plist permissions for park discovery

### **Testing & Quality:**
- Backend: 32 Parks API tests + 20 CheckIn model tests (all passing)
- iOS: Existing auth and dog profile tests should continue passing
- Test with realistic park data around Piermont, NY for location accuracy
- Ensure proper error handling for location permissions and network issues