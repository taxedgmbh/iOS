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

    private let firestoreService = FirestoreService.shared
    private let storageService = StorageService.shared
    private let documentProcessor = DocumentProcessorService.shared
    private let coverSheetService = CoverSheetService.shared
    private let pdfRegenerationService = PDFRegenerationService.shared

    // Published state
    @Published var allDocuments: [TaxDocument] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    // Phase 4: Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // Computed properties for different views
    var recentDocuments: [TaxDocument] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allDocuments
            .filter { $0.uploadedAt >= sevenDaysAgo }
            .sorted { $0.uploadedAt > $1.uploadedAt }
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
        Dictionary(grouping: allDocuments.filter { $0.subcategory != nil }) {
            $0.subcategory!
        }
    }

    private init() {
        // Phase 4: Subscribe to profile change events
        setupProfileChangeSubscription()
    }

    // MARK: - Phase 4: Event-Driven Architecture

    /// Subscribe to profile changes from AuthenticationService
    private func setupProfileChangeSubscription() {
        let authService = AuthenticationService()

        authService.profileDidChange
            .sink { [weak self] updatedUser in
                guard let self = self else { return }

                Task { @MainActor in
                    print("📥 Received profile change event for user: \(updatedUser.name)")
                    print("   Profile version: \(updatedUser.profileVersion)")

                    // Trigger automatic PDF regeneration for stale documents
                    await self.pdfRegenerationService.regenerateAllStale(
                        for: updatedUser,
                        priority: .high
                    )
                }
            }
            .store(in: &cancellables)

        print("✅ Profile change subscription established")
    }

    // MARK: - Load Documents

    func loadDocuments(for userId: String) async {
        isLoading = true
        error = nil

        do {
            let documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)
            allDocuments = documents.sorted { $0.uploadedAt > $1.uploadedAt }
            print("✅ Loaded \(documents.count) documents")
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to load documents: \(error)")
        }

        isLoading = false
    }

    // MARK: - Upload Document

    func uploadDocument(
        image: UIImage,
        userId: String,
        categoryType: TaxCategoryType?,
        processingResult: DocumentProcessingResult?,
        taxYear: Int,
        user: User? = nil
    ) async throws -> TaxDocument {
        print("📤 Starting document upload...")

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
            customerId: userId,
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
            name: extractFileName(from: downloadURL),
            storageUrl: downloadURL,
            category: category,
            subcategory: categoryType?.rawValue,
            aiConfidence: processingResult?.confidence,
            extractedText: processingResult?.extractedText,
            aiSummary: processingResult != nil ? "AI categorized" : "Manually categorized",
            status: processingResult != nil && (processingResult!.confidence > 0.7) ? .pending : .processing,
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
            Task.detached(priority: .background) {
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
            Task.detached(priority: .background) {
                await self.autoGenerateCoverSheet(for: updatedDocument, user: user)
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
