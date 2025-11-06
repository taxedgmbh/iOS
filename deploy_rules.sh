#!/bin/bash
# Firebase Security Rules Deployment Script
# Purpose: Deploy Firestore and Storage rules to the 'taxedgmbh' named database

set -e  # Exit on error

echo "🚀 Deploying Firebase Security Rules to 'taxedgmbh' project..."
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed."
    echo "   Install with: npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase CLI."
    echo "   Login with: firebase login"
    exit 1
fi

# Verify project files exist
if [ ! -f "firebase.json" ]; then
    echo "❌ firebase.json not found in current directory"
    exit 1
fi

if [ ! -f "firestore.rules" ]; then
    echo "❌ firestore.rules not found in current directory"
    exit 1
fi

if [ ! -f "storage.rules" ]; then
    echo "❌ storage.rules not found in current directory"
    exit 1
fi

echo "✅ All configuration files found"
echo ""

# Deploy Firestore rules
echo "📦 Deploying Firestore rules to 'taxedgmbh' database..."
if firebase deploy --only firestore; then
    echo "✅ Firestore rules deployed successfully"
else
    echo "❌ Firestore rules deployment failed"
    exit 1
fi

echo ""

# Deploy Storage rules
echo "📦 Deploying Storage rules..."
if firebase deploy --only storage; then
    echo "✅ Storage rules deployed successfully"
else
    echo "❌ Storage rules deployment failed"
    exit 1
fi

echo ""
echo "✅ All Firebase Security Rules deployed successfully!"
echo ""
echo "🔗 Verify deployment:"
echo "   Firestore: https://console.firebase.google.com/project/taxedgmbh/firestore/rules"
echo "   Storage:   https://console.firebase.google.com/project/taxedgmbh/storage/rules"
echo ""
