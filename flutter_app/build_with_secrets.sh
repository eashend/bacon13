#!/bin/bash

# Secure build script for Flutter app with environment variables
# Usage: ./build_with_secrets.sh [web|android|ios]

set -e

PLATFORM=${1:-web}
PROJECT_ROOT=$(dirname "$(realpath "$0")")
MAIN_ROOT=$(dirname "$PROJECT_ROOT")

echo "🔒 Building Flutter app securely for platform: $PLATFORM"

# Check if .env file exists
if [ ! -f "$MAIN_ROOT/.env" ]; then
    echo "❌ Error: .env file not found!"
    echo "📋 Please copy .env.template to .env and fill in your Firebase configuration:"
    echo "   cp $MAIN_ROOT/.env.template $MAIN_ROOT/.env"
    echo "   # Edit .env with your Firebase secrets"
    exit 1
fi

# Load environment variables
echo "🔧 Loading environment variables..."
source "$MAIN_ROOT/.env"

# Validate required variables
REQUIRED_VARS=(
    "FIREBASE_API_KEY"
    "FIREBASE_APP_ID" 
    "FIREBASE_MESSAGING_SENDER_ID"
    "FIREBASE_PROJECT_ID"
    "FIREBASE_AUTH_DOMAIN"
    "FIREBASE_STORAGE_BUCKET"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: Required environment variable $var is not set!"
        echo "📋 Please check your .env file"
        exit 1
    fi
done

# Build with environment variables
echo "🚀 Building Flutter app..."
cd "$PROJECT_ROOT"

case $PLATFORM in
    web)
        echo "🌐 Building for web..."
        flutter build web \
            --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
            --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
            --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
            --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
            --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET"
        ;;
    android)
        echo "🤖 Building for Android..."
        flutter build apk \
            --dart-define=FIREBASE_API_KEY_ANDROID="$FIREBASE_API_KEY_ANDROID" \
            --dart-define=FIREBASE_APP_ID_ANDROID="$FIREBASE_APP_ID_ANDROID" \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
            --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
            --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
            --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET"
        ;;
    ios)
        echo "🍎 Building for iOS..."
        flutter build ios \
            --dart-define=FIREBASE_API_KEY_IOS="$FIREBASE_API_KEY_IOS" \
            --dart-define=FIREBASE_APP_ID_IOS="$FIREBASE_APP_ID_IOS" \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
            --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
            --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
            --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
            --dart-define=FIREBASE_IOS_BUNDLE_ID="$FIREBASE_IOS_BUNDLE_ID"
        ;;
    *)
        echo "❌ Error: Unsupported platform: $PLATFORM"
        echo "📋 Supported platforms: web, android, ios"
        exit 1
        ;;
esac

echo "✅ Build completed successfully!"
echo "🔒 Firebase secrets loaded from environment variables"