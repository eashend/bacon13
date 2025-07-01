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
1. **Use latest Flutter version** - Run `flutter upgrade` regularly
2. **Run tests** to ensure all tests pass
3. **Build the project** to verify it compiles successfully  
4. **Fix any failing tests or build errors**
5. **Never commit secrets** - Use environment variables for Firebase configuration
6. **Then commit and push** to GitHub

```bash
# Flutter Development Workflow
flutter upgrade                 # Keep Flutter up to date
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

**SECURITY**: Always use environment variables for Firebase configuration. Never commit API keys to git.

```bash
# Setup and maintenance
flutter upgrade     # Always use latest Flutter version
flutter doctor      # Verify Flutter installation

# Setup Firebase secrets (REQUIRED)
cp .env.template .env  # Copy template
# Edit .env with real Firebase configuration (NEVER commit this file)

cd flutter_app
flutter pub get              # Install dependencies  
flutter run -d web           # Start development server (web)
flutter run                  # Start development server (mobile)
./build_with_secrets.sh web  # Secure build for web production
flutter test                 # Run unit tests
```

**Current Flutter Version**: 3.32.5 (Dart 3.8.1)  
**Update Frequency**: Check for updates weekly with `flutter upgrade`

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

### Firebase Configuration (SECURE)

**CRITICAL SECURITY**: Firebase configuration is now loaded from environment variables. API keys are NEVER committed to git.

```bash
# 1. Copy environment template
cp .env.template .env

# 2. Edit .env with your Firebase project configuration
# Get configuration from: firebase apps:sdkconfig
FIREBASE_API_KEY=your-web-api-key-here
FIREBASE_APP_ID=your-web-app-id-here
FIREBASE_MESSAGING_SENDER_ID=your-messaging-sender-id-here
FIREBASE_PROJECT_ID=your-project-id-here
FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_STORAGE_BUCKET=your-project-id.firebasestorage.app

# 3. The .env file is automatically ignored by git
# 4. Flutter app loads secrets via String.fromEnvironment()
```

### Deployment (SECURE)
```bash
# SECURE deployment with environment variables
./deploy_secure.sh YOUR_GCP_PROJECT_ID us-central1 prod

# OR manual secure deployment:
# 1. Ensure .env file exists with Firebase configuration
# 2. Build with secrets
cd flutter_app && ./build_with_secrets.sh web

# 3. Deploy to Firebase
firebase deploy --only hosting,firestore:rules,storage
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