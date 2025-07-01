#!/bin/bash

# Secure deployment script for Bacon13
# Usage: ./deploy_secure.sh [project-id] [region] [environment]

set -e

PROJECT_ID=${1:-bacon13}
REGION=${2:-us-central1}
ENVIRONMENT=${3:-prod}

echo "🔒 Secure deployment for Bacon13"
echo "📋 Project: $PROJECT_ID"
echo "🌍 Region: $REGION"
echo "🏷️  Environment: $ENVIRONMENT"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "📋 Please copy .env.template to .env and fill in your Firebase configuration:"
    echo "   cp .env.template .env"
    echo "   # Edit .env with your Firebase secrets"
    exit 1
fi

# Load environment variables
echo "🔧 Loading environment variables..."
source .env

# Validate Firebase configuration
if [ -z "$FIREBASE_API_KEY" ] || [ -z "$FIREBASE_PROJECT_ID" ]; then
    echo "❌ Error: Firebase configuration missing in .env file!"
    exit 1
fi

# Set Firebase project
echo "🔥 Setting Firebase project..."
firebase use "$PROJECT_ID"

# Build Flutter app with secrets
echo "🚀 Building Flutter app..."
cd flutter_app
./build_with_secrets.sh web
cd ..

# Deploy to Firebase Hosting
echo "🌐 Deploying to Firebase Hosting..."
firebase deploy --only hosting

# Deploy Firestore rules
echo "📊 Deploying Firestore rules..."
firebase deploy --only firestore:rules

# Deploy Storage rules  
echo "🗄️  Deploying Storage rules..."
firebase deploy --only storage

echo "✅ Deployment completed successfully!"
echo "🔗 Your app is live at: https://$PROJECT_ID.web.app"
echo "🔒 All secrets loaded securely from environment variables"