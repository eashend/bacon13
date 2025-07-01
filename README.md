# Bacon13 - Intelligent Photo Sharing App

A cross between Google Photos and Instagram with AI-powered facial detection, automatic person recognition, and friend suggestions based on photo co-appearance frequency. Built with Flutter and Firebase.

## 🎯 Vision
A hybrid of Google Photos and Instagram that automatically detects faces in uploaded photos, organizes them by people, and suggests friendships based on photo co-appearance frequency.

## 🏗️ Current Architecture

- **Frontend**: Flutter (Mobile-first, cross-platform)
- **Authentication**: Firebase Authentication
- **Database**: Firestore (NoSQL document database)
- **Storage**: Firebase Storage for images
- **Hosting**: Firebase Hosting (Web deployment)
- **Infrastructure**: Terraform for Firebase resource provisioning
- **ML/AI**: Google Vision AI (planned) for facial detection
- **Processing**: Cloud Functions for serverless ML pipeline

## 🚀 Features

### ✅ Current Features (MVP Complete)
- User registration and login with Firebase Auth
- Photo uploads to Firebase Storage
- View personal posts and public feed
- Real-time data synchronization with Firestore
- Flutter Material Design UI (iOS, Android, Web)
- Firebase Hosting deployment
- Comprehensive test coverage (27 unit tests)

### 🔄 Next Phase: AI & Social Features
- **Facial Detection**: Automatic face detection in uploaded photos
- **Person Recognition**: Cluster similar faces into person entities
- **Smart Organization**: Auto-generate albums by person
- **Friend Suggestions**: ML-powered suggestions based on photo co-appearance
- **Social Graph**: Build relationships through shared photos
- **Privacy Controls**: Granular consent and data management

---

## 📋 Implementation Roadmap

### **Phase 1: Core ML Infrastructure** (Weeks 1-3)

#### **1.1 Facial Detection Service**
- **Technology**: Google Vision AI or AWS Rekognition
- **Integration**: Cloud Functions for serverless processing
- **Workflow**: Photo upload → Face detection → Store face coordinates
- **Data Storage**: Face bounding boxes, confidence scores

#### **1.2 Face Recognition Pipeline**
- **Face Encoding**: Generate 128-dimensional face embeddings
- **Storage**: Firestore collection for face vectors
- **Clustering**: Group similar faces using cosine similarity
- **Person Creation**: Auto-create "Person" entities from clusters

#### **1.3 Enhanced Data Models**
```typescript
Person {
  id: string
  name?: string  // User-assigned or null for unknown
  faceCount: number
  representativeFaceId: string
  createdAt: timestamp
  isVerified: boolean
}

Photo {
  id: string
  userId: string
  imageUrl: string
  faces: FaceDetection[]
  people: string[]  // Person IDs detected
  location?: GeoPoint
  createdAt: timestamp
  processedAt?: timestamp
}

FaceDetection {
  personId?: string
  boundingBox: {x, y, width, height}
  confidence: number
  embedding: number[]  // 128-dim vector
}
```

### **Phase 2: Friend Suggestion Algorithm** (Weeks 4-5)

#### **2.1 Co-appearance Analysis**
- **Frequency Tracking**: Count photos where two people appear together
- **Relationship Scoring**: Weight by recency and photo count
- **Mutual Friends**: Boost scores for people with mutual connections

#### **2.2 Friend Suggestion Logic**
```typescript
FriendSuggestion {
  suggestedPersonId: string
  confidence: number
  sharedPhotoCount: number
  recentInteractions: number
  mutualFriends: number
  reason: "frequent_photos" | "mutual_friends" | "recent_activity"
}
```

#### **2.3 Social Graph**
- **Friendship Model**: Bidirectional relationships
- **Privacy Levels**: Public, friends-only, private photos
- **User Controls**: Block suggestions, manual friend requests

### **Phase 3: Advanced Photo Features** (Weeks 6-8)

#### **3.1 Smart Organization**
- **People Albums**: Auto-generated albums per person
- **Timeline View**: Chronological photo browsing
- **Search by Person**: "Show me all photos with John"
- **Bulk Actions**: Tag/organize multiple photos

#### **3.2 Social Features**
- **Photo Tagging**: User confirms/corrects person identification
- **Sharing**: Send specific person's photos to them
- **Collaborative Albums**: Shared albums with auto-contribution
- **Memory Prompts**: "1 year ago with Sarah"

### **Phase 4: Privacy & User Experience** (Weeks 9-10)

#### **4.1 Privacy Framework**
- **Consent Management**: Explicit opt-in for face detection
- **Data Control**: Delete face data, opt-out options
- **GDPR Compliance**: Data export, deletion rights
- **Biometric Data Protection**: Encrypted face embeddings

#### **4.2 UI/UX Enhancements**
- **Person Management**: Name, merge, split person clusters
- **Friend Suggestions UI**: Swipe to accept/reject suggestions
- **Photo Review**: Confirm face detections before processing
- **Settings**: Granular privacy controls

### **ML Pipeline Architecture**
```
Photo Upload → Cloud Function → Vision AI → Face Extraction → 
Face Encoding → Clustering → Person Assignment → Friend Analysis
```

### **Technology Stack Additions**
- **Face Detection**: Google Vision AI / AWS Rekognition
- **Face Recognition**: TensorFlow Lite / MediaPipe
- **Vector Similarity**: Firestore with custom indexing
- **Background Processing**: Cloud Functions
- **Batch Processing**: Cloud Run for bulk operations

### **Database Schema Updates**
```typescript
// New Firestore collections
/users/{userId}/people/{personId}
/users/{userId}/photos/{photoId}/faces/{faceId}
/users/{userId}/friendships/{friendshipId}
/users/{userId}/suggestions/{suggestionId}
/users/{userId}/privacy-settings
```

### **Privacy & Security Considerations**
- Face embeddings encrypted at rest
- No raw facial images stored beyond original photos
- User consent required for facial processing
- GDPR compliance with data export/deletion tools
- Granular privacy controls for photo sharing

### **Success Metrics**
- Face detection accuracy > 95%
- Person clustering precision > 90%
- Friend suggestion acceptance rate > 30%
- Photo processing time < 10 seconds

---

## 🛠️ Current Flutter Features

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
   # Install Flutter (latest version)
   # https://docs.flutter.dev/get-started/install
   flutter upgrade  # Ensure latest version
   
   # Install Node.js and npm
   # https://nodejs.org/
   
   # Install Google Cloud CLI
   # https://cloud.google.com/sdk/docs/install
   
   # Install Terraform
   # https://learn.hashicorp.com/tutorials/terraform/install-cli
   ```

   **Flutter Version**: 3.32.5+ (Current: 3.32.5)  
   **Dart Version**: 3.8.1+

4. **Authentication**
   ```bash
   # Authenticate with Google Cloud
   gcloud auth login
   
   # Set up application default credentials
   gcloud auth application-default login
   ```

## 🚀 Quick Deployment

1. **Clone and Setup**
   ```bash
   git clone <your-repo>
   cd bacon13
   chmod +x deploy.sh
   ```

2. **Configure Firebase**
   ```bash
   # Update flutter_app/lib/firebase_options.dart with your Firebase config
   # Or use FlutterFire CLI: flutterfire configure
   ```

3. **Deploy to Firebase**
   ```bash
   # Authenticate first
   firebase login
   
   # Deploy using the script
   ./deploy.sh bacon13 us-central1 dev
   ```

   This script will:
   - Enable required Firebase APIs
   - Deploy infrastructure with Terraform
   - Deploy Firestore and Storage security rules
   - Build Flutter web app and deploy to Firebase Hosting

4. **Manual Deploy** (Alternative)
   ```bash
   cd flutter_app
   flutter build web
   cd ..
   firebase deploy --only hosting
   ```

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

### 🛠️ Local Development

### 1. Flutter Setup
```bash
cd flutter_app
flutter pub get
flutter run -d web      # For web development
flutter run             # For mobile (requires emulator/device)
```

### 2. Firebase Emulation (Optional)
```bash
# Install and start Firebase emulators
npm install -g firebase-tools
firebase emulators:start

# In another terminal, configure Flutter for emulator
# Update firebase_options.dart to use localhost URLs
cd flutter_app && flutter run -d web
```

### 3. Testing
```bash
cd flutter_app
flutter test            # Run all unit tests (27 tests)
flutter build web       # Verify production build
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
