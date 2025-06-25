# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bacon13 is a social media application with a Go microservices backend and React TypeScript frontend, deployed on Google Cloud Run. The app focuses on image-based posts with ML-powered user recognition features.

## Architecture

**Backend**: Go microservices architecture with shared models
- `auth-service` (port 8081): JWT authentication, user registration/login
- `user-service` (port 8080): User profiles and profile image management  
- `post-service` (port 8082): Image post creation and feeds
- `shared/`: Common database models, database connection, and API response types

**Frontend**: React TypeScript with Tailwind CSS
- Uses React Router for navigation
- Axios for API communication
- Testing setup with Jest and React Testing Library

**Infrastructure**: Google Cloud Platform
- Cloud Run for service deployment
- Firestore for document database
- Cloud Storage for image uploads
- Terraform for infrastructure as code

## Development Workflow

**IMPORTANT**: After completing any code changes, ALWAYS commit and push to GitHub:
```bash
git add .
git commit -m "Descriptive commit message"
git push origin main
```

## Development Commands

### Frontend Development
```bash
cd frontend
npm start          # Start development server
npm run build      # Build for production
npm test           # Run tests
```

### Backend Development
```bash
# Run individual services locally
cd backend/auth-service && go run main.go
cd backend/user-service && go run main.go  
cd backend/post-service && go run main.go

# Install dependencies
cd backend/[service-name] && go mod tidy
```

### Local Development Setup
```bash
# Set environment variables for local development
# Note: Firestore requires a GCP project - use Firestore emulator for local testing
export PROJECT_ID=your-project-id
export STORAGE_BUCKET=your-bucket-name

# To use Firestore emulator locally:
gcloud components install cloud-firestore-emulator
gcloud emulators firestore start --host-port=localhost:8080
export FIRESTORE_EMULATOR_HOST=localhost:8080
```

### Deployment
```bash
# Deploy to Google Cloud Run
./deploy.sh YOUR_GCP_PROJECT_ID us-central1 dev

# Manual infrastructure deployment
cd infrastructure
terraform init
terraform plan
terraform apply
```

## Key Components

### Firestore Collections
- `users`: User documents with id, email, password_hash, profile_images array, timestamps
- `posts`: Post documents with id, user_id, image_url, timestamps
- Uses UUID strings as document IDs for consistency

### Authentication Flow
- JWT tokens with 7-day expiration
- bcrypt password hashing
- Token validation middleware in shared package
- Bearer token format for API requests

### Shared Package
Contains common types and database utilities:
- `models.go`: User, Post, request/response structs with Firestore tags
- `database.go`: Firestore client initialization and connection management
- Uses Firestore native mode for real-time capabilities

### Service Communication
Services communicate via HTTP APIs with standardized JSON responses using the `APIResponse` struct.

## Environment Variables

All services use these environment variables (set automatically by Terraform in production):
- `PORT`: Service port number
- `PROJECT_ID`: GCP project identifier (required for Firestore)
- `STORAGE_BUCKET`: Cloud Storage bucket for images
- `ENVIRONMENT`: Deployment environment (dev/staging/prod)
- `FIRESTORE_EMULATOR_HOST`: For local development with Firestore emulator

## File Structure Notes

- Backend services follow Go project conventions with main.go entry points
- Frontend uses Create React App structure with TypeScript
- Infrastructure code is in Terraform format
- Each service has its own Dockerfile for containerization
- Go modules use local replacement for shared package via `replace` directive