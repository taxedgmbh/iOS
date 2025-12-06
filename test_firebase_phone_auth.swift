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
