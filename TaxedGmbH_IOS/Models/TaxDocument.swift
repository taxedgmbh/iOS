//
//  TaxDocument.swift
//  TaxedGmbH_IOS
//
//  Tax document model with AI classification support
//

import Foundation
import FirebaseFirestore

enum TaxCategory: String, Codable, CaseIterable {
    // Swiss Domestic Categories
    case income = "income"
    case deduction = "deduction"
    case pillar = "pillar"
    case wealth = "wealth"

    // Foreign/International Categories
    case foreignIncome = "foreign_income"
    case foreignPension = "foreign_pension"
    case foreignWealth = "foreign_wealth"
    case taxTreaty = "tax_treaty"
    case foreignTax = "foreign_tax"

    case uncategorized = "uncategorized"

    var displayName: String {
        switch self {
        // Swiss Domestic
        case .income: return "documents.category.income".localized
        case .deduction: return "documents.category.deduction".localized
        case .pillar: return "documents.category.pillar".localized
        case .wealth: return "documents.category.wealth".localized

        // Foreign/International
        case .foreignIncome: return "documents.category.foreign_income".localized
        case .foreignPension: return "documents.category.foreign_pension".localized
        case .foreignWealth: return "documents.category.foreign_wealth".localized
        case .taxTreaty: return "documents.category.tax_treaty".localized
        case .foreignTax: return "documents.category.foreign_tax".localized

        case .uncategorized: return "documents.category.uncategorized".localized
        }
    }

    var icon: String {
        switch self {
        // Swiss Domestic
        case .income: return "dollarsign.circle.fill"
        case .deduction: return "minus.circle.fill"
        case .pillar: return "building.columns.fill"
        case .wealth: return "chart.line.uptrend.xyaxis"

        // Foreign/International
        case .foreignIncome: return "globe.europe.africa.fill"
        case .foreignPension: return "briefcase.fill"
        case .foreignWealth: return "banknote.fill"
        case .taxTreaty: return "doc.text.fill"
        case .foreignTax: return "percent"

        case .uncategorized: return "doc.circle.fill"
        }
    }

    var color: String {
        switch self {
        // Swiss Domestic
        case .income: return "green"
        case .deduction: return "blue"
        case .pillar: return "purple"
        case .wealth: return "orange"

        // Foreign/International
        case .foreignIncome: return "teal"
        case .foreignPension: return "indigo"
        case .foreignWealth: return "cyan"
        case .taxTreaty: return "mint"
        case .foreignTax: return "brown"

        case .uncategorized: return "gray"
        }
    }

    var isForeign: Bool {
        switch self {
        case .foreignIncome, .foreignPension, .foreignWealth, .taxTreaty, .foreignTax:
            return true
        default:
            return false
        }
    }
}

enum DocumentStatus: String, Codable {
    case uploading = "uploading"
    case processing = "processing"
    case pending = "pending"
    case reviewed = "reviewed"
    case approved = "approved"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .uploading: return "Wird hochgeladen..."
        case .processing: return "Wird verarbeitet..."
        case .pending: return "Wartet auf Überprüfung"
        case .reviewed: return "Überprüft"
        case .approved: return "Genehmigt"
        case .rejected: return "Abgelehnt"
        }
    }
}

struct TaxDocument: Codable, Identifiable {
    var id: String
    var customerId: String
    var expertId: String?
    var caseId: String?

    // File Information
    var name: String
    var storageUrl: String
    var thumbnailUrl: String?
    var fileSize: Int64?
    var mimeType: String?

    // AI Classification
    var category: TaxCategory
    var subcategory: String?
    var aiConfidence: Double?
    var extractedText: String?
    var aiSummary: String?

    // Status & Review
    var status: DocumentStatus
    var expertNotes: String?

    // Swiss Tax Information
    var taxYear: Int
    var canton: String?
    var municipality: String?
    var amount: Double?

    // Timestamps
    var uploadedAt: Date
    var processedAt: Date?
    var reviewedAt: Date?
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        customerId: String,
        expertId: String? = nil,
        caseId: String? = nil,
        name: String,
        storageUrl: String,
        thumbnailUrl: String? = nil,
        fileSize: Int64? = nil,
        mimeType: String? = nil,
        category: TaxCategory = .uncategorized,
        subcategory: String? = nil,
        aiConfidence: Double? = nil,
        extractedText: String? = nil,
        aiSummary: String? = nil,
        status: DocumentStatus = .uploading,
        expertNotes: String? = nil,
        taxYear: Int,
        canton: String? = nil,
        municipality: String? = nil,
        amount: Double? = nil,
        uploadedAt: Date = Date(),
        processedAt: Date? = nil,
        reviewedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.customerId = customerId
        self.expertId = expertId
        self.caseId = caseId
        self.name = name
        self.storageUrl = storageUrl
        self.thumbnailUrl = thumbnailUrl
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.category = category
        self.subcategory = subcategory
        self.aiConfidence = aiConfidence
        self.extractedText = extractedText
        self.aiSummary = aiSummary
        self.status = status
        self.expertNotes = expertNotes
        self.taxYear = taxYear
        self.canton = canton
        self.municipality = municipality
        self.amount = amount
        self.uploadedAt = uploadedAt
        self.processedAt = processedAt
        self.reviewedAt = reviewedAt
        self.updatedAt = updatedAt
    }

    // Convert to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "customerId": customerId,
            "name": name,
            "storageUrl": storageUrl,
            "category": category.rawValue,
            "status": status.rawValue,
            "taxYear": taxYear,
            "uploadedAt": Timestamp(date: uploadedAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]

        if let expertId = expertId { dict["expertId"] = expertId }
        if let caseId = caseId { dict["caseId"] = caseId }
        if let thumbnailUrl = thumbnailUrl { dict["thumbnailUrl"] = thumbnailUrl }
        if let fileSize = fileSize { dict["fileSize"] = fileSize }
        if let mimeType = mimeType { dict["mimeType"] = mimeType }
        if let subcategory = subcategory { dict["subcategory"] = subcategory }
        if let aiConfidence = aiConfidence { dict["aiConfidence"] = aiConfidence }
        if let extractedText = extractedText { dict["extractedText"] = extractedText }
        if let aiSummary = aiSummary { dict["aiSummary"] = aiSummary }
        if let expertNotes = expertNotes { dict["expertNotes"] = expertNotes }
        if let canton = canton { dict["canton"] = canton }
        if let municipality = municipality { dict["municipality"] = municipality }
        if let amount = amount { dict["amount"] = amount }
        if let processedAt = processedAt { dict["processedAt"] = Timestamp(date: processedAt) }
        if let reviewedAt = reviewedAt { dict["reviewedAt"] = Timestamp(date: reviewedAt) }

        return dict
    }

    // Create from Firestore dictionary
    static func fromDictionary(id: String, data: [String: Any]) -> TaxDocument? {
        guard let customerId = data["customerId"] as? String,
              let name = data["name"] as? String,
              let storageUrl = data["storageUrl"] as? String,
              let categoryString = data["category"] as? String,
              let category = TaxCategory(rawValue: categoryString),
              let statusString = data["status"] as? String,
              let status = DocumentStatus(rawValue: statusString),
              let taxYear = data["taxYear"] as? Int else {
            return nil
        }

        let uploadedAt = (data["uploadedAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let processedAt = (data["processedAt"] as? Timestamp)?.dateValue()
        let reviewedAt = (data["reviewedAt"] as? Timestamp)?.dateValue()

        return TaxDocument(
            id: id,
            customerId: customerId,
            expertId: data["expertId"] as? String,
            caseId: data["caseId"] as? String,
            name: name,
            storageUrl: storageUrl,
            thumbnailUrl: data["thumbnailUrl"] as? String,
            fileSize: data["fileSize"] as? Int64,
            mimeType: data["mimeType"] as? String,
            category: category,
            subcategory: data["subcategory"] as? String,
            aiConfidence: data["aiConfidence"] as? Double,
            extractedText: data["extractedText"] as? String,
            aiSummary: data["aiSummary"] as? String,
            status: status,
            expertNotes: data["expertNotes"] as? String,
            taxYear: taxYear,
            canton: data["canton"] as? String,
            municipality: data["municipality"] as? String,
            amount: data["amount"] as? Double,
            uploadedAt: uploadedAt,
            processedAt: processedAt,
            reviewedAt: reviewedAt,
            updatedAt: updatedAt
        )
    }
}
