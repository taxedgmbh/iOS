//
//  TaxedGmbH_IOSApp.swift
//  TaxedGmbH_IOS
//
//  Created by Emanuel Flury on 22.10.2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct TaxedGmbH_IOSApp: App {
    var body: some Scene {
        DocumentGroup(editing: .itemDocument, migrationPlan: TaxedGmbH_IOSMigrationPlan.self) {
            ContentView()
        }
    }
}

extension UTType {
    static var itemDocument: UTType {
        UTType(importedAs: "com.example.item-document")
    }
}

struct TaxedGmbH_IOSMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        TaxedGmbH_IOSVersionedSchema.self,
    ]

    static var stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct TaxedGmbH_IOSVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        Item.self,
    ]
}
