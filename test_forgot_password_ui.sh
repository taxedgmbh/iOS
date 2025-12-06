#!/bin/bash

echo "========================================"
echo "TESTING FORGOT PASSWORD VIEW"
echo "========================================"
echo ""

# Ensure app is running
echo "1. Launching app..."
xcrun simctl launch C81D388C-4DAC-440C-A03D-C88BB4DD5F5C com.taxed.app
sleep 3

# Take initial screenshot
echo "2. Taking screenshot of login screen..."
xcrun simctl io C81D388C-4DAC-440C-A03D-C88BB4DD5F5C screenshot /tmp/login_screen.png

echo "3. To test the Forgot Password view:"
echo "   - In the simulator, tap on 'Forgot Password?' link"
echo "   - The new view should appear with:"
echo "     • Same liquid glass background as login"
echo "     • App logo at the top"
echo "     • Glass card container"
echo "     • Email/Phone toggle"
echo ""

# Create AppleScript to click on Forgot Password
echo "4. Using AppleScript to interact with simulator..."
osascript <<EOF
tell application "Simulator"
    activate
end tell
delay 2
tell application "System Events"
    -- Click approximately where "Forgot Password?" appears
    click at {207, 1080}
end tell
EOF

sleep 3

# Take screenshot of Forgot Password view
echo "5. Taking screenshot of Forgot Password view..."
xcrun simctl io C81D388C-4DAC-440C-A03D-C88BB4DD5F5C screenshot /tmp/forgot_password_view.png

echo ""
echo "========================================"
echo "SCREENSHOTS CAPTURED"
echo "========================================"
echo "Login screen: /tmp/login_screen.png"
echo "Forgot Password view: /tmp/forgot_password_view.png"
echo ""
echo "The Forgot Password view should now show:"
echo "✅ Same liquid glass background as login/signup"
echo "✅ App logo at top"
echo "✅ Glass card container for form"
echo "✅ Segmented control for Email/Phone reset"
echo "✅ Country selector for phone option"
echo "✅ Consistent button styling with gradient"
echo "✅ Smooth animations and transitions"
echo ""