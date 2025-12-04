//
//  TaxFormField.swift
//  TaxedGmbH_IOS
//
//  Canton-specific tax form field mappings for Swiss tax declarations
//  Maps TaxCategoryType to specific form field numbers in ZH, ZG, BS
//

import Foundation
import FirebaseFirestore

/// Main category grouping for tax form fields
enum TaxFormMainCategory: String, Codable {
    case einkommen = "Einkommen"          // Income
    case abzuege = "Abzüge"               // Deductions
    case vermoegen = "Vermögen"           // Wealth/Assets
    case schulden = "Schulden"            // Liabilities/Debts
    case persoenliches = "Persönliches"   // Personal Information

    var displayNameDe: String {
        return rawValue
    }

    var displayNameEn: String {
        switch self {
        case .einkommen: return "Income"
        case .abzuege: return "Deductions"
        case .vermoegen: return "Wealth"
        case .schulden: return "Liabilities"
        case .persoenliches: return "Personal Information"
        }
    }

    var displayNameFr: String {
        switch self {
        case .einkommen: return "Revenus"
        case .abzuege: return "Déductions"
        case .vermoegen: return "Fortune"
        case .schulden: return "Dettes"
        case .persoenliches: return "Informations personnelles"
        }
    }

    var displayNameIt: String {
        switch self {
        case .einkommen: return "Redditi"
        case .abzuege: return "Deduzioni"
        case .vermoegen: return "Sostanza"
        case .schulden: return "Debiti"
        case .persoenliches: return "Informazioni personali"
        }
    }
}

/// Category grouping for tax form fields (more specific than main category)
enum TaxFormCategory: String, Codable {
    // Income Categories
    case unselbstaendigeErwerbstaetigkeit = "Unselbständige Erwerbstätigkeit"
    case selbstaendigeErwerbstaetigkeit = "Selbständige Erwerbstätigkeit"
    case wertschriftenUndGuthaben = "Wertschriften und Guthaben"
    case liegenschaften = "Liegenschaften"
    case vorsorge = "Vorsorge"
    case uebrigeEinkuenfte = "Übrige Einkünfte"

    // Deduction Categories
    case berufsauslagen = "Berufsauslagen"
    case versicherungen = "Versicherungen und Zinsen"
    case weiterbildung = "Weiterbildung"
    case unterhalt = "Unterhalt und Renten"
    case spenden = "Spenden"
    case kinderbetreuung = "Kinderbetreuung"
    case schuldzinsen = "Schuldzinsen"

    // Wealth Categories
    case bankguthaben = "Bankguthaben"
    case wertpapiere = "Wertpapiere"
    case immobilien = "Immobilien"
    case fahrzeuge = "Fahrzeuge"
    case uebrigesVermoegen = "Übriges Vermögen"

    // Liabilities Categories
    case hypotheken = "Hypotheken"
    case kredite = "Kredite"
    case uebrigeSchulden = "Übrige Schulden"
}

/// Tax form field mapping from Firestore
struct TaxFormField: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    // Canton and field identification
    let canton: String                     // "ZH", "ZG", "BS"
    let fieldNumber: String                // "1.1", "181", "8"
    let labelNumber: String                // Display format: "Ziffer 1.1", "Code 181", "Field 8"

    // Mapping to app's tax category system
    let taxCategoryType: String?           // Maps to TaxCategoryType enum

    // Hierarchical categorization
    let mainCategory: String               // "Einkommen", "Abzüge", "Vermögen", "Schulden"
    let category: String                   // More specific grouping
    let subcategory: String?               // Optional fine-grained classification

    // Multilingual descriptions
    let descriptionDe: String
    let descriptionEn: String
    let descriptionFr: String
    let descriptionIt: String

    // Form metadata
    let pageNumber: Int?                   // Which page on the form
    let sortOrder: Int                     // Display ordering
    let isRequired: Bool                   // Whether field is mandatory
    let formType: String                   // "Hauptformular", "Formular K", "Supplementary"

    // Computed properties
    var cantonDisplayName: String {
        switch canton {
        case "ZH": return "Zürich"
        case "ZG": return "Zug"
        case "BS": return "Basel-Stadt"
        case "SO": return "Solothurn"
        default: return canton
        }
    }

    var mainCategoryEnum: TaxFormMainCategory? {
        TaxFormMainCategory(rawValue: mainCategory)
    }

    var categoryEnum: TaxFormCategory? {
        TaxFormCategory(rawValue: category)
    }

    var taxCategory: TaxCategoryType? {
        guard let taxCategoryType = taxCategoryType else { return nil }
        return TaxCategoryType(rawValue: taxCategoryType)
    }

    func localizedDescription(language: String = "de") -> String {
        switch language {
        case "de": return descriptionDe
        case "en": return descriptionEn
        case "fr": return descriptionFr
        case "it": return descriptionIt
        default: return descriptionDe
        }
    }

    // Firestore coding keys
    enum CodingKeys: String, CodingKey {
        case id
        case canton
        case fieldNumber
        case labelNumber
        case taxCategoryType
        case mainCategory
        case category
        case subcategory
        case descriptionDe
        case descriptionEn
        case descriptionFr
        case descriptionIt
        case pageNumber
        case sortOrder
        case isRequired
        case formType
    }
}

/// Extension for creating sample/seed data
extension TaxFormField {
    /// Create a tax form field for Zürich
    static func zurichField(
        fieldNumber: String,
        taxCategoryType: TaxCategoryType?,
        mainCategory: TaxFormMainCategory,
        category: TaxFormCategory,
        subcategory: String? = nil,
        descriptionDe: String,
        descriptionEn: String,
        descriptionFr: String,
        descriptionIt: String,
        pageNumber: Int? = nil,
        sortOrder: Int,
        isRequired: Bool = false
    ) -> TaxFormField {
        return TaxFormField(
            id: "ZH_\(fieldNumber)",
            canton: "ZH",
            fieldNumber: fieldNumber,
            labelNumber: "Ziffer \(fieldNumber)",
            taxCategoryType: taxCategoryType?.rawValue,
            mainCategory: mainCategory.rawValue,
            category: category.rawValue,
            subcategory: subcategory,
            descriptionDe: descriptionDe,
            descriptionEn: descriptionEn,
            descriptionFr: descriptionFr,
            descriptionIt: descriptionIt,
            pageNumber: pageNumber,
            sortOrder: sortOrder,
            isRequired: isRequired,
            formType: "Hauptformular"
        )
    }

    /// Create a tax form field for Zug
    static func zugField(
        code: String,
        taxCategoryType: TaxCategoryType?,
        mainCategory: TaxFormMainCategory,
        category: TaxFormCategory,
        subcategory: String? = nil,
        descriptionDe: String,
        descriptionEn: String,
        descriptionFr: String,
        descriptionIt: String,
        pageNumber: Int? = nil,
        sortOrder: Int,
        isRequired: Bool = false
    ) -> TaxFormField {
        return TaxFormField(
            id: "ZG_\(code)",
            canton: "ZG",
            fieldNumber: code,
            labelNumber: "Code \(code)",
            taxCategoryType: taxCategoryType?.rawValue,
            mainCategory: mainCategory.rawValue,
            category: category.rawValue,
            subcategory: subcategory,
            descriptionDe: descriptionDe,
            descriptionEn: descriptionEn,
            descriptionFr: descriptionFr,
            descriptionIt: descriptionIt,
            pageNumber: pageNumber,
            sortOrder: sortOrder,
            isRequired: isRequired,
            formType: "Formular K"
        )
    }

    /// Create a tax form field for Basel-Stadt
    static func baselField(
        fieldNumber: String,
        taxCategoryType: TaxCategoryType?,
        mainCategory: TaxFormMainCategory,
        category: TaxFormCategory,
        subcategory: String? = nil,
        descriptionDe: String,
        descriptionEn: String,
        descriptionFr: String,
        descriptionIt: String,
        pageNumber: Int? = nil,
        sortOrder: Int,
        isRequired: Bool = false
    ) -> TaxFormField {
        return TaxFormField(
            id: "BS_\(fieldNumber)",
            canton: "BS",
            fieldNumber: fieldNumber,
            labelNumber: "Feld \(fieldNumber)",
            taxCategoryType: taxCategoryType?.rawValue,
            mainCategory: mainCategory.rawValue,
            category: category.rawValue,
            subcategory: subcategory,
            descriptionDe: descriptionDe,
            descriptionEn: descriptionEn,
            descriptionFr: descriptionFr,
            descriptionIt: descriptionIt,
            pageNumber: pageNumber,
            sortOrder: sortOrder,
            isRequired: isRequired,
            formType: "Hauptformular"
        )
    }

    /// Create a tax form field for Solothurn
    static func solothurnField(
        index: String,
        taxCategoryType: TaxCategoryType?,
        mainCategory: TaxFormMainCategory,
        category: TaxFormCategory,
        subcategory: String? = nil,
        descriptionDe: String,
        descriptionEn: String,
        descriptionFr: String,
        descriptionIt: String,
        pageNumber: Int? = nil,
        sortOrder: Int,
        isRequired: Bool = false
    ) -> TaxFormField {
        return TaxFormField(
            id: "SO_\(index)",
            canton: "SO",
            fieldNumber: index,
            labelNumber: "Index \(index)",
            taxCategoryType: taxCategoryType?.rawValue,
            mainCategory: mainCategory.rawValue,
            category: category.rawValue,
            subcategory: subcategory,
            descriptionDe: descriptionDe,
            descriptionEn: descriptionEn,
            descriptionFr: descriptionFr,
            descriptionIt: descriptionIt,
            pageNumber: pageNumber,
            sortOrder: sortOrder,
            isRequired: isRequired,
            formType: "Hauptformular"
        )
    }
}
