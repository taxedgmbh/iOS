//
//  TaxFormFieldService.swift
//  TaxedGmbH_IOS
//
//  Service for fetching canton-specific tax form field mappings from Firestore
//

import Foundation
import FirebaseFirestore

class TaxFormFieldService {
    static let shared = TaxFormFieldService()
    private let db = Firestore.firestore()
    private let collectionName = "taxFormFields"

    // In-memory cache for performance
    private var cachedFields: [String: [TaxFormField]] = [:]  // canton -> fields
    private var cacheTimestamp: [String: Date] = [:]
    private let cacheExpirationInterval: TimeInterval = 3600  // 1 hour

    private init() {}

    // MARK: - Fetch Methods

    /// Fetch all tax form fields for a specific canton
    func getFieldsForCanton(canton: String) async throws -> [TaxFormField] {
        // Check cache first
        if let cached = getCachedFields(for: canton) {
            print("✅ Returning cached tax form fields for canton: \(canton)")
            return cached
        }


        let snapshot = try await db.collection(collectionName)
            .whereField("canton", isEqualTo: canton)
            .order(by: "sortOrder")
            .getDocuments()

        let fields = try snapshot.documents.compactMap { doc -> TaxFormField? in
            try doc.data(as: TaxFormField.self)
        }

        // Cache the results
        cacheFields(fields, for: canton)

        print("✅ Fetched \(fields.count) tax form fields for \(canton)")
        return fields
    }

    /// Fetch field for a specific tax category type in a canton
    func getFieldForCategory(taxCategoryType: TaxCategoryType, canton: String) async throws -> TaxFormField? {

        let snapshot = try await db.collection(collectionName)
            .whereField("canton", isEqualTo: canton)
            .whereField("taxCategoryType", isEqualTo: taxCategoryType.rawValue)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else {
            print("⚠️ No tax form field found for \(taxCategoryType.rawValue) in \(canton)")
            return nil
        }

        let field = try doc.data(as: TaxFormField.self)
        print("✅ Found field: \(field.labelNumber) for \(taxCategoryType.rawValue)")
        return field
    }

    /// Fetch all fields for a specific main category (Income, Deductions, etc.)
    func getFieldsForMainCategory(mainCategory: TaxFormMainCategory, canton: String) async throws -> [TaxFormField] {

        let snapshot = try await db.collection(collectionName)
            .whereField("canton", isEqualTo: canton)
            .whereField("mainCategory", isEqualTo: mainCategory.rawValue)
            .order(by: "sortOrder")
            .getDocuments()

        let fields = try snapshot.documents.compactMap { doc -> TaxFormField? in
            try doc.data(as: TaxFormField.self)
        }

        print("✅ Found \(fields.count) fields for \(mainCategory.rawValue)")
        return fields
    }

    /// Fetch field by specific field number
    func getField(canton: String, fieldNumber: String) async throws -> TaxFormField? {
        let documentId = "\(canton)_\(fieldNumber)"

        let doc = try await db.collection(collectionName)
            .document(documentId)
            .getDocument()

        guard doc.exists else {
            print("⚠️ Field \(documentId) not found")
            return nil
        }

        let field = try doc.data(as: TaxFormField.self)
        print("✅ Found field: \(field.labelNumber)")
        return field
    }

    /// Fetch all fields (for admin/testing purposes)
    func getAllFields() async throws -> [TaxFormField] {

        let snapshot = try await db.collection(collectionName)
            .order(by: "canton")
            .order(by: "sortOrder")
            .getDocuments()

        let fields = try snapshot.documents.compactMap { doc -> TaxFormField? in
            try doc.data(as: TaxFormField.self)
        }

        print("✅ Fetched \(fields.count) total tax form fields")
        return fields
    }

    // MARK: - Batch Operations

    /// Fetch fields for multiple tax category types at once
    func getFieldsForCategories(taxCategoryTypes: [TaxCategoryType], canton: String) async throws -> [TaxCategoryType: TaxFormField] {

        var result: [TaxCategoryType: TaxFormField] = [:]

        // Firestore "in" queries are limited to 10 items, so we need to batch
        let batchSize = 10
        let batches = stride(from: 0, to: taxCategoryTypes.count, by: batchSize).map {
            Array(taxCategoryTypes[$0..<min($0 + batchSize, taxCategoryTypes.count)])
        }

        for batch in batches {
            let categoryStrings = batch.map { $0.rawValue }

            let snapshot = try await db.collection(collectionName)
                .whereField("canton", isEqualTo: canton)
                .whereField("taxCategoryType", in: categoryStrings)
                .getDocuments()

            for doc in snapshot.documents {
                if let field = try? doc.data(as: TaxFormField.self),
                   let categoryString = field.taxCategoryType,
                   let category = TaxCategoryType(rawValue: categoryString) {
                    result[category] = field
                }
            }
        }

        print("✅ Found \(result.count) field mappings")
        return result
    }

    // MARK: - Cache Management

    private func getCachedFields(for canton: String) -> [TaxFormField]? {
        guard let fields = cachedFields[canton],
              let timestamp = cacheTimestamp[canton],
              Date().timeIntervalSince(timestamp) < cacheExpirationInterval else {
            return nil
        }
        return fields
    }

    private func cacheFields(_ fields: [TaxFormField], for canton: String) {
        cachedFields[canton] = fields
        cacheTimestamp[canton] = Date()
    }

    func clearCache() {
        cachedFields.removeAll()
        cacheTimestamp.removeAll()
        print("🗑️ Tax form field cache cleared")
    }

    func clearCacheForCanton(_ canton: String) {
        cachedFields.removeValue(forKey: canton)
        cacheTimestamp.removeValue(forKey: canton)
        print("🗑️ Cache cleared for canton: \(canton)")
    }

    // MARK: - Admin/Seeding Methods

    /// Import tax form fields to Firestore (for initial data seeding)
    func importFields(_ fields: [TaxFormField]) async throws {
        print("📤 Importing \(fields.count) tax form fields to Firestore...")

        let batch = db.batch()

        for field in fields {
            guard let id = field.id else {
                print("⚠️ Skipping field without ID")
                continue
            }

            let docRef = db.collection(collectionName).document(id)

            do {
                try batch.setData(from: field, forDocument: docRef)
            } catch {
                print("❌ Error encoding field \(id): \(error)")
                throw error
            }
        }

        try await batch.commit()
        print("✅ Successfully imported \(fields.count) fields")

        // Clear cache after import
        clearCache()
    }

    /// Delete all fields for a canton (use with caution!)
    func deleteAllFieldsForCanton(_ canton: String) async throws {
        print("🗑️ Deleting all fields for canton: \(canton)")

        let snapshot = try await db.collection(collectionName)
            .whereField("canton", isEqualTo: canton)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        try await batch.commit()
        print("✅ Deleted \(snapshot.documents.count) fields for \(canton)")

        clearCacheForCanton(canton)
    }

    /// Update a single field
    func updateField(_ field: TaxFormField) async throws {
        guard let id = field.id else {
            throw NSError(domain: "TaxFormFieldService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Field ID is required"])
        }

        print("📝 Updating field: \(id)")

        let docRef = db.collection(collectionName).document(id)
        try docRef.setData(from: field)

        print("✅ Field updated successfully")

        // Clear cache for this canton
        clearCacheForCanton(field.canton)
    }
}

// MARK: - Convenience Methods

extension TaxFormFieldService {
    /// Get the formatted label number for display on cover sheets
    func getLabelNumber(for taxCategoryType: TaxCategoryType, canton: String) async -> String? {
        do {
            let field = try await getFieldForCategory(taxCategoryType: taxCategoryType, canton: canton)
            return field?.labelNumber
        } catch {
            print("❌ Error fetching label number: \(error)")
            return nil
        }
    }

    /// Check if a specific tax category is relevant for a canton
    func isCategoryRelevantForCanton(taxCategoryType: TaxCategoryType, canton: String) async -> Bool {
        do {
            let field = try await getFieldForCategory(taxCategoryType: taxCategoryType, canton: canton)
            return field != nil
        } catch {
            return false
        }
    }
}
