import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import GoogleSignIn

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case invalidNonce
    case invalidToken
    case invalidTokenString
    case invalidEmail
    case weakPassword
    case userNotFound
    case wrongPassword
    case emailAlreadyInUse
    case networkError
    case userCanceled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Ungültige Anmeldeinformationen"
        case .invalidNonce:
            return "Sicherheitsfehler bei der Anmeldung"
        case .invalidToken:
            return "Ungültiges Authentifizierungstoken"
        case .invalidTokenString:
            return "Fehler beim Verarbeiten des Tokens"
        case .invalidEmail:
            return "Ungültige E-Mail-Adresse"
        case .weakPassword:
            return "Passwort muss mindestens \(AppConstants.Validation.minimumPasswordLength) Zeichen lang sein und Buchstaben sowie Zahlen enthalten"
        case .userNotFound:
            return "Kein Konto mit dieser E-Mail-Adresse gefunden"
        case .wrongPassword:
            return "Falsches Passwort. Bitte versuchen Sie es erneut."
        case .emailAlreadyInUse:
            return "Diese E-Mail-Adresse wird bereits verwendet"
        case .networkError:
            return "Netzwerkfehler. Bitte überprüfen Sie Ihre Internetverbindung."
        case .userCanceled:
            return "" // No error message for user cancellation
        case .unknown(let message):
            return message
        }
    }
}

@MainActor
class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Phase 4: Event-driven architecture for profile changes
    let profileDidChange = PassthroughSubject<User, Never>()

    private let firestore: Firestore
    private var currentNonce: String?

    // Database configuration: Using Firebase Firestore
    // Enterprise-grade database with real-time sync, offline support, and scalability
    // Production-ready with automatic backups and security rules

    init() {
        // Initialize Firestore with named database support
        if let databaseId = AppConstants.Firebase.databaseId {
            print("🔧 AuthenticationService using named database: \(databaseId)")
            self.firestore = Firestore.firestore(database: databaseId)
        } else {
            print("🔧 AuthenticationService using default database")
            self.firestore = Firestore.firestore()
        }

        // Check if user is already signed in
        if let currentUser = Auth.auth().currentUser {
            Task {
                await loadUserData(userId: currentUser.uid)
            }
        }
    }

    // MARK: - Apple Sign-In

    /// Generate a random nonce for Apple Sign-In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    /// SHA256 hash of the nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }

    /// Start Apple Sign-In flow
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Handle Apple Sign-In completion
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            switch result {
            case .success(let authorization):
                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    throw AuthError.invalidCredential
                }

                guard let nonce = currentNonce else {
                    throw AuthError.invalidNonce
                }

                guard let appleIDToken = appleIDCredential.identityToken else {
                    throw AuthError.invalidToken
                }

                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    throw AuthError.invalidTokenString
                }

                // Create OAuth credential
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )

                // Sign in with Firebase
                let authResult = try await Auth.auth().signIn(with: credential)

                // Check if user document exists, if not create one
                let userId = authResult.user.uid
                let userDoc = try await firestore.collection(AppConstants.Firebase.Collections.users).document(userId).getDocument()

                if !userDoc.exists {
                    // Create new user document
                    let fullName = appleIDCredential.fullName
                    let name = [fullName?.givenName, fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")

                    let newUser = User(
                        id: userId,
                        email: appleIDCredential.email ?? authResult.user.email ?? "no-email@apple.com",
                        name: name.isEmpty ? "Apple User" : name,
                        role: .customer
                    )

                    try await firestore.collection(AppConstants.Firebase.Collections.users).document(userId).setData(newUser.toDictionary())

                    // Create default workspace for new user (permanent, multi-year)
                    let currentYear = Calendar.current.component(.year, from: Date())
                    do {
                        let defaultWorkspace = try await WorkspaceManager.shared.createWorkspace(
                            name: "Personal Taxes",
                            type: .personal,
                            taxYear: currentYear,
                            owner: newUser,
                            description: "Your personal tax documents and filings"
                        )
                        print("✅ Created default workspace: \(defaultWorkspace.name)")
                    } catch {
                        print("⚠️ Warning: Failed to create default workspace: \(error)")
                        print("⚠️ User can create workspace manually later")
                        // Don't fail the entire signup if workspace creation fails
                    }

                    self.user = newUser
                    self.isAuthenticated = true
                } else {
                    // Load existing user data
                    await loadUserData(userId: userId)
                }

                print("✅ Apple Sign-In successful")

            case .failure(let error):
                // Check if user canceled
                let nsError = error as NSError
                if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" && nsError.code == 1000 {
                    // User canceled - this is not an error
                    print("ℹ️ Apple Sign-In canceled by user")
                    return
                }
                throw error
            }
        } catch {
            // Check if user canceled (double check in catch block)
            let nsError = error as NSError
            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" && nsError.code == 1000 {
                // User canceled - don't show error message
                print("ℹ️ Apple Sign-In canceled by user")
                return
            }

            errorMessage = handleAuthError(error)
            print("❌ Apple Sign-In error: \(error)")
        }
    }

    // MARK: - Google Sign-In

    /// Start Google Sign-In flow
    func handleSignInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            // Get the client ID from GoogleService-Info.plist
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.unknown("Google Client ID not found")
            }

            // Configure Google Sign-In
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // Get the presenting view controller
            guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = await windowScene.windows.first?.rootViewController else {
                throw AuthError.unknown("Could not find root view controller")
            }

            // Sign in with Google
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user

            guard let idToken = user.idToken?.tokenString else {
                throw AuthError.invalidToken
            }

            let accessToken = user.accessToken.tokenString

            // Create Firebase credential with Google tokens
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            // Sign in to Firebase with Google credential
            let authResult = try await Auth.auth().signIn(with: credential)

            // Check if user document exists, if not create one
            let userId = authResult.user.uid
            let userDoc = try await firestore.collection(AppConstants.Firebase.Collections.users).document(userId).getDocument()

            if !userDoc.exists {
                // Create new user document
                let profile = user.profile
                let fullName = profile?.name ?? ""
                let email = profile?.email ?? authResult.user.email ?? "no-email@google.com"

                let newUser = User(
                    id: userId,
                    email: email,
                    name: fullName.isEmpty ? "Google User" : fullName,
                    role: .customer
                )

                try await firestore.collection(AppConstants.Firebase.Collections.users).document(userId).setData(newUser.toDictionary())

                // Create default workspace for new user
                let currentYear = Calendar.current.component(.year, from: Date())
                do {
                    let defaultWorkspace = try await WorkspaceManager.shared.createWorkspace(
                        name: "Personal Taxes",
                        type: .personal,
                        taxYear: currentYear,
                        owner: newUser,
                        description: "Your personal tax documents and filings"
                    )
                    print("✅ Created default workspace: \(defaultWorkspace.name)")
                } catch {
                    print("⚠️ Warning: Failed to create default workspace: \(error)")
                    print("⚠️ User can create workspace manually later")
                }

                self.user = newUser
                self.isAuthenticated = true
            } else {
                // Load existing user data
                await loadUserData(userId: userId)
            }

            print("✅ Google Sign-In successful")

        } catch {
            // Check if user canceled
            let nsError = error as NSError
            if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                // User canceled - don't show error message
                print("ℹ️ Google Sign-In canceled by user")
                return
            }

            errorMessage = handleAuthError(error)
            print("❌ Google Sign-In error: \(error)")
        }
    }

    // MARK: - Email/Password Authentication

    func signUp(email: String, password: String, name: String, phone: String? = nil, role: UserRole = .customer) async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            // Validate input
            guard email.isValidEmail else {
                throw AuthError.invalidEmail
            }

            guard password.isValidPassword else {
                throw AuthError.weakPassword
            }

            guard !name.trimmed.isEmpty else {
                throw AuthError.unknown("Name darf nicht leer sein")
            }

            // 1. Create Firebase Auth user
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)

            // 2. Create user document in database
            let newUser = User(
                id: authResult.user.uid,
                email: email,
                name: name.trimmed,
                role: role,
                phone: phone
            )

            let userData = newUser.toDictionary()

            // Using Firestore Enterprise for production
            try await firestore.collection(AppConstants.Firebase.Collections.users).document(authResult.user.uid).setData(userData)
            print("✅ User saved to Firestore Enterprise database")

            // 3. Create default workspace for new user (permanent, multi-year)
            let currentYear = Calendar.current.component(.year, from: Date())
            do {
                let defaultWorkspace = try await WorkspaceManager.shared.createWorkspace(
                    name: "Personal Taxes",
                    type: .personal,
                    taxYear: currentYear,
                    owner: newUser,
                    description: "Your personal tax documents and filings"
                )
                print("✅ Created default workspace: \(defaultWorkspace.name)")
            } catch {
                print("⚠️ Warning: Failed to create default workspace: \(error)")
                print("⚠️ User can create workspace manually later")
                // Don't fail the entire signup if workspace creation fails
                // User will see "No workspace" message and can create one manually
            }

            // 4. Update local state
            self.user = newUser
            self.isAuthenticated = true

            print("✅ User created successfully: \(email)")
        } catch {
            errorMessage = handleAuthError(error)
            print("❌ Sign up error: \(error)")
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            // Validate input
            guard email.isValidEmail else {
                throw AuthError.invalidEmail
            }

            guard !password.isEmpty else {
                throw AuthError.unknown("Passwort darf nicht leer sein")
            }

            // 1. Sign in with Firebase Auth
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)

            // 2. Load user data from Firestore
            await loadUserData(userId: authResult.user.uid)

            print("✅ User signed in successfully: \(email)")
        } catch {
            errorMessage = handleAuthError(error)
            print("❌ Sign in error: \(error)")
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
            print("✅ User signed out successfully")
        } catch {
            print("❌ Sign out error: \(error)")
            throw error
        }
    }

    // MARK: - User Profile Management

    /// Update user profile data in Firestore
    func updateUser(userId: String, data: [String: Any]) async throws {
        guard !userId.isEmpty else {
            throw AuthError.unknown("User ID is empty")
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            // Phase 4: Increment profile version on changes
            let currentVersion = user?.profileVersion ?? 1
            let newVersion = currentVersion + 1

            // Add updatedAt timestamp and profile versioning
            var updateData = data
            updateData["updatedAt"] = Timestamp(date: Date())
            updateData["profileVersion"] = newVersion
            updateData["profileLastUpdatedAt"] = Timestamp(date: Date())

            // Update Firestore document
            try await firestore
                .collection(AppConstants.Firebase.Collections.users)
                .document(userId)
                .updateData(updateData)

            // Reload user data to reflect changes
            await loadUserData(userId: userId)

            print("✅ User profile updated successfully (version \(currentVersion) -> \(newVersion))")

            // Phase 4: Emit profile change event
            if let updatedUser = user {
                profileDidChange.send(updatedUser)
                print("📢 Profile change event emitted for version \(updatedUser.profileVersion)")

                // Trigger automatic PDF regeneration for all documents
                Task {
                    await PDFRegenerationService.shared.regenerateAllStale(for: updatedUser, priority: .high)
                    print("🔄 Triggered automatic PDF regeneration after profile update")
                }
            }
        } catch {
            print("❌ Error updating user profile: \(error)")
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Password Reset

    /// Send password reset email to the user
    func sendPasswordResetEmail(email: String) async throws {
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("✅ Password reset email sent to: \(email)")
        } catch {
            print("❌ Password reset error: \(error)")
            let errorMsg = handleAuthError(error)
            errorMessage = errorMsg
            throw error
        }
    }

    /// Send password reset SMS to the user's phone (requires Firebase Phone Auth)
    /// Note: This requires Firebase Phone Authentication to be enabled
    func sendPasswordResetSMS(phoneNumber: String) async throws {
        guard !phoneNumber.isEmpty else {
            throw AuthError.invalidEmail // Reusing error enum
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        // TODO: Implement phone-based password reset
        // This requires:
        // 1. Firebase Phone Auth to be enabled
        // 2. A custom backend function to link phone numbers to accounts
        // 3. SMS verification flow
        // For now, we'll throw an error indicating it's not yet implemented

        print("⚠️ SMS password reset not yet implemented for: \(phoneNumber)")
        throw AuthError.unknown("SMS password reset is not yet available. Please use email reset instead.")
    }

    // MARK: - Account Management

    /// Delete user account from Firebase Auth and Firestore
    func deleteAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }

        guard let userId = user?.id else {
            throw AuthError.unknown("User ID not found")
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            // 1. Delete user data from Firestore
            try await firestore
                .collection(AppConstants.Firebase.Collections.users)
                .document(userId)
                .delete()

            print("✅ User data deleted from Firestore")

            // 2. Delete Firebase Auth account
            try await currentUser.delete()

            print("✅ Firebase Auth account deleted")

            // 3. Clear local state
            self.user = nil
            self.isAuthenticated = false

            print("✅ Account deletion completed successfully")
        } catch {
            print("❌ Error deleting account: \(error)")
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Private Helpers

    private func loadUserData(userId: String) async {
        do {
            // Load from Firestore Enterprise with timeout
            print("📡 Loading user data from Firestore Enterprise for userId: \(userId)")

            // Create a task with timeout
            let firestoreTask = Task {
                try await firestore.collection(AppConstants.Firebase.Collections.users).document(userId).getDocument()
            }

            // Wait for the task with a 10-second timeout
            do {
                let document = try await withTimeout(seconds: 10) {
                    try await firestoreTask.value
                }

                if document.exists, let data = document.data() {
                    if let user = User.fromDictionary(data) {
                        self.user = user
                        self.isAuthenticated = true
                        print("✅ User data loaded successfully from Firestore Enterprise: \(user.email)")
                        print("🔍 ========== USER AUTHENTICATION DEBUG ==========")
                        print("   Firebase Auth UID: \(userId)")
                        print("   User Model ID: \(user.id ?? "nil")")
                        print("   Email: \(user.email)")
                        print("   Name: \(user.name)")
                        print("   IDs Match: \(userId == user.id ? "YES ✅" : "NO ❌")")
                        if userId != user.id {
                            print("   ⚠️ WARNING: Firebase Auth UID does not match User.id!")
                            print("   This will cause permission errors in Firebase Storage!")
                        }
                        print("=================================================")
                    } else {
                        print("❌ Failed to parse user data from Firestore")
                        errorMessage = "Benutzerdaten konnten nicht geladen werden"
                        // Still authenticate to allow app usage
                        self.isAuthenticated = true
                    }
                } else {
                    print("❌ User document not found in Firestore")
                    errorMessage = "Benutzerdaten nicht gefunden"
                    // Still authenticate to allow app usage
                    self.isAuthenticated = true
                }
            } catch is TimeoutError {
                print("⚠️ Firestore request timed out after 10 seconds")
                errorMessage = "Die Verbindung zum Server dauert zu lange. Bitte versuchen Sie es später erneut."
                // Still authenticate to allow app usage even on timeout
                self.isAuthenticated = true
            }
        } catch {
            print("❌ Error loading user data: \(error)")
            errorMessage = error.localizedDescription
            // Still authenticate to allow app usage even on error
            self.isAuthenticated = true
        }
    }

    // MARK: - Timeout Helper

    /// Custom timeout error
    private struct TimeoutError: Error {}

    /// Execute an async task with a timeout
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the actual operation
            group.addTask {
                try await operation()
            }

            // Add a timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            // Return the first one to complete
            let result = try await group.next()!

            // Cancel the other task
            group.cancelAll()

            return result
        }
    }

    /// Convert Firebase Auth errors to localized AuthError
    private func handleAuthError(_ error: Error) -> String {
        if let authError = error as? AuthError,
           let description = authError.errorDescription {
            return description
        }

        // Handle Firebase Auth errors
        let nsError = error as NSError
        guard nsError.domain == "FIRAuthErrorDomain" else {
            return error.localizedDescription
        }

        let authError: AuthError
        switch nsError.code {
        case 17007: // ERROR_EMAIL_ALREADY_IN_USE
            authError = .emailAlreadyInUse
        case 17008: // ERROR_INVALID_EMAIL
            authError = .invalidEmail
        case 17009: // ERROR_WRONG_PASSWORD
            authError = .wrongPassword
        case 17011: // ERROR_USER_NOT_FOUND
            authError = .userNotFound
        case 17026: // ERROR_WEAK_PASSWORD
            authError = .weakPassword
        case 17020: // ERROR_NETWORK_REQUEST_FAILED
            authError = .networkError
        default:
            return error.localizedDescription
        }

        return authError.errorDescription ?? error.localizedDescription
    }
}