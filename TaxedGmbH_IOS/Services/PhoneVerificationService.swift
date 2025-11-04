import Foundation
import FirebaseAuth
import Combine

// MARK: - Phone Verification Errors

enum PhoneVerificationError: LocalizedError {
    case invalidPhoneNumber
    case verificationFailed
    case invalidVerificationCode
    case tooManyRequests
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Ungültige Telefonnummer. Bitte geben Sie eine gültige Schweizer Nummer ein."
        case .verificationFailed:
            return "Verifizierung fehlgeschlagen. Bitte versuchen Sie es erneut."
        case .invalidVerificationCode:
            return "Ungültiger Verifizierungscode. Bitte überprüfen Sie Ihre Eingabe."
        case .tooManyRequests:
            return "Zu viele Anfragen. Bitte warten Sie einige Minuten."
        case .networkError:
            return "Netzwerkfehler. Bitte überprüfen Sie Ihre Internetverbindung."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Phone Verification Service

@MainActor
class PhoneVerificationService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var verificationId: String?
    @Published var phoneNumber: String = ""
    @Published var isPhoneVerified = false

    private var selectedCountry: Country = .default

    // Test mode for development - set to false once Firebase Phone Auth is fully configured
    // Production requires: Phone Auth enabled + APNs configured + UIDelegate implementation
    let useTestMode = true
    @Published var testVerificationCode = "123456"

    // MARK: - Phone Number Validation

    /// Validates phone number based on the selected country
    func isValidPhoneNumber(_ phone: String, for country: Country) -> Bool {
        // Remove all spaces and special characters except +
        let cleanedPhone = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        // Extract only digits (no + sign)
        let digitsOnly = cleanedPhone.filter { $0.isNumber }

        // Check length based on country requirements
        let isValidLength = digitsOnly.count >= country.minLength &&
                           digitsOnly.count <= country.maxLength

        // Simple validation: must have valid length and only contain digits
        return isValidLength && !digitsOnly.isEmpty
    }

    /// Formats phone number to E.164 format (+41791234567)
    func formatToE164(_ phone: String, country: Country) -> String {
        // Remove all spaces and special characters except +
        var cleanedPhone = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        // If starts with 0, replace with country dial code
        if cleanedPhone.hasPrefix("0") {
            cleanedPhone = "+\(country.dialCode)" + String(cleanedPhone.dropFirst())
        }

        // If doesn't start with +, add country dial code
        if !cleanedPhone.hasPrefix("+") {
            cleanedPhone = "+\(country.dialCode)" + cleanedPhone
        }

        return cleanedPhone
    }

    /// Formats phone number for display (+41 79 123 45 67)
    func formatForDisplay(_ phone: String, country: Country = .default) -> String {
        let e164 = formatToE164(phone, country: country)

        // Format: +41 79 123 45 67
        if e164.hasPrefix("+41") && e164.count == 12 {
            let countryCode = "+41"
            let index1 = e164.index(e164.startIndex, offsetBy: 3)
            let index2 = e164.index(e164.startIndex, offsetBy: 5)
            let index3 = e164.index(e164.startIndex, offsetBy: 8)
            let index4 = e164.index(e164.startIndex, offsetBy: 10)

            let part1 = e164[index1..<index2]  // 79
            let part2 = e164[index2..<index3]  // 123
            let part3 = e164[index3..<index4]  // 45
            let part4 = e164[index4...]        // 67

            return "\(countryCode) \(part1) \(part2) \(part3) \(part4)"
        }

        return e164
    }

    // MARK: - Send Verification Code

    /// Sends SMS verification code to the provided phone number
    func sendVerificationCode(to phoneNumber: String, country: Country) async throws {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        // Store country for resend
        self.selectedCountry = country

        // Validate phone number
        guard isValidPhoneNumber(phoneNumber, for: country) else {
            throw PhoneVerificationError.invalidPhoneNumber
        }

        let formattedPhone = formatToE164(phoneNumber, country: country)
        self.phoneNumber = formattedPhone

        if useTestMode {
            // TEMPORARY: Test mode - simulate sending SMS
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            self.verificationId = "test-verification-id-\(UUID().uuidString)"
            self.testVerificationCode = String(format: "%06d", Int.random(in: 100000...999999))
            print("📱 TEST MODE: Verification code sent to \(formattedPhone)")
            print("🔢 TEST CODE: \(self.testVerificationCode)")
            return
        }

        do {
            // Production: Use Firebase Phone Auth
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(formattedPhone, uiDelegate: nil)

            self.verificationId = verificationID
            print("✅ Verification code sent to \(formattedPhone)")

        } catch let error as NSError {
            print("❌ Phone verification error: \(error)")

            // Handle Firebase Auth errors
            switch error.code {
            case AuthErrorCode.invalidPhoneNumber.rawValue:
                throw PhoneVerificationError.invalidPhoneNumber
            case AuthErrorCode.tooManyRequests.rawValue:
                throw PhoneVerificationError.tooManyRequests
            case AuthErrorCode.networkError.rawValue:
                throw PhoneVerificationError.networkError
            default:
                throw PhoneVerificationError.unknown(error.localizedDescription)
            }
        }
    }

    // MARK: - Verify Code

    /// Verifies the SMS code entered by the user
    func verifyCode(_ code: String) async throws -> PhoneAuthCredential {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        // Validate code format (6 digits)
        guard code.count == 6, code.allSatisfy({ $0.isNumber }) else {
            throw PhoneVerificationError.invalidVerificationCode
        }

        guard let verificationId = verificationId else {
            throw PhoneVerificationError.verificationFailed
        }

        if useTestMode {
            // TEMPORARY: Test mode - verify against test code
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay

            if code == testVerificationCode {
                self.isPhoneVerified = true
                print("✅ TEST MODE: Phone verified successfully")
                // Return a mock credential (won't be used in test mode)
                return PhoneAuthProvider.provider().credential(
                    withVerificationID: verificationId,
                    verificationCode: code
                )
            } else {
                print("❌ TEST MODE: Invalid code. Expected: \(testVerificationCode), Got: \(code)")
                throw PhoneVerificationError.invalidVerificationCode
            }
        }

        // Production: Verify with Firebase
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationId,
            verificationCode: code
        )

        self.isPhoneVerified = true
        print("✅ Phone verified successfully")
        return credential
    }

    // MARK: - Resend Code

    /// Resends the verification code
    func resendVerificationCode() async throws {
        guard !phoneNumber.isEmpty else {
            throw PhoneVerificationError.invalidPhoneNumber
        }

        try await sendVerificationCode(to: phoneNumber, country: selectedCountry)
    }

    // MARK: - Reset

    /// Resets the verification state
    func reset() {
        phoneNumber = ""
        verificationId = nil
        isPhoneVerified = false
        errorMessage = nil
        isLoading = false
    }
}
