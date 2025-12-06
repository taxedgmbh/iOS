//
//  DocumentManager.swift
//  TaxedGmbH_IOS
//
//  Centralized document management service - SINGLE SOURCE OF TRUTH
//

import Foundation
import Combine
import SwiftUI

@MainActor
class DocumentManager: ObservableObject {
    static let shared = DocumentManager()

    // Use lazy to avoid initialization order crashes
    private lazy var firestoreService = FirestoreService.shared
    private lazy var storageService = StorageService.shared
    private lazy var documentProcessor = DocumentProcessorService.shared
    private lazy var coverSheetService = CoverSheetService.shared
    private lazy var pdfRegenerationService = PDFRegenerationService.shared

    // Published state
    @Published var allDocuments: [TaxDocument] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    // Computed properties for different views
    var recentDocuments: [TaxDocument] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return allDocuments
            .filter { document in
                // Show if uploaded recently OR updated recently (both are non-optional)
                document.uploadedAt >= thirtyDaysAgo ||
                document.updatedAt >= thirtyDaysAgo
            }
            .sorted { doc1, doc2 in
                // Sort by most recently modified first (updatedAt is always set)
                return doc1.updatedAt > doc2.updatedAt
            }
    }

    var pendingReviewDocuments: [TaxDocument] {
        allDocuments.filter {
            $0.status == .pending || $0.status == .processing
        }
    }

    var documentsByCategory: [TaxCategory: [TaxDocument]] {
        Dictionary(grouping: allDocuments) { $0.category }
    }

    var documentsBySubcategory: [String: [TaxDocument]] {
        Dictionary(grouping: allDocuments.compactMap { document -> (String, TaxDocument)? in
            guard let subcategory = document.subcategory else { return nil }
            return (subcategory, document)
        }, by: { $0.0 })
        .mapValues { $0.map { $0.1 } }
    }

    private init() {
        // Initialization complete
        // Note: Profile change subscription removed to prevent initialization crash
        // PDF regeneration can be triggered manually when needed
    }

    // MARK: - Load Documents

    /// Load documents for a specific workspace and tax year (preferred method for workspace-centric architecture)
    /// Note: This method assumes the calling code has already verified workspace access.
    /// For security, views should ensure users can only load documents from their workspaces.
    /// CRITICAL: Filters by BOTH workspaceId AND taxYear to ensure strict year separation
    func loadDocuments(forWorkspace workspace: Workspace) async {
        guard let workspaceId = workspace.id else {
            print("❌ Cannot load documents: Workspace has no ID")
            self.error = "Workspace ID is missing"
            return
        }

        isLoading = true
        error = nil

        do {
            let documents = try await firestoreService.getDocumentsForWorkspace(
                workspaceId: workspaceId,
                taxYear: workspace.taxYear  // ✅ CRITICAL: Pass tax year for filtering
            )
            allDocuments = documents.sorted { $0.uploadedAt > $1.uploadedAt }
            print("✅ Loaded \(documents.count) documents for workspace \(workspace.name) (tax year: \(workspace.taxYear))")
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to load documents for workspace: \(error)")
        }

        isLoading = false
    }

    /// Load documents for a user (legacy method - loads ALL user documents across workspaces)
    func loadDocuments(for userId: String) async {
        isLoading = true
        error = nil

        do {
            let documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)
            allDocuments = documents.sorted { $0.uploadedAt > $1.uploadedAt }
            print("✅ Loaded \(documents.count) documents for user")
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to load documents for user: \(error)")
        }

        isLoading = false
    }

    // MARK: - Upload Document

    func uploadDocument(
        image: UIImage,
        userId: String,
        workspaceId: String? = nil,
        categoryType: TaxCategoryType?,
        processingResult: DocumentProcessingResult?,
        taxYear: Int,
        user: User? = nil
    ) async throws -> TaxDocument {
        print("📤 Starting document upload...")

        // Ensure we have a valid workspaceId for upload
        guard let validWorkspaceId = workspaceId else {
            print("❌ Error: No workspaceId provided for document upload")
            throw NSError(domain: "DocumentManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Workspace ID is required for document upload"
            ])
        }

        // Validate user has access to this workspace
        do {
            let workspace = try await WorkspaceManager.shared.getWorkspace(workspaceId: validWorkspaceId)
            guard workspace.isMember(userId: userId) else {
                print("❌ Error: User \(userId) is not a member of workspace \(validWorkspaceId)")
                throw NSError(domain: "DocumentManager", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "You do not have access to this workspace"
                ])
            }
            print("✅ Validated user is member of workspace")
        } catch {
            print("❌ Error validating workspace access: \(error)")
            throw error
        }

        // Generate attachment number
        let uploadDate = Date()
        let attachmentNumber = generateAttachmentNumber(for: categoryType, uploadDate: uploadDate)
        print("📎 Generated attachment number: \(attachmentNumber)")

        // Determine category
        let category = convertToTaxCategory(categoryType)
        let categoryRawValue = convertCategoryGroupToStoragePath(categoryType?.categoryGroup ?? .income)
        let documentType = categoryType?.rawValue ?? "uncategorized"

        // Upload to storage - now returns (downloadURL, documentId) tuple
        let (downloadURL, documentId) = try await storageService.uploadDocumentAsPDF(
            image: image,
            workspaceId: validWorkspaceId,
            documentType: documentType,
            taxYear: taxYear,
            category: categoryRawValue,
            subcategory: categoryType?.rawValue ?? "",
            attachmentNumber: attachmentNumber
        ) { progress in
            print("📊 Upload progress: \(Int(progress * 100))%")
        }

        print("✅ Received documentId from storage: \(documentId)")

        // Create document record
        let document = TaxDocument(
            customerId: userId,
            workspaceId: workspaceId,
            name: extractFileName(from: downloadURL),
            storageUrl: downloadURL,
            category: category,
            subcategory: categoryType?.rawValue,
            aiConfidence: processingResult?.confidence,
            extractedText: processingResult?.extractedText,
            aiSummary: processingResult != nil ? "AI categorized" : "Manually categorized",
            status: (processingResult?.confidence ?? 0) > 0.7 ? .pending : .processing,
            taxYear: taxYear,
            taxCategoryType: categoryType?.rawValue,
            attachmentNumber: attachmentNumber,
            currency: "CHF",
            workflowStatus: .pendingReview
        )

        // Save to Firestore
        try await firestoreService.createDocument(document)

        // Add to local array
        allDocuments.insert(document, at: 0)

        print("✅ Document uploaded successfully: \(document.name)")

        // Auto-generate cover sheet in background if user provided
        if let user = user {
            Task(priority: .background) {
                await self.autoGenerateCoverSheet(for: document, user: user)
            }
        }

        return document
    }

    // MARK: - Remap/Recategorize Document

    func remapDocument(
        _ document: TaxDocument,
        to newCategoryType: TaxCategoryType,
        regenerateAttachment: Bool = true,
        user: User? = nil
    ) async throws {
        print("🔄 Remapping document: \(document.name)")
        print("   From: \(document.subcategory ?? "unknown") -> To: \(newCategoryType.rawValue)")

        var updatedDocument = document

        // Update category information
        updatedDocument.category = convertToTaxCategory(newCategoryType)
        updatedDocument.subcategory = newCategoryType.rawValue
        updatedDocument.taxCategoryType = newCategoryType.rawValue

        // Regenerate attachment number if requested
        if regenerateAttachment {
            let newAttachmentNumber = generateAttachmentNumber(
                for: newCategoryType,
                uploadDate: document.uploadedAt
            )
            updatedDocument.attachmentNumber = newAttachmentNumber
            print("📎 New attachment number: \(newAttachmentNumber)")
        }

        // Update workflow status
        updatedDocument.workflowStatus = .classified
        updatedDocument.updatedAt = Date()

        // Save to Firestore
        try await firestoreService.updateDocument(updatedDocument)

        // Update local array
        if let index = allDocuments.firstIndex(where: { $0.id == document.id }) {
            allDocuments[index] = updatedDocument
        }

        print("✅ Document remapped successfully")

        // Auto-regenerate cover sheet in background if user provided
        if let user = user {
            Task(priority: .background) {
                await self.autoGenerateCoverSheet(for: updatedDocument, user: user)

                // Mark package for regeneration after cover sheet is updated
                if let workspaceId = updatedDocument.workspaceId {
                    pdfRegenerationService.markPackageForRegeneration(
                        workspaceId: workspaceId,
                        taxYear: updatedDocument.taxYear
                    )
                    print("📦 Tax package marked for regeneration after remap")
                }
            }
        }
    }

    // MARK: - Update Document Notes

    func updateDocumentNotes(_ document: TaxDocument, notes: String) async throws {
        print("📝 Updating document notes: \(document.name)")

        var updatedDocument = document
        updatedDocument.userNotes = notes.isEmpty ? nil : notes
        updatedDocument.updatedAt = Date()

        // Save to Firestore
        try await firestoreService.updateDocument(updatedDocument)

        // Update local array
        if let index = allDocuments.firstIndex(where: { $0.id == document.id }) {
            allDocuments[index] = updatedDocument
        }

        print("✅ Document notes updated successfully")
    }

    // MARK: - Delete Document

    func deleteDocument(_ document: TaxDocument) async throws {
        print("🗑️ Deleting document: \(document.name)")

        // Delete from Firestore
        try await firestoreService.deleteDocument(documentId: document.id)

        // Delete from Storage
        try await storageService.deleteDocument(storageUrl: document.storageUrl)

        // Remove from local array
        allDocuments.removeAll { $0.id == document.id }

        print("✅ Document deleted successfully")

        // Mark package for regeneration after deletion
        if let workspaceId = document.workspaceId {
            pdfRegenerationService.markPackageForRegeneration(
                workspaceId: workspaceId,
                taxYear: document.taxYear
            )
            print("📦 Tax package marked for regeneration after deletion")
        }
    }

    // MARK: - Helper Methods

    private func generateAttachmentNumber(for categoryType: TaxCategoryType?, uploadDate: Date) -> String {
        let categoryCode = categoryType?.rawValue ?? "uncategorized"
        let shortCode = getShortCode(for: categoryCode)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let timeStamp = dateFormatter.string(from: uploadDate)
        let lastFour = String(timeStamp.suffix(4))

        return "\(shortCode)_\(lastFour)"
    }

    func getShortCode(for category: String) -> String {
        let codeMap: [String: String] = [
            "salary": "SAL",
            "bonus": "BON",
            "freelance": "FRL",
            "investment": "INV",
            "rental": "REN",
            "pension": "PEN",
            "foreignIncome": "FIN",
            "mortgage": "MTG",
            "donations": "DON",
            "education": "EDU",
            "medical": "MED",
            "insurancePremiums": "INS",
            "childcare": "CHI",
            "homeOffice": "HOM",
            "travelExpenses": "TRV",
            "property": "PRO",
            "stocks": "STK",
            "crypto": "CRY",
            "foreignWealth": "FWE",
            "savings": "SAV",
            "insuranceSurrenderValue": "ISV",
            "pillar2": "P2A",
            "pillar3a": "P3A",
            "militaryService": "MIL",
            "taxTreaty": "TAX",
            "other": "OTH",
            "uncategorized": "UNC"
        ]
        return codeMap[category] ?? "DOC"
    }

    private func convertToTaxCategory(_ categoryType: TaxCategoryType?) -> TaxCategory {
        guard let categoryType = categoryType else { return .uncategorized }

        switch categoryType.categoryGroup {
        case .income:
            return .income
        case .deductions:
            return .deduction
        case .assets:
            return .wealth
        case .liabilities:
            return .deduction
        case .swissSpecific:
            switch categoryType {
            case .pillar2, .pillar3a:
                return .pillar
            case .militaryService, .taxTreaty:
                return .foreignIncome
            default:
                return .uncategorized
            }
        }
    }

    private func convertCategoryGroupToStoragePath(_ group: CategoryGroup) -> String {
        switch group {
        case .income: return "income"
        case .deductions: return "deduction"
        case .assets: return "wealth"
        case .liabilities: return "liabilities"
        case .swissSpecific: return "pillar"
        }
    }

    private func extractFileName(from url: String) -> String {
        let components = url.components(separatedBy: "/")
        return components.last?.removingPercentEncoding ?? "document.pdf"
    }

    // MARK: - Automatic Cover Sheet Generation

    /// Auto-generates a cover sheet for a document in the background
    private func autoGenerateCoverSheet(for document: TaxDocument, user: User) async {
        print("🔄 Auto-generating cover sheet for: \(document.name)")

        do {
            let (coverUrl, processedUrl) = try await coverSheetService.processCoverSheet(
                for: document,
                user: user
            )

            print("✅ Auto-generated cover sheet: \(coverUrl)")
            print("✅ Auto-generated processed doc: \(processedUrl)")

            // Update document in local array
            await MainActor.run {
                if let index = allDocuments.firstIndex(where: { $0.id == document.id }) {
                    var updated = allDocuments[index]
                    updated.coverSheetUrl = coverUrl
                    updated.processedDocumentUrl = processedUrl
                    updated.coverSheetGenerated = true
                    updated.workflowStatus = .coverGenerated
                    allDocuments[index] = updated
                }
            }
        } catch {
            print("❌ Auto cover sheet generation failed: \(error)")
        }
    }

    /// Generates cover sheets for all documents that don't have one yet
    func generateAllCoverSheets(for user: User) async {
        print("📋 Generating cover sheets for all documents without one...")

        let documentsNeedingCover = allDocuments.filter { $0.coverSheetUrl == nil }
        print("   Found \(documentsNeedingCover.count) documents needing cover sheets")

        for document in documentsNeedingCover {
            await autoGenerateCoverSheet(for: document, user: user)
            // Small delay to avoid overwhelming the server
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        print("✅ Finished generating all cover sheets")
    }
}
