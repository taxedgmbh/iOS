//
//  TaxIndexService.swift
//  TaxedGmbH_IOS
//
//  Service for querying tax index mappings from Firestore
//  Provides canton-specific field requirements for tax documents
//

import Foundation
import FirebaseFirestore

@MainActor
class TaxIndexService {
    static let shared = TaxIndexService()

    private let db = Firestore.firestore()
    private let collectionName = "taxIndexes"

    // Cache for performance
    private var cache: [String: TaxIndexMapping] = [:]

    private init() {}

    /// Get tax index mapping for a specific canton and tax category
    /// - Parameters:
    ///   - canton: Canton code (e.g., "ZH", "AG")
    ///   - category: Tax category type
    ///   - person: Optional person number (1 or 2) for joint filings
    /// - Returns: Tax index mapping if found
    func getIndexMapping(
        canton: String,
        category: TaxCategoryType,
        person: Int? = nil
    ) async throws -> TaxIndexMapping? {
        print("📊 TaxIndexService: Querying mapping for \(canton) / \(category.rawValue)")

        // Build cache key
        let cacheKey = "\(canton)_\(category.rawValue)_\(person ?? 0)"

        // Check cache first
        if let cached = cache[cacheKey] {
            print("✅ Found in cache")
            return cached
        }

        // Query Firestore
        // First, try to find by exact subcategory match
        let subcategory = category.formCategory.rawValue
        print("🔍 Query details:")
        print("   - Collection: \(collectionName)")
        print("   - Canton: \(canton)")
        print("   - Sub_Category: \(subcategory)")
        print("   - Category type: \(category.rawValue)")

        var query = db.collection(collectionName)
            .whereField("Canton", isEqualTo: canton)
            .whereField("Sub_Category", isEqualTo: subcategory)

        // Add person filter if specified
        if let personNum = person {
            let personString = "Person \(personNum)"
            print("   - Person filter: \(personString)")
            query = query.whereField("Person", isEqualTo: personString)
        }

        let snapshot = try await query.getDocuments()
        print("📊 Query returned \(snapshot.documents.count) documents")

        // Debug: Print all documents found
        for (index, doc) in snapshot.documents.enumerated() {
            print("   Document \(index + 1):")
            print("   - ID: \(doc.documentID)")
            let data = doc.data()
            print("   - Canton: \(data["Canton"] ?? "nil")")
            print("   - Index: \(data["Index"] ?? "nil")")
            print("   - Sub_Category: \(data["Sub_Category"] ?? "nil")")
            print("   - Main_Category: \(data["Main_Category"] ?? "nil")")
        }

        if let document = snapshot.documents.first {
            let mapping = try document.data(as: TaxIndexMapping.self)
            cache[cacheKey] = mapping
            print("✅ Found mapping: Index \(mapping.index)")
            return mapping
        }

        // Fallback: Search by main category
        let mainCat = category.mainFormCategory.rawValue
        let fallbackQuery = db.collection(collectionName)
            .whereField("Canton", isEqualTo: canton)
            .whereField("Main_Category", isEqualTo: mainCat)
            .limit(to: 1)

        let fallbackSnapshot = try await fallbackQuery.getDocuments()

        if let document = fallbackSnapshot.documents.first {
            let mapping = try document.data(as: TaxIndexMapping.self)
            cache[cacheKey] = mapping
            print("⚠️ Using fallback mapping: Index \(mapping.index)")
            return mapping
        }

        print("❌ No mapping found for \(canton) / \(category.rawValue)")
        return nil
    }

    /// Get index mapping by direct index number
    /// - Parameters:
    ///   - canton: Canton code
    ///   - index: Index number (e.g., "100", "2.21")
    /// - Returns: Tax index mapping if found
    func getMapping(canton: String, index: String) async throws -> TaxIndexMapping? {
        let cacheKey = "\(canton)_\(index)"

        if let cached = cache[cacheKey] {
            return cached
        }

        let query = db.collection(collectionName)
            .whereField("Canton", isEqualTo: canton)
            .whereField("Index", isEqualTo: index)
            .limit(to: 1)

        let snapshot = try await query.getDocuments()

        if let document = snapshot.documents.first {
            let mapping = try document.data(as: TaxIndexMapping.self)
            cache[cacheKey] = mapping
            return mapping
        }

        return nil
    }

    /// Get all index mappings for a canton
    /// - Parameter canton: Canton code
    /// - Returns: Array of all tax index mappings for the canton
    func getAllMappings(for canton: String) async throws -> [TaxIndexMapping] {
        print("📊 Loading all mappings for canton: \(canton)")

        let query = db.collection(collectionName)
            .whereField("Canton", isEqualTo: canton)

        let snapshot = try await query.getDocuments()

        let mappings = try snapshot.documents.compactMap { document in
            try document.data(as: TaxIndexMapping.self)
        }

        print("✅ Loaded \(mappings.count) mappings for \(canton)")
        return mappings
    }

    /// Clear the cache
    func clearCache() {
        cache.removeAll()
        print("🗑️ TaxIndexService cache cleared")
    }

    /// Preload mappings for a canton (for performance)
    func preloadMappings(for canton: String) async {
        do {
            let mappings = try await getAllMappings(for: canton)
            for mapping in mappings {
                let key = "\(canton)_\(mapping.index)"
                cache[key] = mapping
            }
            print("✅ Preloaded \(mappings.count) mappings for \(canton)")
        } catch {
            print("❌ Failed to preload mappings: \(error)")
        }
    }
}

// MARK: - TaxFormCategory Extension

extension TaxFormCategory {
    var rawValue: String {
        switch self {
        case .unselbstaendigeErwerbstaetigkeit: return "Haupterwerb"
        case .selbstaendigeErwerbstaetigkeit: return "Selbständig"
        case .wertschriftenUndGuthaben: return "Wertschriften"
        case .liegenschaften: return "Liegenschaften"
        case .vorsorge: return "Vorsorge"
        case .uebrigeEinkuenfte: return "Übrige Einkünfte"
        case .berufsauslagen: return "Berufsauslagen"
        case .versicherungen: return "Versicherungsprämien"
        case .weiterbildung: return "Weiterbildung"
        case .unterhalt: return "Unterhaltsbeiträge"
        case .spenden: return "Spenden"
        case .kinderbetreuung: return "Kinderbetreuung"
        case .schuldzinsen: return "Schuldzinsen"
        case .bankguthaben: return "Guthaben"
        case .wertpapiere: return "Wertpapiere"
        case .immobilien: return "Immobilien"
        case .fahrzeuge: return "Fahrzeuge"
        case .uebrigesVermoegen: return "Übrige Vermögenswerte"
        case .hypotheken: return "Hypotheken"
        case .kredite: return "Kredite"
        case .uebrigeSchulden: return "Übrige Schulden"
        }
    }
}

// MARK: - TaxFormMainCategory Extension

extension TaxFormMainCategory {
    var rawValue: String {
        switch self {
        case .einkommen: return "Einkommen"
        case .abzuege: return "Abzüge"
        case .vermoegen: return "Vermögen"
        case .schulden: return "Schulden"
        case .persoenliches: return "Persönliches"
        }
    }
}
