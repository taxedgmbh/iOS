#!/bin/bash

echo "======================================"
echo "FIREBASE PHONE AUTHENTICATION SETUP"
echo "======================================"
echo ""
echo "Project ID: taxedgmbh"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

echo "Current Authentication Configuration:"
echo "-------------------------------------"

# Try to get current auth configuration
echo ""
echo "Attempting to check current authentication providers..."
firebase auth:export /tmp/users.csv --project taxedgmbh 2>/dev/null || echo "Note: Cannot export users without authentication"

echo ""
echo "======================================"
echo "MANUAL STEPS TO ENABLE PHONE AUTH"
echo "======================================"
echo ""
echo "Since we cannot access Firebase Console programmatically,"
echo "please follow these steps manually:"
echo ""
echo "1. Go to Firebase Console:"
echo "   https://console.firebase.google.com/project/taxedgmbh/authentication/providers"
echo ""
echo "2. In the Authentication section:"
echo "   - Click on 'Phone' provider"
echo "   - Toggle 'Enable' switch to ON"
echo "   - Configure the following:"
echo "     * Phone numbers for testing (optional):"
echo "       +41 79 123 4567 with code: 123456"
echo "       +41 78 987 6543 with code: 654321"
echo "     * Save the configuration"
echo ""
echo "3. Verify these providers are ENABLED:"
echo "   ✅ Email/Password"
echo "   ✅ Phone"
echo "   ✅ Apple (Sign in with Apple)"
echo ""
echo "4. Check SMS region settings:"
echo "   - Go to Project Settings > General"
echo "   - Ensure your region supports SMS"
echo "   - Default regions: US, EU should work"
echo ""
echo "5. For iOS App configuration:"
echo "   - Ensure APNs Authentication Key is uploaded"
echo "   - Go to Project Settings > Cloud Messaging"
echo "   - Upload APNs key or certificates if not done"
echo ""
echo "======================================"
echo "TESTING PHONE AUTHENTICATION"
echo "======================================"
echo ""
echo "After enabling phone auth, test with:"
echo ""
echo "1. Run the app on simulator:"
echo "   ./test_auth_flow.sh"
echo ""
echo "2. In the app:"
echo "   - Tap 'Sign Up'"
echo "   - Enter test email and password"
echo "   - Select country code (🇨🇭 +41)"
echo "   - Enter phone number"
echo "   - You should receive SMS verification"
echo ""
echo "3. For testing on simulator:"
echo "   - Use test phone numbers configured above"
echo "   - Enter the preset verification code"
echo ""
echo "======================================"
echo "TROUBLESHOOTING"
echo "======================================"
echo ""
echo "If phone auth doesn't work:"
echo ""
echo "1. Check reCAPTCHA is configured:"
echo "   - Firebase Console > Authentication > Settings > Authorized domains"
echo "   - Add your app's domain if needed"
echo ""
echo "2. For iOS Silent APNs:"
echo "   - Ensure APNs key is uploaded in Firebase Console"
echo "   - Project Settings > Cloud Messaging > iOS app configuration"
echo ""
echo "3. Check Firebase Auth SDK version:"
echo "   - Should be 10.0+ for best phone auth support"
echo ""
echo "4. Review error logs:"
echo "   firebase functions:log --project taxedgmbh"
echo ""

# Create a test script for phone authentication
cat > test_firebase_phone_auth.swift << 'EOF'
import FirebaseAuth

// Test phone authentication
func testPhoneAuth() {
    let phoneNumber = "+41791234567" // Swiss test number

    PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
        if let error = error {
            print("❌ Phone auth error: \(error.localizedDescription)")
            return
        }

        guard let verificationID = verificationID else {
            print("❌ No verification ID received")
            return
        }

        print("✅ SMS sent! Verification ID: \(verificationID)")
        print("Enter the verification code from SMS")

        // In real app, get code from user input
        let verificationCode = "123456" // Test code

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )

        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("❌ Sign in error: \(error.localizedDescription)")
                return
            }

            print("✅ Successfully signed in with phone!")
            print("User ID: \(authResult?.user.uid ?? "unknown")")
        }
    }
}
EOF

echo "Test code saved to: test_firebase_phone_auth.swift"
echo ""
echo "======================================"
echo "FIREBASE RULES FOR PHONE AUTH"
echo "======================================"
echo ""
echo "Ensure your Firestore rules support phone-authenticated users:"
echo ""
cat << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users (including phone auth)
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Phone verification documents
    match /phoneVerifications/{docId} {
      allow read, write: if request.auth != null;
    }
  }
}
EOF
echo ""
echo "======================================"
echo "NEXT STEPS"
echo "======================================"
echo ""
echo "1. Open Firebase Console and enable Phone authentication"
echo "2. Configure test phone numbers (optional but recommended)"
echo "3. Run ./test_auth_flow.sh to test the implementation"
echo "4. Monitor Firebase Auth logs for any issues"
echo ""
echo "Firebase Console Direct Link:"
echo "https://console.firebase.google.com/project/taxedgmbh/authentication/providers"
echo ""