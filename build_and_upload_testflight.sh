#!/bin/bash

# Complete TestFlight Build & Upload Script for TaxedGmbH_IOS
# This script will:
# 1. Clean the project
# 2. Build a Release archive
# 3. Export the IPA
# 4. Open in Xcode Organizer for upload to TestFlight

set -e  # Exit on error

echo "🚀 TaxedGmbH TestFlight Build & Upload"
echo "========================================"
echo ""

# Configuration
PROJECT_PATH="TaxedGmbH_IOS.xcodeproj"
SCHEME="TaxedGmbH_IOS"
CONFIGURATION="Release"
ARCHIVE_PATH="$HOME/Desktop/TaxedGmbH_IOS.xcarchive"
EXPORT_PATH="$HOME/Desktop/TaxedGmbH_IOS_Export"
EXPORT_OPTIONS="ExportOptions.plist"

# Check if we're in the right directory
if [ ! -f "$PROJECT_PATH/project.pbxproj" ]; then
    echo "❌ Error: Not in project directory!"
    echo "Please run this script from: /Users/emanuelflury/github/TaxedGmbH_IOS"
    exit 1
fi

echo "✅ Project found"

# Check if export options exist
if [ ! -f "$EXPORT_OPTIONS" ]; then
    echo "❌ Error: ExportOptions.plist not found!"
    exit 1
fi

echo "✅ ExportOptions.plist found"

# Clean previous builds
echo ""
echo "🧹 Cleaning previous builds..."
rm -rf "$ARCHIVE_PATH"
rm -rf "$EXPORT_PATH"

# Step 1: Build Release Archive
echo ""
echo "📦 Building Release archive for iOS device..."
echo "This may take a few minutes..."
echo ""

xcodebuild clean archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphoneos \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=B56TJL3Q75 \
    | grep -E "^\*\*|error:|warning:|BUILD"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Archive build failed!"
    echo "Please check the errors above."
    exit 1
fi

echo ""
echo "✅ Archive created successfully!"
echo "   Location: $ARCHIVE_PATH"

# Step 2: Export IPA
echo ""
echo "📤 Exporting IPA for App Store distribution..."
echo ""

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates \
    | grep -E "^\*\*|error:|warning:|EXPORT"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ IPA export failed!"
    echo "Please check the errors above."
    exit 1
fi

echo ""
echo "✅ IPA exported successfully!"
echo "   Location: $EXPORT_PATH/TaxedGmbH_IOS.ipa"

# Step 3: Verify IPA
if [ -f "$EXPORT_PATH/TaxedGmbH_IOS.ipa" ]; then
    IPA_SIZE=$(du -h "$EXPORT_PATH/TaxedGmbH_IOS.ipa" | cut -f1)
    echo "   Size: $IPA_SIZE"
else
    echo "❌ IPA file not found!"
    exit 1
fi

# Step 4: Open in Xcode Organizer
echo ""
echo "========================================"
echo "✅ Build complete! Ready for TestFlight upload"
echo "========================================"
echo ""
echo "Next steps:"
echo ""
echo "Option 1 (RECOMMENDED - Easiest):"
echo "   Opening Xcode Organizer now..."
echo "   1. The archive will open in Xcode Organizer"
echo "   2. Click 'Distribute App'"
echo "   3. Select 'App Store Connect'"
echo "   4. Click 'Upload'"
echo "   5. Click 'Next' through the options"
echo "   6. Click 'Upload'"
echo ""
echo "Opening Xcode Organizer in 3 seconds..."
sleep 3

open "$ARCHIVE_PATH"

echo ""
echo "Option 2 (Alternative - Transporter App):"
echo "   1. Open Transporter from Mac App Store"
echo "   2. Sign in with your Apple ID"
echo "   3. Drag this file: $EXPORT_PATH/TaxedGmbH_IOS.ipa"
echo ""
echo "Option 3 (Alternative - Command Line):"
echo "   xcrun altool --upload-app -f $EXPORT_PATH/TaxedGmbH_IOS.ipa -t ios --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID"
echo ""
echo "========================================"
echo "After upload completes:"
echo "1. Go to App Store Connect (https://appstoreconnect.apple.com)"
echo "2. Select your app"
echo "3. Go to TestFlight tab"
echo "4. Wait for processing (usually 10-30 minutes)"
echo "5. Add internal or external testers"
echo "6. Submit for Beta App Review if using external testers"
echo "========================================"
echo ""
echo "🎉 Good luck with your TestFlight release!"
