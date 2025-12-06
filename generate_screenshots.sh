#!/bin/bash

# App Store Screenshot Generator for TaxedGmbH
echo "📸 Generating App Store Screenshots..."

SCREENSHOT_DIR="$HOME/Desktop/TaxedGmbH_Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# iPhone 6.7" (iPhone 15 Pro Max) - Required
DEVICE_ID="A97E0F35-650E-4803-BDB2-1C3047AC6F4F"

echo "🚀 Starting iPhone 15 Pro Max simulator..."
xcrun simctl boot $DEVICE_ID 2>/dev/null || true
sleep 3

echo "📱 Installing app..."
xcrun simctl install $DEVICE_ID /tmp/DerivedDataNew/Build/Products/Debug-iphonesimulator/TaxedGmbH_IOS.app 2>/dev/null || echo "App already installed"

echo "▶️  Launching app..."
xcrun simctl launch $DEVICE_ID com.taxed.app
sleep 5

echo "📸 Capturing screenshots..."

# 1. Sign In Screen
xcrun simctl io $DEVICE_ID screenshot "$SCREENSHOT_DIR/01_SignIn_6.7.png"
echo "✅ Captured: Sign In Screen"

# Note: For full screenshot set, you'll need to:
# - Sign in to the app
# - Navigate through different screens
# - Capture each screen

echo ""
echo "Screenshots saved to: $SCREENSHOT_DIR"
echo ""
echo "Required Screenshots for App Store:"
echo "1. Sign In / Welcome Screen ✅"
echo "2. Dashboard / Home Screen"
echo "3. Document Scanner"
echo "4. Document List"
echo "5. Expert Chat"
echo "6. Settings (optional)"
echo ""
echo "Required Sizes:"
echo "• 6.7\" (iPhone 15 Pro Max) - 1290 x 2796 pixels"
echo "• 6.5\" (iPhone 14 Plus) - 1284 x 2778 pixels (optional)"
echo "• 5.5\" (iPhone 8 Plus) - 1242 x 2208 pixels (optional)"
echo ""
echo "💡 Tip: Open the app in Xcode Simulator and manually navigate to capture all screens"