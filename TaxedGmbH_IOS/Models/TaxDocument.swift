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

/// Enhanced workflow status for complete document lifecycle
enum DocumentWorkflowStatus: String, Codable {
    case uploading = "uploading"
    case processing = "processing"
    case pendingClassification = "pending_classification"
    case classified = "classified"
    case pendingReview = "pending_review"
    case reviewed = "reviewed"
    case approved = "approved"
    case coverGenerated = "cover_generated"
    case finalized = "finalized"
    case submitted = "submitted"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .uploading: return "workflow.uploading".localized
        case .processing: return "workflow.processing".localized
        case .pendingClassification: return "workflow.pending_classification".localized
        case .classified: return "workflow.classified".localized
        case .pendingReview: return "workflow.pending_review".localized
        case .reviewed: return "workflow.reviewed".localized
        case .approved: return "workflow.approved".localized
        case .coverGenerated: return "workflow.cover_generated".localized
        case .finalized: return "workflow.finalized".localized
        case .submitted: return "workflow.submitted".localized
        case .rejected: return "workflow.rejected".localized
        }
    }

    var icon: String {
        switch self {
        case .uploading: return "arrow.up.circle"
        case .processing: return "gearshape.2"
        case .pendingClassification: return "questionmark.circle"
        case .classified: return "checkmark.circle"
        case .pendingReview: return "eye.circle"
        case .reviewed: return "eye.circle.fill"
        case .approved: return "hand.thumbsup.circle.fill"
        case .coverGenerated: return "doc.badge.plus"
        case .finalized: return "checkmark.seal.fill"
        case .submitted: return "paperplane.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .uploading, .processing: return "gray"
        case .pendingClassification: return "orange"
        case .classified: return "blue"
        case .pendingReview: return "yellow"
        case .reviewed: return "cyan"
        case .approved: return "green"
        case .coverGenerated: return "purple"
        case .finalized: return "indigo"
        case .submitted: return "mint"
        case .rejected: return "red"
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

    // Enhanced Categorization (for accurate subcategory counting)
    var taxCategoryType: String?  // Explicit TaxCategoryType value (e.g., "salary", "mortgage")

    // Tax Office Requirements
    var purpose: String?          // Document purpose description
    var currency: String?         // Currency code (CHF, EUR, USD)
    var documentDate: Date?       // Date on the document itself

    // Workflow Tracking
    var workflowStatus: DocumentWorkflowStatus?  // Enhanced workflow state
    var coverSheetGenerated: Bool?               // Whether cover PDF has been created
    var coverSheetUrl: String?                   // URL to generated cover sheet PDF
    var processedDocumentUrl: String?            // URL to merged document+cover PDF
    var submissionPackageId: String?             // Link to tax submission package

    // Tax Office Submission
    var taxOfficeRequired: Bool?  // Whether this document needs tax office submission
    var includeInSubmission: Bool? // User wants to include in tax package
    var submittedAt: Date?        // When submitted to tax office
    var reviewedBy: String?       // User/expert ID who reviewed
    var approvedBy: String?       // User/expert ID who approved

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
        updatedAt: Date = Date(),
        taxCategoryType: String? = nil,
        purpose: String? = nil,
        currency: String? = nil,
        documentDate: Date? = nil,
        workflowStatus: DocumentWorkflowStatus? = nil,
        coverSheetGenerated: Bool? = nil,
        coverSheetUrl: String? = nil,
        processedDocumentUrl: String? = nil,
        submissionPackageId: String? = nil,
        taxOfficeRequired: Bool? = nil,
        includeInSubmission: Bool? = nil,
        submittedAt: Date? = nil,
        reviewedBy: String? = nil,
        approvedBy: String? = nil
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
        self.taxCategoryType = taxCategoryType
        self.purpose = purpose
        self.currency = currency
        self.documentDate = documentDate
        self.workflowStatus = workflowStatus
        self.coverSheetGenerated = coverSheetGenerated
        self.coverSheetUrl = coverSheetUrl
        self.processedDocumentUrl = processedDocumentUrl
        self.submissionPackageId = submissionPackageId
        self.taxOfficeRequired = taxOfficeRequired
        self.includeInSubmission = includeInSubmission
        self.submittedAt = submittedAt
        self.reviewedBy = reviewedBy
        self.approvedBy = approvedBy
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

        // Enhanced Categorization
        if let taxCategoryType = taxCategoryType { dict["taxCategoryType"] = taxCategoryType }

        // Tax Office Requirements
        if let purpose = purpose { dict["purpose"] = purpose }
        if let currency = currency { dict["currency"] = currency }
        if let documentDate = documentDate { dict["documentDate"] = Timestamp(date: documentDate) }

        // Workflow Tracking
        if let workflowStatus = workflowStatus { dict["workflowStatus"] = workflowStatus.rawValue }
        if let coverSheetGenerated = coverSheetGenerated { dict["coverSheetGenerated"] = coverSheetGenerated }
        if let coverSheetUrl = coverSheetUrl { dict["coverSheetUrl"] = coverSheetUrl }
        if let processedDocumentUrl = processedDocumentUrl { dict["processedDocumentUrl"] = processedDocumentUrl }
        if let submissionPackageId = submissionPackageId { dict["submissionPackageId"] = submissionPackageId }

        // Tax Office Submission
        if let taxOfficeRequired = taxOfficeRequired { dict["taxOfficeRequired"] = taxOfficeRequired }
        if let includeInSubmission = includeInSubmission { dict["includeInSubmission"] = includeInSubmission }
        if let submittedAt = submittedAt { dict["submittedAt"] = Timestamp(date: submittedAt) }
        if let reviewedBy = reviewedBy { dict["reviewedBy"] = reviewedBy }
        if let approvedBy = approvedBy { dict["approvedBy"] = approvedBy }

        return dict
    }

    // Create from Firestore dictionary
    static func fromDictionary(id: String, data: [String: Any]) -> TaxDocument? {
        guard let customerId = data["customerId"] as? String,
              let name = data["name"] as? String,
              let storageUrl = data["storageUrl"] as? String,
              let statusString = data["status"] as? String,
              let status = DocumentStatus(rawValue: statusString),
              let taxYear = data["taxYear"] as? Int else {
            return nil
        }

        // If category is missing or invalid, default to uncategorized
        let categoryString = data["category"] as? String
        let category = categoryString.flatMap { TaxCategory(rawValue: $0) } ?? .uncategorized

        let uploadedAt = (data["uploadedAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let processedAt = (data["processedAt"] as? Timestamp)?.dateValue()
        let reviewedAt = (data["reviewedAt"] as? Timestamp)?.dateValue()

        // Enhanced fields
        let documentDate = (data["documentDate"] as? Timestamp)?.dateValue()
        let submittedAt = (data["submittedAt"] as? Timestamp)?.dateValue()
        let workflowStatusString = data["workflowStatus"] as? String
        let workflowStatus = workflowStatusString.flatMap { DocumentWorkflowStatus(rawValue: $0) }

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
            updatedAt: updatedAt,
            taxCategoryType: data["taxCategoryType"] as? String,
            purpose: data["purpose"] as? String,
            currency: data["currency"] as? String,
            documentDate: documentDate,
            workflowStatus: workflowStatus,
            coverSheetGenerated: data["coverSheetGenerated"] as? Bool,
            coverSheetUrl: data["coverSheetUrl"] as? String,
            processedDocumentUrl: data["processedDocumentUrl"] as? String,
            submissionPackageId: data["submissionPackageId"] as? String,
            taxOfficeRequired: data["taxOfficeRequired"] as? Bool,
            includeInSubmission: data["includeInSubmission"] as? Bool,
            submittedAt: submittedAt,
            reviewedBy: data["reviewedBy"] as? String,
            approvedBy: data["approvedBy"] as? String
        )
    }
}
