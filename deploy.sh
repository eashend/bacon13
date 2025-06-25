#!/bin/bash

# Firebase Deployment Script for Bacon13 App
# Make sure you have Firebase CLI and gcloud CLI installed and authenticated

set -e

# Configuration
PROJECT_ID=${1:-"bacon13"}
REGION=${2:-"us-central1"}
ENVIRONMENT=${3:-"dev"}

echo "Deploying Bacon13 App (Flutter + Firebase Architecture)..."
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Environment: $ENVIRONMENT"

# Set the project
gcloud config set project $PROJECT_ID
firebase use $PROJECT_ID

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable \
    firestore.googleapis.com \
    firebase.googleapis.com \
    identitytoolkit.googleapis.com \
    storage.googleapis.com

# Deploy infrastructure with Terraform (Firebase resources)
echo "Deploying Firebase infrastructure with Terraform..."
cd infrastructure

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    terraform init
fi

# Create terraform.tfvars file
cat > terraform.tfvars << EOF
project_id = "$PROJECT_ID"
region = "$REGION"
environment = "$ENVIRONMENT"
EOF

# Plan and apply
terraform plan
echo "Do you want to apply the Terraform configuration? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    terraform apply -auto-approve
else
    echo "Deployment cancelled."
    exit 1
fi

cd ..

# Deploy Firebase Security Rules
echo "Deploying Firestore security rules..."
firebase deploy --only firestore:rules

echo "Deploying Firebase Storage security rules..."
firebase deploy --only storage

# Build and deploy Flutter web app
echo "Building and deploying Flutter web app..."
cd flutter_app

# Install dependencies
flutter pub get

# Build the Flutter web app
flutter build web

# Deploy to Firebase Hosting
cd ..
firebase deploy --only hosting

echo ""
echo "Deployment completed!"
echo ""
echo "Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
echo "Firestore Database: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "Firebase Storage: https://console.firebase.google.com/project/$PROJECT_ID/storage"
echo "Firebase Authentication: https://console.firebase.google.com/project/$PROJECT_ID/authentication"
echo ""
echo "Your app should be available at: https://$PROJECT_ID.web.app"
