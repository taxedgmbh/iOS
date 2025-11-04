//
//  String+Extensions.swift
//  TaxedGmbH_IOS
//
//  String extensions for common operations
//

import Foundation

extension String {

    // MARK: - Validation

    var isValidEmail: Bool {
        return ValidationHelper.isValidEmail(self)
    }

    var isValidPassword: Bool {
        return ValidationHelper.isValidPassword(self)
    }

    var isValidSwissPhone: Bool {
        return ValidationHelper.isValidSwissPhone(self)
    }

    // MARK: - Trimming

    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        return self.trimmed.isEmpty
    }

    // MARK: - Formatting

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}
