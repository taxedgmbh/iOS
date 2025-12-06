#!/bin/bash

echo "======================================"
echo "Testing Authentication Flow"
echo "======================================"
echo ""

# Kill any running simulators
echo "1. Stopping any running simulators..."
killall Simulator 2>/dev/null || true
sleep 2

# Start simulator
echo "2. Starting iPhone 17 simulator..."
xcrun simctl boot C81D388C-4DAC-440C-A03D-C88BB4DD5F5C 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID C81D388C-4DAC-440C-A03D-C88BB4DD5F5C
sleep 5

# Uninstall existing app
echo "3. Uninstalling existing app..."
xcrun simctl uninstall C81D388C-4DAC-440C-A03D-C88BB4DD5F5C com.taxed.app 2>/dev/null || true

# Install app
echo "4. Installing app..."
xcrun simctl install C81D388C-4DAC-440C-A03D-C88BB4DD5F5C \
    /Users/emanuelflury/Library/Developer/Xcode/DerivedData/TaxedGmbH_IOS-gerngfqzuwudosgobknlgtoawnlj/Build/Products/Debug-iphonesimulator/TaxedGmbH_IOS.app

# Launch app
echo "5. Launching app..."
xcrun simctl launch --console-pty C81D388C-4DAC-440C-A03D-C88BB4DD5F5C com.taxed.app

echo ""
echo "======================================"
echo "App is now running on the simulator"
echo "======================================"
echo ""
echo "Test the following:"
echo "1. Sign Up:"
echo "   - Notice the phone field now has country code selector (🇨🇭 +41)"
echo "   - Enter a test email (e.g., test@example.com)"
echo "   - Enter a password (min 6 characters)"
echo "   - Enter your name"
echo "   - Select different countries to see the dial code change"
echo "   - Enter a phone number (optional - with proper formatting)"
echo "   - If phone provided, verification will be triggered"
echo ""
echo "2. Sign In:"
echo "   - Email/password login should work without keychain errors"
echo "   - Apple Sign In should work"
echo ""
echo "3. Check for errors:"
echo "   - No more keychain access error (-34018)"
echo "   - Phone numbers properly formatted with country codes"
echo "   - 2FA phone verification working"
echo ""