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

## Environment Setup

**PostgreSQL Setup** (macOS with Homebrew):
```bash
# Install PostgreSQL 15
brew install postgresql@15
export PATH="/usr/local/opt/postgresql@15/bin:$PATH"

# Start service
brew services start postgresql@15

# Create database
createdb barkpark

# Initialize schema (use simple version for now)
psql -d barkpark -f scripts/init-db-simple.sql

# Update dogs table with comprehensive profile fields (run once)
psql -d barkpark -f scripts/update-dogs-table.sql
```

**Environment Variables**:
- Copy `.env.example` to `.env`
- Set `DB_USER` to your macOS username (not 'postgres')
- Leave `DB_PASSWORD` empty for local development
- JWT_SECRET is set for development
- AWS S3 credentials required for image uploads (see S3 setup below)

**AWS S3 Setup** (for photo uploads):
```bash
# 1. Create S3 bucket (must be globally unique)
# - Bucket name: barkpark-images-[your-name]
# - Region: us-east-1 (matches .env default)
# - Disable "Block all public access" 

# 2. Create IAM user with S3 permissions
# - User: barkpark-s3-user
# - Policy: Custom policy with bucket access (see below)
# - Generate access keys

# 3. Set bucket policy for public read access:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
    }
  ]
}

# 4. IAM policy for user:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:PutObjectAcl"],
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
    },
    {
      "Effect": "Allow", 
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME"
    }
  ]
}
```

**Update .env with S3 credentials**:
```bash
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key  
AWS_REGION=us-east-1
S3_BUCKET_NAME=barkpark-images-[your-name]
```

**iOS App Setup**:
- Xcode 15+ required for iOS 16+ target
- Project located in `/iOS/BarkPark/BarkPark.xcodeproj`
- No external dependencies - uses native SwiftUI and Foundation
- Backend must be running on localhost:3000 for API calls

## Development Commands

**Backend:**
```bash
# Install dependencies
npm install

# Start development server with auto-reload
npm run dev

# Start production server
npm start

# Test server is running
curl http://localhost:3000/health
```

**iOS App:**
```bash
# Open Xcode project
open iOS/BarkPark/BarkPark.xcodeproj

# Build and run in simulator (from Xcode)
# Cmd+R or Product → Run

# Ensure backend is running first:
npm run dev
```

## Completed Features

**✅ JWT Authentication System**:
- User registration with validation
- Login with password verification
- JWT token generation and validation
- Protected routes with Bearer token auth
- Password hashing with bcrypt

**✅ Dog Profile System**:
- Complete CRUD operations for dog profiles
- Comprehensive profile data (personality, health, activities)
- **AWS S3 image upload working** (profile photo + gallery)
- JSON field support for activities and gallery images
- Age calculation from birthday
- User ownership validation and security
- **Photo upload endpoints fully functional**

**✅ iOS SwiftUI App**:
- Apple-style design system with modern UI/UX
- Complete authentication flow (Welcome, Login, SignUp)
- Cloud-first architecture with online-only data flow
- "My Pack" view showcasing dogs with profile photos
- Add Dog form with profile photo picker (PhotosPicker iOS 16+)
- **Photo upload functionality working** (profile photos to S3)
- TabView navigation with 4 main sections
- MVVM architecture with ObservableObject view models
- JWT token management and API integration
- **Image processing and compression** for optimal uploads

**Authentication API Endpoints**:
- `POST /api/auth/register` - Create new user account
- `POST /api/auth/login` - Authenticate and get JWT token
- `GET /api/auth/me` - Get current user profile (protected)
- `PUT /api/auth/me` - Update user profile (protected)

**Dog Profile API Endpoints**:
- `GET /api/dogs` - Get all user's dogs
- `POST /api/dogs` - Create new dog profile
- `GET /api/dogs/:id` - Get specific dog
- `PUT /api/dogs/:id` - Update dog profile
- `DELETE /api/dogs/:id` - Delete dog profile
- `POST /api/dogs/:id/profile-image` - Upload profile photo
- `POST /api/dogs/:id/gallery` - Upload gallery photos (up to 5)
- `DELETE /api/dogs/:id/gallery` - Remove gallery photo

## Testing

```bash
# Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","firstName":"John","lastName":"Doe"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Access protected route (use token from login response)
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Create dog profile
curl -X POST http://localhost:3000/api/dogs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "name": "Buddy",
    "breed": "Golden Retriever",
    "birthday": "2020-05-15",
    "weight": 65.5,
    "gender": "male",
    "sizeCategory": "large",
    "energyLevel": "high",
    "friendlinessDogs": 5,
    "friendlinessPeople": 4,
    "trainingLevel": "advanced",
    "favoriteActivities": ["fetch", "swimming", "hiking"],
    "isVaccinated": true,
    "isSpayedNeutered": true,
    "bio": "Buddy is a friendly and energetic Golden Retriever"
  }'

# Get all dogs for user
curl -X GET http://localhost:3000/api/dogs \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Upload profile photo (replace DOG_ID and image.jpg)
curl -X POST http://localhost:3000/api/dogs/DOG_ID/profile-image \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "image=@image.jpg"

# Upload gallery photos (up to 5 images)
curl -X POST http://localhost:3000/api/dogs/DOG_ID/gallery \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "images=@image1.jpg" \
  -F "images=@image2.jpg"
```

**iOS App Testing:**
```bash
# 1. Start backend server
npm run dev

# 2. Open iOS project in Xcode
open iOS/BarkPark/BarkPark.xcodeproj

# 3. Run in simulator (Cmd+R)
# 4. Test authentication flow:
#    - Welcome screen → "Get Started" → Create account
#    - Welcome screen → "Already have account" → Login
# 5. Test dog profiles:
#    - Empty state → "Add Your First Dog"
#    - Fill form → "Add [Dog Name]" button
#    - View dog list in "My Pack"
#    - Tap dog card → View dog details
```

## iOS Photo Upload Implementation

**✅ Complete Photo Upload System**:
- **PhotosPicker Integration**: Native iOS 16+ photo selection
- **Image Processing**: Automatic resize (1024px max) and compression (3MB target)  
- **Multipart Upload**: Full multipart/form-data support in APIService
- **Profile Photos**: Upload during dog creation in AddDogView
- **Photo Display**: AsyncImage in MyPackView dog cards with paw print fallback
- **Error Handling**: Comprehensive error management and user feedback

**Key iOS Components**:
```swift
// Core photo upload files
iOS/BarkPark/BarkPark/Core/Network/ImageProcessor.swift      // Image validation, resize, compression
iOS/BarkPark/BarkPark/Core/Network/APIService.swift          // Multipart upload methods
iOS/BarkPark/BarkPark/Features/DogProfiles/Views/AddDogView.swift  // Photo picker UI
iOS/BarkPark/BarkPark/Features/DogProfiles/ViewModels/DogProfileViewModel.swift  // Upload logic
```

**Photo Upload Flow**:
1. User selects photo via PhotosPicker in AddDogView
2. Image processed (resize to 1024px, compress to <3MB)
3. Dog profile created via API
4. Profile photo uploaded to S3 via multipart request
5. Dog data updated with S3 image URL
6. Photo displays in MyPackView AsyncImage

**Image Processing Pipeline**:
- **Validation**: PNG/JPEG/WebP format check
- **Resize**: Max 1024px (optimal for profile photos)
- **Compress**: Target 3MB (accounts for multipart overhead)
- **Upload**: Multipart/form-data with proper boundaries
- **Display**: AsyncImage with placeholder fallback

**Technical Notes**:
- Uses PhotosUI framework (requires iOS 16+)
- All photo operations are async/await with MainActor compliance
- Images automatically compressed to prevent 5MB backend limit issues
- Comprehensive test coverage for all photo functionality
- Supports both profile photos and gallery images (gallery UI pending)

## ✅ iOS App Status: COMPLETE AND WORKING

**Current Status (June 2025)**: 
- ✅ **Full iOS SwiftUI app implemented** and working end-to-end
- ✅ **Complete photo upload system** with iOS 16+ PhotosPicker
- ✅ **Authentication flow** (Welcome → Login/Register → My Pack)
- ✅ **Dog profile creation** with comprehensive form validation
- ✅ **Photo uploads to S3** working correctly
- ✅ **All bugs fixed** - app creates dog profiles successfully

**Recent Fixes Applied**:
1. **Fixed model mismatches** - Updated iOS models to match backend API responses
2. **Fixed JSON decoding** - Added ISO8601 date handling for backend dates  
3. **Fixed enum validation** - Aligned iOS form values with backend validation rules
4. **Fixed activities selector** - Resolved UI bug with multi-selection
5. **Added submit button** - Proper "Add [Dog Name]" button at bottom of form
6. **Fixed photo upload flow** - Complete multipart/form-data implementation

**Enum Value Alignment (iOS ↔ Backend)**:
- **Energy Level**: `["low", "medium", "high"]` (was `["low", "moderate", "high", "very_high"]`)  
- **Size Category**: `["small", "medium", "large"]` (was `["small", "medium", "large", "extra_large"]`)
- **Training Level**: `["puppy", "basic", "advanced"]` (was `["untrained", "basic", "intermediate", "advanced"]`)
- **Gender**: `["male", "female"]` (backend also accepts `"unknown"`)

**Working Features**:
- **Authentication**: Login/register with JWT tokens, persistent sessions
- **Dog Profiles**: Full CRUD with personality traits, health info, activities
- **Photo Uploads**: Profile photos + gallery images with S3 integration
- **Image Processing**: Automatic resize (1024px) + compression (3MB target)
- **Form Validation**: Real-time validation with proper error handling
- **Apple Design**: Native iOS 16+ UI with PhotosPicker integration

**Test Coverage**:
- ✅ Unit tests for photo upload functionality
- ✅ API service tests with multipart form data
- ✅ Image processor tests for resize/compression
- ✅ UI tests for complete photo upload workflow

**Development Commands Working**:
```bash
# Backend (Terminal 1)
cd backend && npm run dev

# iOS App (Terminal 2) 
open ios/BarkPark/BarkPark.xcodeproj
# Build and run in Xcode simulator
```

**End-to-End Workflow Verified**:
1. Start backend server (`npm run dev`)
2. Launch iOS app in Xcode simulator
3. Create account or login with existing user
4. Navigate to "My Pack" → "Add Your First Dog" OR tap existing dog → "Edit"
5. Fill complete form with photo selection
6. Press "Add [Dog Name]" or "Save Changes" → Profile created/updated successfully
7. View dog list with profile photos displayed
8. **Gallery Management**: Add up to 5 photos, remove photos, set profile photo from gallery

**Architecture Confirmed Working**:
- 📱 **iOS 16+ target** with PhotosPicker
- 🏗️ **MVVM + Coordinator** pattern with ObservableObject view models
- 🌐 **Cloud-first** approach with online-only data flow
- 🔐 **JWT authentication** with UserDefaults persistence
- 🎨 **Apple-style design** system with semantic colors/spacing
- 📸 **Complete photo pipeline** from picker → processing → S3 upload → display

## ✅ Recently Completed Features (June 2025)

**🆕 Dog Profile Editing with Gallery Management:**
- **Complete EditDogView** - Full editing interface with pre-populated form fields
- **Gallery management** - Add up to 5 photos, remove individual photos with visual grid
- **Profile photo selection from gallery** - Choose any gallery image as profile photo via dedicated picker sheet
- **Backend API extensions** - New `PUT /api/dogs/:id/profile-image-from-gallery` endpoint
- **Model fixes** - Made `breed` and `birthday` optional to handle legacy data
- **Connection debugging** - Resolved iOS simulator network issues (localhost → 127.0.0.1)
- **Git repository cleanup** - Proper .gitignore for iOS, removed user-specific files

**🔐 Authentication Error Handling Improvements:**
- **Enhanced APIService error handling** - Properly parse and display backend error messages
- **Status code handling** - Different error types for 400, 401, 409, and 500+ responses
- **User-friendly error messages** - Show actual error reasons instead of generic "Invalid response"
- **Comprehensive debugging logs** - Track authentication flow for troubleshooting

**🔧 Key Technical Improvements:**
- **iOS APIService** - Added updateDog(), setProfileImageFromGallery(), removeGalleryImage() methods
- **DogProfileViewModel** - Enhanced with editing and gallery management functionality  
- **Error handling** - Comprehensive debugging logs for API calls and data flow
- **JSON decoding fixes** - Handle null breed/birthday values from legacy dog records
- **Repository structure** - Clean iOS file tracking, excluded xcuserdata and *.xcuserstate

**📱 UI/UX Enhancements:**
- **Apple-style editing interface** with consistent design system
- **Visual gallery management** with drag-to-remove functionality
- **Profile photo picker sheet** for selecting from existing gallery images
- **Form pre-population** from existing dog data with proper validation
- **Real-time error feedback** and loading states

## Pending Features

- Dog park geospatial queries (needs PostGIS installation)
- Friend connections and social features
- Real-time messaging with Socket.io
- Park administrator notices
- Check-in functionality for dogs visiting parks

## Database Notes

**Schema Evolution:**
- Started with simplified schema (`scripts/init-db-simple.sql`)
- Dogs table enhanced with comprehensive profile fields (`scripts/update-dogs-table.sql`)
- Currently using `latitude/longitude` columns instead of PostGIS `GEOMETRY` type
- When PostGIS is installed later, migrate to use `scripts/init-db.sql` for proper geospatial support

**Dog Profile Data Structure:**
- Core: name, breed, birthday (age calculated), weight, gender, size
- Personality: energy level, friendliness scales (1-5), training level, activities (JSON array)
- Health: vaccination status, spay/neuter status, special needs
- Media: profile image URL, gallery images (JSON array)
- All images stored in AWS S3 with automatic cleanup on deletion

**Key Technical Notes:**
- PostgreSQL JSON fields require special parsing in Node.js model layer
- S3 integration handles file uploads with unique naming and organized folder structure
- Database constraints enforce valid enum values and friendliness scale ranges

**iOS Technical Notes:**
- Custom date formatter required for backend JSON dates (yyyy-MM-dd'T'HH:mm:ss.SSS'Z')
- APIService handles JWT token persistence in UserDefaults automatically
- Design system uses Apple's semantic colors and spacing (16pt grid system)
- Models use camelCase naming to match backend API responses
- Cloud-first approach: all data flows through API calls, minimal local storage
- AuthenticationManager and DogProfileViewModel use @MainActor for UI updates
- **IMPORTANT**: Use `127.0.0.1:3000` instead of `localhost:3000` for iOS Simulator compatibility
- **Model flexibility**: `breed` and `birthday` are optional in Dog model to handle legacy/incomplete data
- **Debugging**: Comprehensive logging in APIService and ViewModels for troubleshooting data flow
- **Authentication Error Handling**: APIService properly parses backend error messages for login/register failures
  - Login errors (401): "Invalid email or password" displayed to user
  - Registration errors (409): "User with this email already exists"
  - Validation errors (400): Field-specific error messages
  - Server errors (500+): "Server error occurred. Please try again later."

## Deployment

Repository: https://github.com/arathe/BarkPark
Ready for Railway/Render deployment with environment variable configuration.