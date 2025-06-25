# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bacon13 is a social media application with a mobile-first Flutter architecture using Firebase services. The app focuses on image-based posts with real-time capabilities.

## Architecture

**Mobile-First Architecture**: Flutter with Firebase SDK
- Flutter with Material Design for cross-platform UI (iOS, Android, Web)
- Firebase Authentication for user management
- Firestore for real-time database operations
- Firebase Storage for image uploads
- Firebase Hosting for web deployment

**No Backend Services**: Flutter app communicates directly with Firebase
- Authentication handled by Firebase Auth SDK
- Data operations via Firestore SDK
- Image uploads via Firebase Storage SDK
- Real-time updates with Firestore listeners

**Infrastructure**: Google Cloud Platform + Firebase
- Firebase Authentication for user management
- Firestore for document database
- Firebase Storage for image uploads
- Firebase Hosting for frontend deployment
- Terraform for infrastructure provisioning

## Development Workflow

**CRITICAL**: Before committing ANY code changes, ALWAYS:
1. **Run tests** to ensure all tests pass
2. **Build the project** to verify it compiles successfully  
3. **Fix any failing tests or build errors**
4. **Then commit and push** to GitHub

```bash
# Flutter Development Workflow
flutter test                    # ALWAYS run tests first
flutter build web              # Verify build works
git add .                      # Stage changes only after tests pass
git commit -m "Descriptive commit message"
git push origin main

# React Development Workflow (deprecated - migrated to Flutter)
cd frontend
npm test                       # ALWAYS run tests first
npm run build                  # Verify build works  
cd ..
git add .                      # Stage changes only after tests pass
git commit -m "Descriptive commit message"
git push origin main
```

**NEVER commit without running tests first** - this prevents broken code from entering the repository.

## Development Commands

### Flutter Development
```bash
cd flutter_app
flutter pub get    # Install dependencies  
flutter run -d web # Start development server (web)
flutter run        # Start development server (mobile)
flutter build web  # Build for web production
flutter test        # Run unit tests
```

### Legacy React Development (Deprecated - Migrated to Flutter)
```bash
cd frontend
npm install        # Install dependencies
npm start          # Start development server
npm run build      # Build for production
npm test           # Run tests
```

### Firebase Emulation (Local Development)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start Firebase emulators
firebase emulators:start

# In another terminal, set environment for local emulation
export REACT_APP_USE_EMULATOR=true
cd frontend && npm start
```

### Firebase Configuration
```bash
# Create .env file in frontend/ directory
REACT_APP_FIREBASE_API_KEY=your-api-key
REACT_APP_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
REACT_APP_FIREBASE_PROJECT_ID=your-project-id
REACT_APP_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
REACT_APP_FIREBASE_APP_ID=your-app-id
```

### Deployment
```bash
# Deploy Firebase infrastructure and frontend
./deploy.sh YOUR_GCP_PROJECT_ID us-central1 dev

# Manual deployment steps:
# 1. Deploy infrastructure
cd infrastructure && terraform apply

# 2. Deploy Firebase rules
firebase deploy --only firestore:rules
firebase deploy --only storage

# 3. Deploy frontend
cd frontend && npm run build
firebase deploy --only hosting
```

## Key Components

### Firestore Collections
- `users`: User documents with Firebase UID as ID, email, profile_images array, timestamps
- `posts`: Post documents with UUID as ID, user_id (Firebase UID), image_url, timestamps
- Users use Firebase UID strings as document IDs, posts use UUID strings

### Authentication Flow
- Firebase Authentication SDK for user registration/login
- Client-side Firebase Auth state management
- Automatic user profile creation in Firestore on first login
- Firebase Auth guards for protected routes
- Real-time auth state synchronization

### Frontend Services
- `authService.ts`: Firebase Auth wrapper functions for login/register/signout
- `postService.ts`: Firestore operations for posts and image uploads
- `AuthContext.tsx`: React context for authentication state management
- Components organized by feature (Auth/, Posts/)
- Firebase SDK handles all backend communication

### Security
- Firestore security rules enforce data access permissions
- Firebase Storage rules control image upload permissions
- Client-side Firebase Auth provides secure authentication
- No custom backend reduces attack surface

## Environment Variables

Frontend uses these environment variables (set in .env file):
- `REACT_APP_FIREBASE_API_KEY`: Firebase API key
- `REACT_APP_FIREBASE_AUTH_DOMAIN`: Firebase Auth domain
- `REACT_APP_FIREBASE_PROJECT_ID`: Firebase project ID
- `REACT_APP_FIREBASE_STORAGE_BUCKET`: Firebase Storage bucket
- `REACT_APP_FIREBASE_MESSAGING_SENDER_ID`: Firebase messaging sender ID
- `REACT_APP_FIREBASE_APP_ID`: Firebase app ID
- `REACT_APP_USE_EMULATOR`: For local development with Firebase emulators

## File Structure Notes

- Frontend uses Create React App structure with TypeScript
- Firebase configuration files in project root (firebase.json, firestore.rules, storage.rules)
- Infrastructure code uses Terraform for Firebase resource provisioning
- React components organized by feature in src/components/
- Firebase services abstracted in src/services/
- Authentication state managed via React Context
- No backend directories - pure frontend architecture