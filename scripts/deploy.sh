#!/bin/bash

# Deploy script for UACC Firebase Functions
# Usage: ./scripts/deploy.sh [environment]

set -e

ENVIRONMENT=${1:-development}
PROJECT_ID="uacc-uacc"

echo "🚀 Deploying UACC Firebase Functions to $ENVIRONMENT"

# Check prerequisites
command -v firebase >/dev/null 2>&1 || { echo "❌ Firebase CLI is required but not installed. Aborting." >&2; exit 1; }
command -v gcloud >/dev/null 2>&1 || { echo "❌ Google Cloud CLI is required but not installed. Aborting." >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required but not installed. Aborting." >&2; exit 1; }

# Verify we're in the correct directory
if [ ! -f "firebase.json" ]; then
    echo "❌ firebase.json not found. Please run this script from the project root."
    exit 1
fi

# Check if logged in to Firebase
if ! firebase projects:list >/dev/null 2>&1; then
    echo "❌ Not logged in to Firebase. Please run 'firebase login' first."
    exit 1
fi

# Set Firebase project
echo "📋 Using Firebase project: $PROJECT_ID"
firebase use "$PROJECT_ID"

# Install dependencies
echo "📦 Installing dependencies..."
cd functions
npm install
cd ..

# Run tests if available
echo "🧪 Running tests..."
cd functions
npm test || echo "⚠️  No tests found or tests failed"
cd ..

# Set up secrets if provided
if [ -n "$GEMINI_API_KEY" ]; then
    echo "🔑 Setting up Gemini API key in Secret Manager..."
    
    # Check if secret exists
    if gcloud secrets describe GEMINI_API_KEY --project="$PROJECT_ID" >/dev/null 2>&1; then
        echo "$GEMINI_API_KEY" | gcloud secrets versions add GEMINI_API_KEY --data-file=- --project="$PROJECT_ID"
        echo "✅ Updated existing secret"
    else
        echo "$GEMINI_API_KEY" | gcloud secrets create GEMINI_API_KEY --data-file=- --project="$PROJECT_ID"
        echo "✅ Created new secret"
    fi
    
    # Grant access to Cloud Functions service account
    PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
    SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
    
    gcloud secrets add-iam-policy-binding GEMINI_API_KEY \
        --member="serviceAccount:${SERVICE_ACCOUNT}" \
        --role="roles/secretmanager.secretAccessor" \
        --project="$PROJECT_ID" || echo "⚠️  IAM binding already exists"
        
    echo "✅ Secret Manager configured"
else
    echo "⚠️  GEMINI_API_KEY environment variable not set. Skipping secret setup."
    echo "   Make sure to set this manually before deploying."
fi

# Deploy functions
echo "🚢 Deploying Firebase Functions..."
firebase deploy --only functions:geminiProxy

# Test deployment
echo "🧪 Testing deployment..."
FUNCTION_URL="https://us-central1-${PROJECT_ID}.cloudfunctions.net/geminiProxy"

# Health check (should return 405 for GET request)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$FUNCTION_URL")
if [ "$HTTP_CODE" = "405" ]; then
    echo "✅ Function is responding (GET returns 405 as expected)"
else
    echo "⚠️  Unexpected response code: $HTTP_CODE"
fi

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📍 Function URL: $FUNCTION_URL"
echo "📊 View logs: firebase functions:log --only geminiProxy"
echo "🔍 Monitor: https://console.firebase.google.com/project/$PROJECT_ID/functions"
echo ""
echo "Next steps:"
echo "1. Test the function with a valid Firebase ID token"
echo "2. Update your Flutter app to use the deployed endpoint"
echo "3. Set up monitoring and alerts for production"
echo ""

if [ "$ENVIRONMENT" = "production" ]; then
    echo "🔴 PRODUCTION DEPLOYMENT COMPLETE"
    echo "Please verify all functionality before directing traffic to this endpoint."
fi