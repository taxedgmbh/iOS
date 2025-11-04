import Foundation
import FirebaseCore
import FirebaseFirestore

// Test script to check Firestore connectivity
class FirestoreConnectionTest {

    static func testConnection() {
        print("🔍 Starting Firestore Connection Test...")
        print("=====================================")

        // Check if Firebase is configured
        if FirebaseApp.app() == nil {
            print("❌ Firebase is not configured. Call FirebaseApp.configure() first.")
            return
        }

        print("✅ Firebase is configured")

        // Get Firestore instance
        let db = Firestore.firestore()
        print("✅ Firestore instance created")

        // Test 1: Check Firestore settings
        let settings = db.settings
        print("📋 Firestore Settings:")
        print("   - Host: \(settings.host)")
        print("   - SSL Enabled: \(settings.isSSLEnabled)")
        print("   - Cache Size: \(settings.cacheSettings?.sizeBytes ?? 0) bytes")

        // Test 2: Try to read a simple document
        print("\n🔄 Testing database read...")

        db.collection("test").document("ping").getDocument { (document, error) in
            if let error = error {
                let nsError = error as NSError
                print("❌ Read failed with error:")
                print("   - Domain: \(nsError.domain)")
                print("   - Code: \(nsError.code)")
                print("   - Description: \(error.localizedDescription)")

                // Check specific error codes
                if nsError.domain == "FIRFirestoreErrorDomain" {
                    switch nsError.code {
                    case 7: // Permission denied
                        print("   ⚠️ Permission denied - This is expected if security rules are strict")
                        print("   ✅ But it confirms Firestore is reachable!")
                    case 14: // Unavailable
                        print("   ❌ Network unavailable - Check internet connection")
                    case 16: // Unauthenticated
                        print("   ⚠️ Unauthenticated - This is expected for test reads")
                        print("   ✅ But it confirms Firestore is reachable!")
                    default:
                        print("   ❌ Unknown Firestore error code: \(nsError.code)")
                    }
                }
            } else {
                print("✅ Successfully connected to Firestore!")
                if let document = document, document.exists {
                    print("   - Document data: \(document.data() ?? [:])")
                } else {
                    print("   - Document doesn't exist (which is fine for testing)")
                }
            }

            print("\n=====================================")
            print("📊 Test Complete")
        }

        // Test 3: Check network connectivity
        print("\n🌐 Checking network endpoints...")

        // Test Firebase Auth endpoint
        testEndpoint(url: "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=AIzaSyAeVchuS_dJW1NuMBLAVDM-jgM3hQFw53E", name: "Firebase Auth API")

        // Test Firestore endpoint
        testEndpoint(url: "https://firestore.googleapis.com/v1/projects/taxedgmbh/databases/(default)/documents", name: "Firestore API")
    }

    static func testEndpoint(url: String, name: String) {
        guard let url = URL(string: url) else {
            print("❌ Invalid URL for \(name)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 \(name):")
                print("   - Status Code: \(httpResponse.statusCode)")

                switch httpResponse.statusCode {
                case 200:
                    print("   ✅ API is fully accessible")
                case 401, 403:
                    print("   ✅ API is reachable (auth required)")
                case 404:
                    print("   ❌ API endpoint not found")
                case 500...599:
                    print("   ❌ Server error")
                default:
                    print("   ⚠️ Unexpected status code")
                }
            } else if let error = error {
                print("❌ \(name) - Network error: \(error.localizedDescription)")
            }
            semaphore.signal()
        }.resume()

        semaphore.wait()
    }
}