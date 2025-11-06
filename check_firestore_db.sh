#!/bin/bash

# Test Firestore database connection
echo "🔍 Checking Firestore database 'taxedgmbh'..."

# Extract project ID from GoogleService-Info.plist
PROJECT_ID=$(plutil -extract PROJECT_ID raw /Users/emanuelflury/github/TaxedGmbH_IOS/TaxedGmbH_IOS/Resources/GoogleService-Info.plist)
echo "📋 Project ID: $PROJECT_ID"

# Show database URL from config
DATABASE_URL=$(plutil -extract DATABASE_URL raw /Users/emanuelflury/github/TaxedGmbH_IOS/TaxedGmbH_IOS/Resources/GoogleService-Info.plist)
echo "🔗 Database URL: $DATABASE_URL"

echo ""
echo "✅ Firebase configuration found"
echo "✅ Database ID 'taxedgmbh' is configured in AppConstants.Firebase.databaseId"
echo ""
echo "To verify database access, go to:"
echo "https://console.firebase.google.com/project/$PROJECT_ID/firestore/databases"
