//
//  ArrayExtensions.swift
//  TaxedGmbH_IOS
//
//  Array utility extensions for safe access
//

import Foundation

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}