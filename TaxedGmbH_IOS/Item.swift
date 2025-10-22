//
//  Item.swift
//  TaxedGmbH_IOS
//
//  Created by Emanuel Flury on 22.10.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
