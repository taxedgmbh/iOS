//
//  TaxIndexMapping.swift
//  TaxedGmbH_IOS
//
//  Model for dynamic tax index field mappings from Firestore
//  Maps tax categories to canton-specific index numbers and required input fields
//

import Foundation
import FirebaseFirestore

/// Field type for dynamic tax form inputs
enum FieldType: String, Codable {
    case currency = "currency"
    case percentage = "percentage"
    case integer = "integer"
    case text = "text"
    case date = "date"

    var keyboardType: UIKeyboardType {
        switch self {
        case .currency, .percentage:
            return .decimalPad
        case .integer:
            return .numberPad
        case .text:
            return .default
        case .date:
            return .default
        }
    }
}

/// Definition of a single input field
struct FieldDefinition: Identifiable, Codable {
    var id: String { name }
    let name: String
    let type: FieldType
    let required: Bool

    init(name: String, type: FieldType, required: Bool) {
        self.name = name
        self.type = type
        self.required = required
    }
}

/// Tax index mapping from Firestore database
/// Maps a tax category to its canton-specific index number and required fields
struct TaxIndexMapping: Codable, Identifiable {
    var id: String { "\(canton)_\(index)" }

    let canton: String
    let index: String
    let mainCategory: String
    let subCategory: String
    let person: String?

    // Field definitions (up to 5 fields)
    let field1Name: String?
    let field1Type: String?
    let field1Required: Bool

    let field2Name: String?
    let field2Type: String?
    let field2Required: Bool

    let field3Name: String?
    let field3Type: String?
    let field3Required: Bool

    let field4Name: String?
    let field4Type: String?
    let field4Required: Bool

    let field5Name: String?
    let field5Type: String?
    let field5Required: Bool

    // Metadata
    let currencyRequired: Bool
    let fxRequired: Bool
    let displayFormula: String?
    let notes: String?

    // Computed property: Get all defined fields
    var fields: [FieldDefinition] {
        var result: [FieldDefinition] = []

        // Field 1
        if let name = field1Name, !name.isEmpty,
           let typeString = field1Type,
           let type = FieldType(rawValue: typeString) {
            result.append(FieldDefinition(name: name, type: type, required: field1Required))
        }

        // Field 2
        if let name = field2Name, !name.isEmpty,
           let typeString = field2Type,
           let type = FieldType(rawValue: typeString) {
            result.append(FieldDefinition(name: name, type: type, required: field2Required))
        }

        // Field 3
        if let name = field3Name, !name.isEmpty,
           let typeString = field3Type,
           let type = FieldType(rawValue: typeString) {
            result.append(FieldDefinition(name: name, type: type, required: field3Required))
        }

        // Field 4
        if let name = field4Name, !name.isEmpty,
           let typeString = field4Type,
           let type = FieldType(rawValue: typeString) {
            result.append(FieldDefinition(name: name, type: type, required: field4Required))
        }

        // Field 5
        if let name = field5Name, !name.isEmpty,
           let typeString = field5Type,
           let type = FieldType(rawValue: typeString) {
            result.append(FieldDefinition(name: name, type: type, required: field5Required))
        }

        return result
    }

    /// Firestore field mapping
    enum CodingKeys: String, CodingKey {
        case canton = "Canton"
        case index = "Index"
        case mainCategory = "Main_Category"
        case subCategory = "Sub_Category"
        case person = "Person"

        case field1Name = "Field1_Name_DE"
        case field1Type = "Field1_Type"
        case field1Required = "Field1_Required"

        case field2Name = "Field2_Name_DE"
        case field2Type = "Field2_Type"
        case field2Required = "Field2_Required"

        case field3Name = "Field3_Name_DE"
        case field3Type = "Field3_Type"
        case field3Required = "Field3_Required"

        case field4Name = "Field4_Name_DE"
        case field4Type = "Field4_Type"
        case field4Required = "Field4_Required"

        case field5Name = "Field5_Name_DE"
        case field5Type = "Field5_Type"
        case field5Required = "Field5_Required"

        case currencyRequired = "Currency_Required"
        case fxRequired = "FX_Required"
        case displayFormula = "Display_Formula"
        case notes = "Notes"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        canton = try container.decode(String.self, forKey: .canton)
        index = try container.decode(String.self, forKey: .index)
        mainCategory = try container.decode(String.self, forKey: .mainCategory)
        subCategory = try container.decode(String.self, forKey: .subCategory)
        person = try container.decodeIfPresent(String.self, forKey: .person)

        field1Name = try container.decodeIfPresent(String.self, forKey: .field1Name)
        field1Type = try container.decodeIfPresent(String.self, forKey: .field1Type)
        // Handle "Yes"/"No" strings from CSV
        if let reqString = try container.decodeIfPresent(String.self, forKey: .field1Required) {
            field1Required = reqString.lowercased() == "yes"
        } else {
            field1Required = false
        }

        field2Name = try container.decodeIfPresent(String.self, forKey: .field2Name)
        field2Type = try container.decodeIfPresent(String.self, forKey: .field2Type)
        if let reqString = try container.decodeIfPresent(String.self, forKey: .field2Required) {
            field2Required = reqString.lowercased() == "yes"
        } else {
            field2Required = false
        }

        field3Name = try container.decodeIfPresent(String.self, forKey: .field3Name)
        field3Type = try container.decodeIfPresent(String.self, forKey: .field3Type)
        if let reqString = try container.decodeIfPresent(String.self, forKey: .field3Required) {
            field3Required = reqString.lowercased() == "yes"
        } else {
            field3Required = false
        }

        field4Name = try container.decodeIfPresent(String.self, forKey: .field4Name)
        field4Type = try container.decodeIfPresent(String.self, forKey: .field4Type)
        if let reqString = try container.decodeIfPresent(String.self, forKey: .field4Required) {
            field4Required = reqString.lowercased() == "yes"
        } else {
            field4Required = false
        }

        field5Name = try container.decodeIfPresent(String.self, forKey: .field5Name)
        field5Type = try container.decodeIfPresent(String.self, forKey: .field5Type)
        if let reqString = try container.decodeIfPresent(String.self, forKey: .field5Required) {
            field5Required = reqString.lowercased() == "yes"
        } else {
            field5Required = false
        }

        // Currency/FX
        if let currString = try container.decodeIfPresent(String.self, forKey: .currencyRequired) {
            currencyRequired = currString.lowercased() == "yes"
        } else {
            currencyRequired = false
        }

        if let fxString = try container.decodeIfPresent(String.self, forKey: .fxRequired) {
            fxRequired = fxString.lowercased() == "yes"
        } else {
            fxRequired = false
        }

        displayFormula = try container.decodeIfPresent(String.self, forKey: .displayFormula)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}
