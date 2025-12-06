#!/bin/bash

# TestFlight Upload Script for TaxedGmbH_IOS

echo "🚀 TaxedGmbH TestFlight Upload Script"
echo "======================================"
echo ""

ARCHIVE_PATH="$HOME/Desktop/TaxedGmbH_IOS.xcarchive"
EXPORT_PATH="$HOME/Desktop/TaxedGmbH_IOS_Export"
EXPORT_OPTIONS="ExportOptions.plist"

# Check if archive exists
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive not found at: $ARCHIVE_PATH"
    echo "Please build the archive first with:"
    echo "xcodebuild -project TaxedGmbH_IOS.xcodeproj -scheme TaxedGmbH_IOS -configuration Release -sdk iphoneos -archivePath ~/Desktop/TaxedGmbH_IOS.xcarchive clean archive"
    exit 1
fi

echo "✅ Found archive at: $ARCHIVE_PATH"

# Export IPA from archive
echo ""
echo "📦 Exporting IPA for App Store..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates

if [ $? -ne 0 ]; then
    echo "❌ Export failed!"
    exit 1
fi

echo ""
echo "✅ IPA exported successfully to: $EXPORT_PATH"

# Upload to App Store Connect
echo ""
echo "📤 Uploading to TestFlight..."
echo "This will validate and upload your app to App Store Connect."
echo ""

xcrun altool --upload-app \
    -f "$EXPORT_PATH/TaxedGmbH_IOS.ipa" \
    -t ios \
    --apiKey "YOUR_API_KEY" \
    --apiIssuer "YOUR_ISSUER_ID" \
    --verbose

# Alternative: Use Transporter or Xcode Organizer
echo ""
echo "======================================"
echo "Alternative upload methods:"
echo ""
echo "1. Open Xcode Organizer:"
echo "   xcodebuild -exportArchive -archivePath $ARCHIVE_PATH -exportPath $EXPORT_PATH -exportOptionsPlist $EXPORT_OPTIONS"
echo "   Then: Xcode > Window > Organizer > Upload to App Store"
echo ""
echo "2. Use Transporter app:"
echo "   - Download from Mac App Store"
echo "   - Sign in with Apple ID"
echo "   - Drag the IPA file: $EXPORT_PATH/TaxedGmbH_IOS.ipa"
echo ""
echo "3. Use Xcode directly:"
echo "   open $ARCHIVE_PATH"
echo "   This will open in Xcode Organizer for direct upload"
echo ""
echo "======================================"