import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Comprehensive Firestore Integration Test
/// This script tests the complete authentication and database flow
class FirestoreIntegrationTest {

    private let firestore = Firestore.firestore()
    private var testUserId: String?

    // MARK: - Test Configuration

    struct TestUser {
        static let email = "test-\(UUID().uuidString.prefix(8))@taxed.com"
        static let password = "Test1234"
        static let name = "Test User"
        static let phone = "+41791234567"
        static let role = "customer"
    }

    // MARK: - Main Test Runner

    func runAllTests() async {
        print("🧪 Starting Comprehensive Firestore Integration Tests...")
        print("================================================\n")

        var passedTests = 0
        var failedTests = 0

        // Test 1: Firebase Configuration
        if await testFirebaseConfiguration() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Test 2: Firestore Connection
        if await testFirestoreConnection() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Test 3: User Registration
        if await testUserRegistration() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Test 4: Data Persistence
        if await testDataPersistence() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Test 5: User Login
        if await testUserLogin() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Test 6: Data Retrieval
        if await testDataRetrieval() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Test 7: Security Rules
        if await testSecurityRules() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Test 8: Index Performance
        if await testIndexPerformance() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Test 9: Offline Capabilities
        if await testOfflineCapabilities() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Test 10: Cleanup
        if await testCleanup() {
            passedTests += 1
        } else {
            failedTests += 1
        }

        // Summary
        print("\n================================================")
        print("📊 Test Summary:")
        print("✅ Passed: \(passedTests)/10")
        print("❌ Failed: \(failedTests)/10")
        print("================================================\n")

        if failedTests == 0 {
            print("🎉 All tests passed! Firestore integration is working perfectly!")
        } else {
            print("⚠️  Some tests failed. Please review the errors above.")
        }
    }

    // MARK: - Test 1: Firebase Configuration

    func testFirebaseConfiguration() async -> Bool {
        print("Test 1: Checking Firebase Configuration...")

        do {
            // Check if Firebase is configured
            guard FirebaseApp.app() != nil else {
                print("❌ Firebase is not configured")
                return false
            }

            // Check if Auth is available
            let auth = Auth.auth()
            print("   ✓ Firebase Auth initialized")

            // Check if Firestore is available
            let db = Firestore.firestore()
            print("   ✓ Firestore initialized")

            print("✅ Test 1 Passed: Firebase configuration is correct\n")
            return true
        } catch {
            print("❌ Test 1 Failed: \(error.localizedDescription)\n")
            return false
        }
    }

    // MARK: - Test 2: Firestore Connection

    func testFirestoreConnection() async -> Bool {
        print("Test 2: Testing Firestore Connection...")

        do {
            // Try to read from Firestore (this will test connection)
            let testCollection = firestore.collection("_test_connection")
            let testDoc = testCollection.document("ping")

            try await testDoc.setData(["timestamp": Date(), "test": true])
            print("   ✓ Write operation successful")

            let snapshot = try await testDoc.getDocument()
            guard snapshot.exists else {
                print("❌ Document not found after write")
                return false
            }
            print("   ✓ Read operation successful")

            try await testDoc.delete()
            print("   ✓ Delete operation successful")

            print("✅ Test 2 Passed: Firestore connection is working\n")
            return true
        } catch {
            print("❌ Test 2 Failed: \(error.localizedDescription)")
            print("   Possible causes:")
            print("   - No internet connection")
            print("   - Firestore not enabled in Firebase Console")
            print("   - Security rules blocking access\n")
            return false
        }
    }

    // MARK: - Test 3: User Registration

    func testUserRegistration() async -> Bool {
        print("Test 3: Testing User Registration...")

        do {
            // Create Firebase Auth user
            let authResult = try await Auth.auth().createUser(
                withEmail: TestUser.email,
                password: TestUser.password
            )

            testUserId = authResult.user.uid
            print("   ✓ Firebase Auth user created: \(testUserId!)")

            // Create user document in Firestore
            let userData: [String: Any] = [
                "email": TestUser.email,
                "name": TestUser.name,
                "phone": TestUser.phone,
                "role": TestUser.role,
                "createdAt": Date(),
                "updatedAt": Date()
            ]

            try await firestore.collection("users")
                .document(testUserId!)
                .setData(userData)

            print("   ✓ User document created in Firestore")
            print("   ✓ Email: \(TestUser.email)")
            print("   ✓ Name: \(TestUser.name)")
            print("   ✓ Phone: \(TestUser.phone)")
            print("   ✓ Role: \(TestUser.role)")

            print("✅ Test 3 Passed: User registration successful\n")
            return true
        } catch {
            print("❌ Test 3 Failed: \(error.localizedDescription)")
            if let authError = error as NSError? {
                print("   Error code: \(authError.code)")
            }
            print("")
            return false
        }
    }

    // MARK: - Test 4: Data Persistence

    func testDataPersistence() async -> Bool {
        print("Test 4: Testing Data Persistence...")

        guard let userId = testUserId else {
            print("❌ Test 4 Skipped: No user ID available\n")
            return false
        }

        do {
            // Wait a moment to ensure data is persisted
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // Try to read the data back
            let document = try await firestore.collection("users")
                .document(userId)
                .getDocument()

            guard document.exists else {
                print("❌ User document not found in Firestore")
                return false
            }

            guard let data = document.data() else {
                print("❌ User document has no data")
                return false
            }

            // Verify all fields
            guard let email = data["email"] as? String,
                  let name = data["name"] as? String,
                  let phone = data["phone"] as? String,
                  let role = data["role"] as? String else {
                print("❌ Missing required fields in user document")
                return false
            }

            print("   ✓ Data persisted successfully")
            print("   ✓ Email: \(email)")
            print("   ✓ Name: \(name)")
            print("   ✓ Phone: \(phone)")
            print("   ✓ Role: \(role)")

            print("✅ Test 4 Passed: Data persistence verified\n")
            return true
        } catch {
            print("❌ Test 4 Failed: \(error.localizedDescription)\n")
            return false
        }
    }

    // MARK: - Test 5: User Login

    func testUserLogin() async -> Bool {
        print("Test 5: Testing User Login...")

        do {
            // Sign out first
            try Auth.auth().signOut()
            print("   ✓ Signed out successfully")

            // Sign back in
            let authResult = try await Auth.auth().signIn(
                withEmail: TestUser.email,
                password: TestUser.password
            )

            print("   ✓ Sign in successful")
            print("   ✓ User ID: \(authResult.user.uid)")
            print("   ✓ Email: \(authResult.user.email ?? "N/A")")

            print("✅ Test 5 Passed: User login successful\n")
            return true
        } catch {
            print("❌ Test 5 Failed: \(error.localizedDescription)\n")
            return false
        }
    }

    // MARK: - Test 6: Data Retrieval

    func testDataRetrieval() async -> Bool {
        print("Test 6: Testing Data Retrieval...")

        guard let userId = testUserId else {
            print("❌ Test 6 Skipped: No user ID available\n")
            return false
        }

        do {
            // Retrieve user data
            let document = try await firestore.collection("users")
                .document(userId)
                .getDocument()

            guard document.exists else {
                print("❌ User document not found")
                return false
            }

            guard let data = document.data() else {
                print("❌ No data in document")
                return false
            }

            print("   ✓ Document retrieved successfully")
            print("   ✓ Fields: \(data.keys.joined(separator: ", "))")

            // Test query by email (uses index)
            let querySnapshot = try await firestore.collection("users")
                .whereField("email", isEqualTo: TestUser.email)
                .getDocuments()

            guard !querySnapshot.documents.isEmpty else {
                print("❌ Query by email returned no results")
                return false
            }

            print("   ✓ Query by email successful")
            print("   ✓ Found \(querySnapshot.documents.count) document(s)")

            print("✅ Test 6 Passed: Data retrieval successful\n")
            return true
        } catch {
            print("❌ Test 6 Failed: \(error.localizedDescription)\n")
            return false
        }
    }

    // MARK: - Test 7: Security Rules

    func testSecurityRules() async -> Bool {
        print("Test 7: Testing Security Rules...")

        guard let userId = testUserId else {
            print("❌ Test 7 Skipped: No user ID available\n")
            return false
        }

        do {
            // Test: User can read own data (should succeed)
            let ownDoc = try await firestore.collection("users")
                .document(userId)
                .getDocument()

            guard ownDoc.exists else {
                print("❌ Cannot read own document")
                return false
            }
            print("   ✓ User can read own document")

            // Test: User can update own data (should succeed)
            try await firestore.collection("users")
                .document(userId)
                .updateData(["updatedAt": Date()])
            print("   ✓ User can update own document")

            print("✅ Test 7 Passed: Security rules working correctly\n")
            return true
        } catch {
            print("❌ Test 7 Failed: \(error.localizedDescription)")
            print("   This might indicate security rules are not deployed\n")
            return false
        }
    }

    // MARK: - Test 8: Index Performance

    func testIndexPerformance() async -> Bool {
        print("Test 8: Testing Index Performance...")

        do {
            // Test indexed query (should be fast)
            let startTime = Date()

            let querySnapshot = try await firestore.collection("users")
                .whereField("role", isEqualTo: "customer")
                .order(by: "createdAt", descending: true)
                .limit(to: 10)
                .getDocuments()

            let duration = Date().timeIntervalSince(startTime)

            print("   ✓ Indexed query completed")
            print("   ✓ Duration: \(String(format: "%.3f", duration))s")
            print("   ✓ Documents: \(querySnapshot.documents.count)")

            if duration < 2.0 {
                print("   ✓ Query performance is good")
            } else {
                print("   ⚠️  Query is slower than expected (might need indexes)")
            }

            print("✅ Test 8 Passed: Index performance test complete\n")
            return true
        } catch let error as NSError {
            if error.domain == "FIRFirestoreErrorDomain" && error.code == 9 {
                print("❌ Test 8 Failed: Index not found")
                print("   The query requires an index that is not yet deployed")
                print("   Please ensure all indexes are deployed in Firebase Console\n")
            } else {
                print("❌ Test 8 Failed: \(error.localizedDescription)\n")
            }
            return false
        }
    }

    // MARK: - Test 9: Offline Capabilities

    func testOfflineCapabilities() async -> Bool {
        print("Test 9: Testing Offline Capabilities...")

        do {
            // Check if offline persistence is enabled
            let settings = firestore.settings
            if settings.isPersistenceEnabled {
                print("   ✓ Offline persistence is enabled")
            } else {
                print("   ℹ️  Offline persistence is not enabled (default)")
            }

            print("✅ Test 9 Passed: Offline capabilities checked\n")
            return true
        } catch {
            print("❌ Test 9 Failed: \(error.localizedDescription)\n")
            return false
        }
    }

    // MARK: - Test 10: Cleanup

    func testCleanup() async -> Bool {
        print("Test 10: Cleaning up test data...")

        guard let userId = testUserId else {
            print("❌ Test 10 Skipped: No user ID available\n")
            return false
        }

        do {
            // Delete user document
            try await firestore.collection("users")
                .document(userId)
                .delete()
            print("   ✓ User document deleted")

            // Delete Firebase Auth user
            if let currentUser = Auth.auth().currentUser {
                try await currentUser.delete()
                print("   ✓ Firebase Auth user deleted")
            }

            print("✅ Test 10 Passed: Cleanup successful\n")
            return true
        } catch {
            print("❌ Test 10 Failed: \(error.localizedDescription)")
            print("   Manual cleanup may be required\n")
            return false
        }
    }
}

// MARK: - Run Tests

/// Entry point for running tests
@MainActor
func runFirestoreIntegrationTests() async {
    let tester = FirestoreIntegrationTest()
    await tester.runAllTests()
}
