#!/bin/bash

echo "========================================"
echo "COMPLETE AUTHENTICATION TEST SUITE"
echo "========================================"
echo ""
echo "Firebase Project: taxedgmbh"
echo "App Bundle ID: com.taxed.app"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Current Firebase Users:${NC}"
echo "1. info@taxed.ch (verified)"
echo "2. hello@taxed.ch (unverified)"
echo "3. eaflury@gmail.com (verified, has workspace)"
echo ""

echo "========================================"
echo "STEP 1: CHECK FIREBASE AUTH STATUS"
echo "========================================"
echo ""

# Check Firebase auth export capability
echo "Checking Firebase authentication access..."
if firebase auth:export /tmp/test_users.csv --project taxedgmbh 2>/dev/null; then
    USER_COUNT=$(wc -l < /tmp/test_users.csv)
    echo -e "${GREEN}✅ Firebase Auth is accessible${NC}"
    echo "   Total users: $((USER_COUNT - 1))"
else
    echo -e "${RED}❌ Cannot access Firebase Auth${NC}"
    echo "   Please check Firebase CLI authentication"
fi
echo ""

echo "========================================"
echo "STEP 2: TEST APP AUTHENTICATION"
echo "========================================"
echo ""

# Kill any running simulators
echo "Restarting simulator..."
killall Simulator 2>/dev/null || true
sleep 2

# Start fresh simulator
echo "Starting iPhone 17 simulator..."
xcrun simctl boot C81D388C-4DAC-440C-A03D-C88BB4DD5F5C 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID C81D388C-4DAC-440C-A03D-C88BB4DD5F5C
sleep 5

# Uninstall and reinstall app
echo "Installing fresh app..."
xcrun simctl uninstall C81D388C-4DAC-440C-A03D-C88BB4DD5F5C com.taxed.app 2>/dev/null || true
xcrun simctl install C81D388C-4DAC-440C-A03D-C88BB4DD5F5C \
    /Users/emanuelflury/Library/Developer/Xcode/DerivedData/TaxedGmbH_IOS-gerngfqzuwudosgobknlgtoawnlj/Build/Products/Debug-iphonesimulator/TaxedGmbH_IOS.app

# Launch app
echo "Launching app..."
xcrun simctl launch C81D388C-4DAC-440C-A03D-C88BB4DD5F5C com.taxed.app

# Take screenshot
sleep 3
xcrun simctl io C81D388C-4DAC-440C-A03D-C88BB4DD5F5C screenshot /tmp/auth_test_screenshot.png
echo -e "${GREEN}✅ App launched and screenshot taken${NC}"
echo ""

echo "========================================"
echo "TEST SCENARIOS"
echo "========================================"
echo ""

echo -e "${YELLOW}Test 1: Email/Password Sign In${NC}"
echo "1. In the app, tap 'Sign In'"
echo "2. Enter: info@taxed.ch"
echo "3. Enter any password (test with wrong password first)"
echo "4. Should show error for wrong password"
echo "5. Try with correct password if known"
echo ""

echo -e "${YELLOW}Test 2: New User Sign Up${NC}"
echo "1. Tap 'Sign Up' link"
echo "2. Enter new email: test_$(date +%s)@example.com"
echo "3. Password: TestPass123!"
echo "4. Name: Test User"
echo "5. Phone: Select 🇨🇭 +41, enter 79 123 4567"
echo "6. Tap 'Sign Up'"
echo "Expected: User created, phone verification triggered"
echo ""

echo -e "${YELLOW}Test 3: Apple Sign In${NC}"
echo "1. From sign in screen, tap 'Sign in with Apple'"
echo "2. Follow Apple ID authentication flow"
echo "Expected: Should authenticate with Apple ID"
echo ""

echo -e "${YELLOW}Test 4: Phone Verification (if enabled)${NC}"
echo "1. During sign up, enter phone number"
echo "2. Should receive SMS (or use test code: 123456)"
echo "3. Enter verification code"
echo "Expected: Phone verified and linked to account"
echo ""

echo "========================================"
echo "FIREBASE CONSOLE CHECKS"
echo "========================================"
echo ""
echo "Please verify in Firebase Console:"
echo -e "${YELLOW}https://console.firebase.google.com/project/taxedgmbh/authentication/providers${NC}"
echo ""
echo "1. Authentication Providers Status:"
echo "   [ ] Email/Password - ENABLED"
echo "   [ ] Phone - ENABLED"
echo "   [ ] Apple - ENABLED"
echo ""
echo "2. Test Phone Numbers (if using simulator):"
echo "   +41 79 123 4567 → Code: 123456"
echo "   +41 78 987 6543 → Code: 654321"
echo ""
echo "3. APNs Configuration (for phone auth):"
echo "   Project Settings > Cloud Messaging"
echo "   [ ] APNs Authentication Key uploaded"
echo "   [ ] iOS app configured"
echo ""

echo "========================================"
echo "MONITORING & DEBUGGING"
echo "========================================"
echo ""

echo "Monitor authentication logs:"
echo "firebase functions:log --project taxedgmbh"
echo ""

echo "Check Xcode console for errors:"
echo "1. Open Xcode"
echo "2. Window > Devices and Simulators"
echo "3. Select your simulator"
echo "4. Open Console to see live logs"
echo ""

echo "Common Issues and Solutions:"
echo ""
echo -e "${RED}Issue: Keychain error -34018${NC}"
echo -e "${GREEN}Solution:${NC} Already fixed with simulator workaround in TaxedGmbH_IOSApp.swift"
echo ""
echo -e "${RED}Issue: Phone auth not sending SMS${NC}"
echo -e "${GREEN}Solution:${NC} "
echo "1. Enable Phone provider in Firebase Console"
echo "2. Upload APNs key for iOS"
echo "3. Use test phone numbers for simulator"
echo ""
echo -e "${RED}Issue: Sign in with Apple not working${NC}"
echo -e "${GREEN}Solution:${NC}"
echo "1. Verify Apple provider is enabled in Firebase"
echo "2. Check entitlements file has com.apple.developer.applesignin"
echo "3. Ensure provisioning profile supports Sign in with Apple"
echo ""

echo "========================================"
echo "VERIFICATION CHECKLIST"
echo "========================================"
echo ""
echo "Mark each item when verified:"
echo ""
echo "[ ] Email/Password sign in works"
echo "[ ] New user sign up works"
echo "[ ] Phone number field shows country selector"
echo "[ ] Phone verification SMS received (or test code works)"
echo "[ ] Apple Sign In works"
echo "[ ] No keychain errors in console"
echo "[ ] User appears in Firebase Console after sign up"
echo "[ ] User can sign out and sign back in"
echo ""

echo -e "${GREEN}========================================"
echo "AUTHENTICATION TESTING READY!"
echo "========================================${NC}"
echo ""
echo "App is running on simulator."
echo "Follow the test scenarios above to verify all auth methods."
echo ""
echo "For manual Firebase configuration:"
echo -e "${YELLOW}https://console.firebase.google.com/project/taxedgmbh/authentication/providers${NC}"
echo ""