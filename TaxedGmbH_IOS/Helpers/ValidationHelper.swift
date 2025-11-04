//
//  ValidationHelper.swift
//  TaxedGmbH_IOS
//
//  Validation utilities for user input
//

import Foundation

struct ValidationHelper {

    // MARK: - Email Validation

    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Password Validation

    static func isValidPassword(_ password: String) -> Bool {
        // Must be at least minimum length
        guard password.count >= AppConstants.Validation.minimumPasswordLength else {
            return false
        }

        // Must contain at least one letter
        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil

        // Must contain at least one number
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil

        return hasLetter && hasNumber
    }

    static func passwordStrength(_ password: String) -> PasswordStrength {
        let length = password.count
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil

        var strength = 0
        if length >= 8 { strength += 1 }
        if length >= 12 { strength += 1 }
        if hasUppercase { strength += 1 }
        if hasLowercase { strength += 1 }
        if hasNumber { strength += 1 }
        if hasSpecialChar { strength += 1 }

        switch strength {
        case 0...2: return .weak
        case 3...4: return .medium
        default: return .strong
        }
    }

    enum PasswordStrength {
        case weak, medium, strong

        var description: String {
            switch self {
            case .weak: return "Schwach"
            case .medium: return "Mittel"
            case .strong: return "Stark"
            }
        }

        var color: String {
            switch self {
            case .weak: return "red"
            case .medium: return "orange"
            case .strong: return "green"
            }
        }
    }

    // MARK: - File Validation

    static func isValidFileSize(_ size: Int64) -> Bool {
        return size <= AppConstants.Validation.maximumFileSize
    }

    static func isValidImageType(_ mimeType: String) -> Bool {
        return AppConstants.Validation.supportedImageTypes.contains(mimeType)
    }

    // MARK: - Swiss Specific Validation

    static func isValidSwissPhone(_ phone: String) -> Bool {
        // Swiss phone: +41 XX XXX XX XX or 0XX XXX XX XX
        let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
        let swissPhoneRegex = "^(\\+41|0)[0-9]{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", swissPhoneRegex)
        return phonePredicate.evaluate(with: cleanPhone)
    }

    // MARK: - Name Validation

    static func isValidName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 2 && trimmedName.count <= 50
    }
}
