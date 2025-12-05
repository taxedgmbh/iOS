import Foundation
import Combine
import LocalAuthentication
import SwiftUI
import FirebaseAuth

enum BiometricType {
    case none
    case touchID
    case faceID
}

class BiometricAuthService: ObservableObject {
    @Published var biometricType: BiometricType = .none
    @Published var canEvaluatePolicy = false
    @Published var isAuthenticated = false
    @Published var errorMessage: String?

    private let context = LAContext()
    private let userDefaults = UserDefaults.standard

    // Keys for UserDefaults
    private let kBiometricEnabled = "biometric_enabled"
    private let kSavedEmail = "saved_email"
    private let kSavedPasswordToken = "saved_password_token"

    init() {
        checkBiometricAvailability()
    }

    // MARK: - Check Biometric Availability

    func checkBiometricAvailability() {
        var error: NSError?

        canEvaluatePolicy = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        // Determine biometric type
        switch context.biometryType {
        case .none:
            biometricType = .none
        case .touchID:
            biometricType = .touchID
        case .faceID:
            biometricType = .faceID
        case .opticID:
            biometricType = .faceID  // Treat Optic ID as Face ID
        @unknown default:
            biometricType = .none
        }
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometric(completion: @escaping @Sendable (Bool, String?) -> Void) {
        let reason = biometricType == .faceID ?
            "Mit Face ID bei Taxed anmelden" :
            "Mit Touch ID bei Taxed anmelden"

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    completion(true, nil)
                } else {
                    self.isAuthenticated = false
                    let errorMsg = self.evaluateBiometricError(error)
                    self.errorMessage = errorMsg
                    completion(false, errorMsg)
                }
            }
        }
    }

    // MARK: - Save Credentials for Biometric

    func saveBiometricCredentials(email: String, password: String) {
        // Enable biometric authentication
        userDefaults.set(true, forKey: kBiometricEnabled)
        userDefaults.set(email, forKey: kSavedEmail)

        // In production, use Keychain instead of UserDefaults for password
        // This is simplified for demonstration
        if let data = password.data(using: .utf8) {
            userDefaults.set(data.base64EncodedString(), forKey: kSavedPasswordToken)
        }
    }

    func getBiometricCredentials() -> (email: String, password: String)? {
        guard isBiometricEnabled(),
              let email = userDefaults.string(forKey: kSavedEmail),
              let token = userDefaults.string(forKey: kSavedPasswordToken),
              let data = Data(base64Encoded: token),
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        return (email, password)
    }

    func clearBiometricCredentials() {
        userDefaults.removeObject(forKey: kBiometricEnabled)
        userDefaults.removeObject(forKey: kSavedEmail)
        userDefaults.removeObject(forKey: kSavedPasswordToken)
        isAuthenticated = false
    }

    func isBiometricEnabled() -> Bool {
        return userDefaults.bool(forKey: kBiometricEnabled) && canEvaluatePolicy
    }

    // MARK: - Error Handling

    private func evaluateBiometricError(_ error: Error?) -> String {
        guard let error = error as? LAError else {
            return "Unbekannter Fehler"
        }

        switch error.code {
        case .authenticationFailed:
            return "Biometrische Authentifizierung fehlgeschlagen"
        case .userCancel:
            return "Authentifizierung abgebrochen"
        case .userFallback:
            return "Bitte verwenden Sie Ihr Passwort"
        case .biometryNotAvailable:
            return "Biometrische Authentifizierung nicht verfügbar"
        case .biometryNotEnrolled:
            return biometricType == .faceID ?
                "Face ID ist nicht eingerichtet" :
                "Touch ID ist nicht eingerichtet"
        case .biometryLockout:
            return "Zu viele fehlgeschlagene Versuche"
        default:
            return "Authentifizierung fehlgeschlagen"
        }
    }

    // MARK: - Quick Login

    func performQuickLogin(authService: AuthenticationService) async -> Bool {
        guard isBiometricEnabled(),
              let credentials = getBiometricCredentials() else {
            return false
        }

        return await withCheckedContinuation { continuation in
            authenticateWithBiometric { success, error in
                if success {
                    Task { @MainActor in
                        await authService.signIn(
                            email: credentials.email,
                            password: credentials.password
                        )
                        continuation.resume(returning: authService.isAuthenticated)
                    }
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    // MARK: - Biometric Icon

    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.fill"
        }
    }

    var biometricName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Passcode"
        }
    }
}