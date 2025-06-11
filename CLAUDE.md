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

**Database**: PostgreSQL with simplified schema (PostGIS not yet installed for geospatial)
**Authentication**: JWT tokens with bcrypt password hashing
**Image Storage**: AWS S3 for profile and gallery images
**iOS Architecture**: MVVM + Coordinator pattern, cloud-first online-only approach
**Current Status**: Backend API and iOS app with authentication + dog profiles + photo uploads complete

[... rest of existing content remains the same ...]

## ✅ Recently Completed Features (June 2025)

**🆕 Complete Dog Profile Management (Latest Session):**
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

## Development Guidelines

- You should verify the server status at the start of each new session. If it is not running, start it in dev mode.
- Dog weight values come from PostgreSQL as strings - custom decoder handles this
- All gallery photos should display as squares with fixed dimensions to prevent overlap
- Delete operations use immediate deletion pattern for better UX
- Navigation uses NavigationLink with proper EnvironmentObject passing