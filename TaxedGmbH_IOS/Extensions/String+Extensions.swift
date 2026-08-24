//
//  String+Extensions.swift
//  TaxedGmbH_IOS
//

import Foundation

nonisolated extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        trimmed.isEmpty
    }
}
