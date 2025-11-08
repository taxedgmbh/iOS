//
//  PDFRegenerationService.swift
//  TaxedGmbH_IOS
//
//  Phase 3: Queue-based PDF regeneration service
//

import Foundation
import Combine

/// Priority levels for PDF regeneration tasks
enum RegenerationPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3

    static func < (lhs: RegenerationPriority, rhs: RegenerationPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Represents a queued regeneration task
struct RegenerationTask: Identifiable {
    let id: String  // documentId
    let document: TaxDocument
    let user: User
    let priority: RegenerationPriority
    let queuedAt: Date

    init(document: TaxDocument, user: User, priority: RegenerationPriority = .normal) {
        self.id = document.id
        self.document = document
        self.user = user
        self.priority = priority
        self.queuedAt = Date()
    }
}

/// Result of a regeneration operation
struct RegenerationResult {
    let documentId: String
    let success: Bool
    let error: Error?
    let coverSheetUrl: String?
    let processedDocumentUrl: String?
}

@MainActor
class PDFRegenerationService: ObservableObject {
    static let shared = PDFRegenerationService()

    // Dependencies - lazy to avoid circular initialization with DocumentManager
    private lazy var firestoreService = FirestoreService.shared
    private lazy var coverSheetService = CoverSheetService.shared
    private lazy var documentManager = DocumentManager.shared

    // Published state
    @Published var isProcessing: Bool = false
    @Published var currentTask: RegenerationTask?
    @Published var queuedTasks: [RegenerationTask] = []
    @Published var completedCount: Int = 0
    @Published var failedCount: Int = 0

    // Package regeneration state
    @Published var isRegeneratingPackage: Bool = false
    @Published var packageRegenerationNeeded: [String: Set<Int>] = [:] // workspaceId: Set<taxYear>

    // Private queue (sorted by priority, then by queued time)
    private var queue: [RegenerationTask] = []
    private var isRunning: Bool = false
    private var packageRegenerationTimer: Timer?

    private init() {
        // Schedule periodic package regeneration check (every 10 seconds)
        setupPackageRegenerationTimer()
    }

    // MARK: - Public API

    /// Detect all documents that need regeneration for a user
    func detectStaleDocuments(for user: User) async -> [TaxDocument] {
        print("🔍 Detecting stale documents for user version \(user.profileVersion)")

        guard let userId = user.id else {
            print("❌ No user ID provided")
            return []
        }

        do {
            let documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)

            let staleDocuments = documents.filter { document in
                // Document needs regeneration if:
                // 1. It has a cover sheet URL (was generated before)
                // 2. Profile version mismatch OR needsRegeneration flag set
                if document.coverSheetUrl != nil {
                    if let generatedVersion = document.generatedWithProfileVersion {
                        return generatedVersion != user.profileVersion || document.needsRegeneration == true
                    } else {
                        // No version recorded - assume stale
                        return true
                    }
                }
                return false
            }

            print("✅ Found \(staleDocuments.count) stale documents out of \(documents.count) total")
            return staleDocuments
        } catch {
            print("❌ Error detecting stale documents: \(error)")
            return []
        }
    }

    /// Queue a single document for regeneration
    func queueRegeneration(document: TaxDocument, user: User, priority: RegenerationPriority = .normal) {
        let task = RegenerationTask(document: document, user: user, priority: priority)

        // Avoid duplicate entries
        if queue.contains(where: { $0.id == task.id }) {
            print("⚠️ Document \(document.name) already queued")
            return
        }

        queue.append(task)
        queue.sort { task1, task2 in
            if task1.priority != task2.priority {
                return task1.priority > task2.priority  // Higher priority first
            }
            return task1.queuedAt < task2.queuedAt  // Earlier tasks first
        }

        queuedTasks = queue
        print("📥 Queued document \(document.name) with priority \(priority)")

        // Start processing if not already running
        if !isRunning {
            Task {
                await processQueue()
            }
        }
    }

    /// Queue multiple documents for batch regeneration
    func queueBatchRegeneration(documents: [TaxDocument], user: User, priority: RegenerationPriority = .normal) {
        print("📋 Queueing batch of \(documents.count) documents")

        for document in documents {
            queueRegeneration(document: document, user: user, priority: priority)
        }
    }

    /// Regenerate all stale documents for a user
    func regenerateAllStale(for user: User, priority: RegenerationPriority = .normal) async {
        let staleDocuments = await detectStaleDocuments(for: user)

        if staleDocuments.isEmpty {
            print("✅ No stale documents to regenerate")
            return
        }

        print("🔄 Starting batch regeneration of \(staleDocuments.count) documents")
        queueBatchRegeneration(documents: staleDocuments, user: user, priority: priority)
    }

    /// Cancel all queued tasks
    func cancelAll() {
        queue.removeAll()
        queuedTasks = []
        print("❌ Cancelled all queued regeneration tasks")
    }

    /// Get current queue status
    func getQueueStatus() -> (total: Int, pending: Int, processing: Bool) {
        return (
            total: completedCount + failedCount + queue.count,
            pending: queue.count,
            processing: isRunning
        )
    }

    // MARK: - Private Processing

    private func processQueue() async {
        guard !isRunning else {
            print("⚠️ Queue processor already running")
            return
        }

        isRunning = true
        isProcessing = true

        print("🚀 Starting queue processor")

        while !queue.isEmpty {
            let task = queue.removeFirst()
            queuedTasks = queue
            currentTask = task

            print("⚙️ Processing: \(task.document.name) [Priority: \(task.priority)]")

            let result = await regenerateDocument(task: task)

            if result.success {
                completedCount += 1
                print("✅ Completed: \(task.document.name)")
            } else {
                failedCount += 1
                print("❌ Failed: \(task.document.name) - \(result.error?.localizedDescription ?? "Unknown error")")
            }

            // Small delay between tasks to avoid overwhelming the system
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        currentTask = nil
        isRunning = false
        isProcessing = false

        print("🏁 Queue processor finished. Completed: \(completedCount), Failed: \(failedCount)")
    }

    private func regenerateDocument(task: RegenerationTask) async -> RegenerationResult {
        var updatedDocument = task.document

        do {
            // Update status to generating
            updatedDocument.pdfGenerationStatus = .generating
            updatedDocument.needsRegeneration = false
            try await firestoreService.updateDocument(updatedDocument)

            // Generate new cover sheet with updated profile
            let (coverUrl, processedUrl) = try await coverSheetService.processCoverSheet(
                for: task.document,
                user: task.user
            )

            // Update document with new URLs and profile version
            updatedDocument.coverSheetUrl = coverUrl
            updatedDocument.processedDocumentUrl = processedUrl
            updatedDocument.pdfGenerationStatus = .completed
            updatedDocument.pdfLastGeneratedAt = Date()
            updatedDocument.generatedWithProfileVersion = task.user.profileVersion
            updatedDocument.coverSheetGenerated = true
            updatedDocument.workflowStatus = .coverGenerated
            updatedDocument.updatedAt = Date()

            try await firestoreService.updateDocument(updatedDocument)

            // Update local DocumentManager state
            await updateLocalDocument(updatedDocument)

            return RegenerationResult(
                documentId: task.document.id,
                success: true,
                error: nil,
                coverSheetUrl: coverUrl,
                processedDocumentUrl: processedUrl
            )

        } catch {
            // Mark as failed
            updatedDocument.pdfGenerationStatus = .failed
            updatedDocument.needsRegeneration = true
            try? await firestoreService.updateDocument(updatedDocument)

            return RegenerationResult(
                documentId: task.document.id,
                success: false,
                error: error,
                coverSheetUrl: nil,
                processedDocumentUrl: nil
            )
        }
    }

    private func updateLocalDocument(_ document: TaxDocument) async {
        // Update DocumentManager's local array
        if let index = documentManager.allDocuments.firstIndex(where: { $0.id == document.id }) {
            documentManager.allDocuments[index] = document
        }
    }

    // MARK: - Batch Operations

    /// Mark all documents for a user as needing regeneration
    func markAllForRegeneration(userId: String) async throws {
        print("🔄 Marking all documents for user \(userId) as needing regeneration")

        let documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)
        let documentsWithCovers = documents.filter { $0.coverSheetUrl != nil }

        print("   Found \(documentsWithCovers.count) documents with cover sheets")

        for var document in documentsWithCovers {
            document.needsRegeneration = true
            document.updatedAt = Date()
            try await firestoreService.updateDocument(document)
        }

        print("✅ Marked \(documentsWithCovers.count) documents for regeneration")
    }

    // MARK: - Tax Package Regeneration

    /// Mark a workspace/tax year combination for package regeneration
    func markPackageForRegeneration(workspaceId: String, taxYear: Int) {
        if packageRegenerationNeeded[workspaceId] == nil {
            packageRegenerationNeeded[workspaceId] = Set<Int>()
        }
        packageRegenerationNeeded[workspaceId]?.insert(taxYear)
        print("📦 Marked package for regeneration: workspace=\(workspaceId), year=\(taxYear)")
    }

    /// Setup timer for periodic package regeneration
    private func setupPackageRegenerationTimer() {
        packageRegenerationTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.processPackageRegenerations()
            }
        }
    }

    /// Process all pending package regenerations
    private func processPackageRegenerations() async {
        guard !isRegeneratingPackage else {
            print("⚠️ Package regeneration already in progress")
            return
        }

        guard !packageRegenerationNeeded.isEmpty else {
            return
        }

        isRegeneratingPackage = true

        // Process each workspace/year combination
        for (workspaceId, taxYears) in packageRegenerationNeeded {
            for taxYear in taxYears {
                do {
                    // Get workspace and user info
                    guard let workspace = try? await WorkspaceManager.shared.getWorkspace(workspaceId: workspaceId),
                          let userId = workspace.ownerId else {
                        print("❌ Cannot regenerate package: workspace or owner not found")
                        continue
                    }

                    guard let user = try? await firestoreService.getUserProfile(userId: userId) else {
                        print("❌ Cannot regenerate package: user not found")
                        continue
                    }

                    // Get all documents for this workspace/year
                    let allDocuments = try await firestoreService.getDocumentsForWorkspace(workspaceId: workspaceId)
                    let yearDocuments = allDocuments.filter { $0.taxYear == taxYear }

                    guard !yearDocuments.isEmpty else {
                        print("⚠️ No documents found for workspace \(workspaceId), year \(taxYear)")
                        continue
                    }

                    print("📦 Regenerating package: \(yearDocuments.count) documents for \(taxYear)")

                    // Generate the package
                    let packageURL = try await coverSheetService.generateTaxSubmissionPackage(
                        for: yearDocuments,
                        user: user,
                        workspaceId: workspaceId,
                        taxYear: taxYear
                    )

                    print("✅ Package regenerated successfully: \(packageURL.path)")

                    // TODO: Store package metadata in Firestore (optional)
                    // This could track package version, generation time, etc.

                } catch {
                    print("❌ Package regeneration failed for workspace \(workspaceId), year \(taxYear): \(error)")
                }
            }
        }

        // Clear completed regenerations
        packageRegenerationNeeded.removeAll()
        isRegeneratingPackage = false
        print("🏁 Package regeneration batch completed")
    }

    /// Regenerate package immediately (bypasses timer)
    func regeneratePackageNow(workspaceId: String, taxYear: Int) async {
        print("📦 Immediate package regeneration requested")
        markPackageForRegeneration(workspaceId: workspaceId, taxYear: taxYear)
        await processPackageRegenerations()
    }
}
