# Bacon13 App - Firebase Frontend-Only Architecture

A social media application built with React TypeScript frontend using Firebase services directly - no backend required!

## Architecture

- **Frontend**: React TypeScript with Tailwind CSS
- **Authentication**: Firebase Authentication
- **Database**: Firestore (NoSQL document database)
- **Storage**: Firebase Storage for images
- **Hosting**: Firebase Hosting
- **Infrastructure**: Terraform for Firebase resource provisioning

## Features

### Must Have (MVP)
- ✅ User registration and login with Firebase Auth
- ✅ Image post uploads to Firebase Storage
- ✅ View own posts in reverse chronological order
- ✅ Public feed with latest posts
- ✅ Real-time data synchronization with Firestore
- ✅ Responsive UI with Tailwind CSS
- ✅ Firebase Hosting deployment

### Should Have
- 🔄 Real-time notifications
- 🔄 User profile customization
- 🔄 Image compression and optimization

### Could Have
- 🔄 Social features (likes, comments)
- 🔄 Pagination/lazy loading
- 🔄 Advanced search and filters

## Frontend Features

### Authentication
- Email/password registration and login
- Real-time authentication state management
- Automatic user profile creation in Firestore
- Protected routes and components

### Posts Management
- Direct image upload to Firebase Storage
- Create posts with image validation
- View personal posts and public feed
- Real-time post updates

### UI/UX
- Responsive design with Tailwind CSS
- Loading states and error handling
- Clean, modern interface
- Mobile-friendly layout

## Prerequisites

1. **Google Cloud Platform Account**
   - Create a GCP project
   - Enable billing

2. **Firebase Setup**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Initialize Firebase in your project
   firebase init
   ```

3. **Required Tools**
   ```bash
   # Install Node.js and npm
   # https://nodejs.org/
   
   # Install Google Cloud CLI
   # https://cloud.google.com/sdk/docs/install
   
   # Install Terraform
   # https://learn.hashicorp.com/tutorials/terraform/install-cli
   ```

4. **Authentication**
   ```bash
   # Authenticate with Google Cloud
   gcloud auth login
   
   # Set up application default credentials
   gcloud auth application-default login
   ```

## Quick Deployment

1. **Clone and Setup**
   ```bash
   git clone <your-repo>
   cd bacon13
   chmod +x deploy.sh
   ```

2. **Configure Firebase**
   ```bash
   # Create frontend/.env file with your Firebase config
   cp frontend/.env.example frontend/.env
   # Edit with your Firebase project credentials
   ```

3. **Deploy to Firebase**
   ```bash
   ./deploy.sh YOUR_GCP_PROJECT_ID us-central1 dev
   ```

   This script will:
   - Enable required Firebase APIs
   - Deploy infrastructure with Terraform
   - Deploy Firestore and Storage security rules
   - Build and deploy frontend to Firebase Hosting

## Manual Deployment

### 1. Infrastructure Setup

```bash
cd infrastructure
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project details
terraform plan
terraform apply
```

### 2. Deploy Firebase Rules and Frontend

```bash
# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy Storage security rules  
firebase deploy --only storage

# Build and deploy frontend
cd frontend
npm install
npm run build
firebase deploy --only hosting
```

## Frontend Structure

### Main Components
```
src/
├── components/
│   ├── Auth/
│   │   ├── LoginForm.tsx
│   │   └── RegisterForm.tsx
│   └── Posts/
│       ├── CreatePost.tsx
│       └── PostList.tsx
├── contexts/
│   └── AuthContext.tsx
├── services/
│   ├── authService.ts
│   └── postService.ts
└── firebase/
    └── config.ts
```

### Key Features
- **Authentication**: Firebase Auth with email/password
- **Data Storage**: Firestore for user profiles and posts
- **File Upload**: Firebase Storage for images
- **Real-time Updates**: Firestore listeners for live data
- **Security**: Client-side security rules enforcement

## Environment Variables

Create a `.env` file in the `frontend/` directory with your Firebase configuration:

```bash
REACT_APP_FIREBASE_API_KEY=your-api-key
REACT_APP_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
REACT_APP_FIREBASE_PROJECT_ID=your-project-id
REACT_APP_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
REACT_APP_FIREBASE_APP_ID=your-app-id
```

### Local Development

### 1. Frontend Setup
```bash
cd frontend
npm install
npm start
```

### 2. Firebase Emulation (Optional)
```bash
# Install and start Firebase emulators
npm install -g firebase-tools
firebase emulators:start

# In another terminal, run frontend with emulator
export REACT_APP_USE_EMULATOR=true
cd frontend && npm start
```

## Monitoring and Logs

```bash
# View Firebase Hosting logs
firebase projects:list

# Monitor Firebase services in console
echo "Firebase Console: https://console.firebase.google.com/project/YOUR_PROJECT_ID"
echo "Firestore: https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore"
echo "Storage: https://console.firebase.google.com/project/YOUR_PROJECT_ID/storage"
echo "Authentication: https://console.firebase.google.com/project/YOUR_PROJECT_ID/authentication"

# Check deployment status
firebase hosting:sites:list
```

## Security Considerations

- Firestore security rules enforce data access permissions
- Firebase Storage rules control file upload permissions
- Firebase Auth handles secure authentication automatically
- Client-side validation and server-side security rules
- HTTPS enabled by default on Firebase Hosting
- No custom backend reduces attack surface

## Scaling

Firebase services automatically scale:
- **Firestore**: Scales automatically with usage
- **Firebase Storage**: Handles any number of uploads
- **Firebase Auth**: Supports millions of users
- **Firebase Hosting**: Global CDN with automatic scaling
- No server management required

## Cost Optimization

- **Firebase pricing is pay-per-use**:
  - Firestore: Per document read/write/delete
  - Storage: Per GB stored and bandwidth
  - Auth: Free up to 50,000 MAU
  - Hosting: Free tier includes 10GB hosting
- **No idle costs** - only pay for actual usage
- Monitor usage in Firebase Console

## Next Steps

1. **Enhanced Features**:
   - Add real-time notifications
   - Implement social features (likes, comments)
   - Add image compression and optimization
   - Create user profile customization

2. **Performance**:
   - Implement pagination for large feeds
   - Add image lazy loading
   - Optimize Firestore queries with indexes
   - Add caching strategies

3. **Development**:
   - Set up CI/CD pipeline with GitHub Actions
   - Add comprehensive testing suite
   - Implement error monitoring (Sentry)
   - Add analytics (Google Analytics)

## Troubleshooting

### Common Issues

1. **Firebase Configuration Errors**
   - Verify `.env` file exists in `frontend/` directory
   - Check all Firebase config values are correct
   - Ensure Firebase project is properly initialized

2. **Authentication Issues**
   - Verify Firebase Auth is enabled in Firebase Console
   - Check email/password provider is enabled
   - Ensure correct Firebase project ID in config

3. **Firestore Permission Errors**
   - Verify Firestore security rules are deployed
   - Check user is authenticated before accessing data
   - Ensure rules allow the operation being attempted

4. **Storage Upload Errors**
   - Verify Firebase Storage rules are deployed
   - Check file size limits (5MB for posts, 2MB for profiles)
   - Ensure user is authenticated for uploads

5. **Deployment Issues**
   - Run `firebase login` to authenticate
   - Check `firebase use PROJECT_ID` is set correctly
   - Verify all required APIs are enabled in GCP

For more help, check the Firebase documentation: https://firebase.google.com/docs
