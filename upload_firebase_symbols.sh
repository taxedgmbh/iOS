#!/bin/bash

# Firebase Crashlytics dSYM Upload Script
# This script uploads debug symbols (dSYMs) to Firebase Crashlytics
# to enable proper crash report symbolication

# Only run for Release builds to avoid unnecessary uploads during development
if [ "${CONFIGURATION}" = "Release" ]; then
    echo "🔍 Checking for Firebase Crashlytics upload script..."

    # Path to Firebase Crashlytics upload script
    FIREBASE_SCRIPT="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"

    if [ -f "$FIREBASE_SCRIPT" ]; then
        echo "✅ Found Firebase Crashlytics script"
        echo "📤 Uploading dSYMs to Firebase Crashlytics..."
        "$FIREBASE_SCRIPT"
        echo "✅ dSYM upload complete"
    else
        echo "⚠️  Firebase Crashlytics upload script not found"
        echo "ℹ️  Path checked: $FIREBASE_SCRIPT"
        echo "ℹ️  This is normal if you're not using Firebase Crashlytics"
    fi
else
    echo "ℹ️  Skipping dSYM upload (not a Release build)"
fi
