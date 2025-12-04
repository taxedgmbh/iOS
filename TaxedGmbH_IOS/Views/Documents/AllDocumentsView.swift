//
//  AllDocumentsView.swift
//  TaxedGmbH_IOS
//
//  Unified document view with Apple HIG-compliant design
//

import SwiftUI
import FirebaseStorage
import PDFKit

enum DocumentFilter: String, CaseIterable {
    case all = "All"
    case recent = "Recent"
    case pending = "Pending Review"
    case byCategory = "By Category"

    var icon: String {
        switch self {
        case .all: return "doc.on.doc.fill"
        case .recent: return "clock.fill"
        case .pending: return "exclamationmark.circle.fill"
        case .byCategory: return "folder.fill"
        }
    }

    var localized: String {
        switch self {
        case .all: return "All Documents"
        case .recent: return "Recent"
        case .pending: return "Pending"
        case .byCategory: return "By Category"
        }
    }
}

struct AllDocumentsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var documentManager = DocumentManager.shared
    @ObservedObject private var workspaceManager = WorkspaceManager.shared
    @ObservedObject private var pdfRegenerationService = PDFRegenerationService.shared

    @State private var selectedFilter: DocumentFilter = .all
    @State private var searchText = ""
    @State private var showUploadSheet = false
    @State private var showSortMenu = false
    @State private var packageURL: String?
    @State private var taxYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showPackagePreview = false
    @State private var packagePDFDocument: PDFDocument?
    @State private var isLoadingPackage = false

    var filteredDocuments: [TaxDocument] {
        var documents: [TaxDocument]

        switch selectedFilter {
        case .all:
            documents = documentManager.allDocuments
        case .recent:
            documents = documentManager.recentDocuments
        case .pending:
            documents = documentManager.pendingReviewDocuments
        case .byCategory:
            documents = documentManager.allDocuments
        }

        // Apply search filter
        if !searchText.isEmpty {
            documents = documents.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.category.displayName.lowercased().contains(searchText.lowercased()) ||
                ($0.subcategory?.lowercased().contains(searchText.lowercased()) ?? false) ||
                ($0.attachmentNumber?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }

        return documents
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                    // Tax Package Banner
                    if let packageURL = packageURL {
                        TaxPackageBanner(
                            taxYear: taxYear,
                            documentCount: filteredDocuments.count,
                            isRegenerating: pdfRegenerationService.isRegeneratingPackage,
                            isLoading: isLoadingPackage,
                            onPreview: { previewPackage(url: packageURL) }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }

                    // Enhanced Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(DocumentFilter.allCases, id: \.self) { filter in
                                EnhancedFilterPill(
                                    filter: filter,
                                    isSelected: selectedFilter == filter,
                                    count: countForFilter(filter)
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    .background(Color(.systemBackground))

                    // Search Bar
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.body)

                            TextField("Search documents...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        Button(action: { showSortMenu.toggle() }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .background(Color(.systemBackground))

                    // Document List
                    if documentManager.isLoading {
                        VStack(spacing: 16) {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading documents...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else if filteredDocuments.isEmpty {
                        EnhancedEmptyState(
                            filter: selectedFilter,
                            hasSearch: !searchText.isEmpty,
                            onUpload: { showUploadSheet = true }
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredDocuments) { document in
                                    NavigationLink(destination: DocumentDetailView(document: document)) {
                                        EnhancedDocumentCard(document: document)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showUploadSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { refresh() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showUploadSheet) {
                DocumentUploadView()
            }
            .sheet(isPresented: $showPackagePreview) {
                if let pdfDocument = packagePDFDocument {
                    TaxPackagePreviewView(
                        pdfDocument: pdfDocument,
                        taxYear: taxYear,
                        documentCount: filteredDocuments.count
                    )
                }
            }
            .onAppear {
                loadDocuments()
                loadPackageURL()
            }
            .refreshable {
                await refreshAsync()
            }
    }

    // MARK: - Helper Methods

    private func countForFilter(_ filter: DocumentFilter) -> Int {
        switch filter {
        case .all:
            return documentManager.allDocuments.count
        case .recent:
            return documentManager.recentDocuments.count
        case .pending:
            return documentManager.pendingReviewDocuments.count
        case .byCategory:
            return documentManager.documentsByCategory.keys.count
        }
    }

    private func loadDocuments() {
        guard let userId = authService.user?.id else {
            print("❌ No user ID available for loading documents")
            return
        }

        print("📄 Loading documents for user: \(userId)")

        Task {
            // Try workspace-based loading with timeout
            do {
                // Add timeout for workspace loading
                try await withTimeout(seconds: 5) {
                    try await workspaceManager.loadUserWorkspaces(for: userId)
                }

                if let workspaceId = workspaceManager.activeWorkspace?.id {
                    print("✅ Using workspace: \(workspaceId)")
                    await documentManager.loadDocuments(forWorkspace: workspaceId)
                } else {
                    print("⚠️ No active workspace, loading user documents directly")
                    await documentManager.loadDocuments(for: userId)
                }
            } catch {
                print("❌ Workspace loading failed or timed out: \(error.localizedDescription)")
                // Always fallback to user documents on any error
                await documentManager.loadDocuments(for: userId)
            }
        }
    }

    /// Execute an async task with a timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the actual operation
            group.addTask {
                try await operation()
            }

            // Add a timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            // Return the first one to complete
            let result = try await group.next()!

            // Cancel the other task
            group.cancelAll()

            return result
        }
    }

    private struct TimeoutError: Error {
        var localizedDescription: String {
            return "Operation timed out"
        }
    }

    private func refresh() {
        loadDocuments()
    }

    private func refreshAsync() async {
        guard let userId = authService.user?.id else {
            print("❌ No user ID available for refresh")
            return
        }

        print("🔄 Refreshing documents for user: \(userId)")

        // Try workspace-based loading with timeout
        do {
            try await withTimeout(seconds: 5) {
                try await workspaceManager.loadUserWorkspaces(for: userId)
            }

            if let workspaceId = workspaceManager.activeWorkspace?.id {
                print("✅ Refreshing workspace: \(workspaceId)")
                await documentManager.loadDocuments(forWorkspace: workspaceId)
            } else {
                print("⚠️ No active workspace, refreshing user documents directly")
                await documentManager.loadDocuments(for: userId)
            }
        } catch {
            print("❌ Workspace refresh failed or timed out: \(error.localizedDescription)")
            // Always fallback to user documents on any error
            await documentManager.loadDocuments(for: userId)
        }
    }

    private func loadPackageURL() {
        guard let workspaceId = workspaceManager.activeWorkspace?.id else { return }

        Task {
            packageURL = await pdfRegenerationService.getPackageURL(
                workspaceId: workspaceId,
                taxYear: taxYear
            )
        }
    }

    private func previewPackage(url: String) {
        guard let packageURL = URL(string: url) else {
            print("❌ Invalid package URL")
            return
        }

        isLoadingPackage = true

        Task {
            do {
                // Download PDF temporarily
                let (tempURL, _) = try await URLSession.shared.download(from: packageURL)

                // Load PDF document
                if let pdfDocument = PDFDocument(url: tempURL) {
                    await MainActor.run {
                        packagePDFDocument = pdfDocument
                        isLoadingPackage = false
                        showPackagePreview = true
                    }
                    print("✅ Package loaded for preview: \(pdfDocument.pageCount) pages")
                } else {
                    await MainActor.run {
                        isLoadingPackage = false
                    }
                    print("❌ Failed to create PDF document")
                }
            } catch {
                await MainActor.run {
                    isLoadingPackage = false
                }
                print("❌ Failed to download package for preview: \(error)")
            }
        }
    }
}

// MARK: - Enhanced Filter Pill

struct EnhancedFilterPill: View {
    let filter: DocumentFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.caption)

                Text(filter.localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : Color(red: 227/255, green: 30/255, blue: 36/255))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ?
                                Color.white.opacity(0.3) :
                                Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.15)
                        )
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        Color(red: 227/255, green: 30/255, blue: 36/255)
                    } else {
                        Color(.systemGray6)
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
            .shadow(color: isSelected ? Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Enhanced Document Card

struct EnhancedDocumentCard: View {
    let document: TaxDocument

    @State private var thumbnailImage: UIImage?
    @State private var isLoadingThumbnail = false

    var body: some View {
        HStack(spacing: 16) {
            // PDF Thumbnail or Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 70, height: 70)

                if let thumbnail = thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                        )
                } else if isLoadingThumbnail {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: document.category.icon)
                        .font(.title2)
                        .foregroundColor(categoryColor)
                }
            }

            // Document Info
            VStack(alignment: .leading, spacing: 6) {
                Text(cleanDocumentName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let attachmentNum = document.attachmentNumber {
                        Text(attachmentNum)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(categoryColor)
                            .cornerRadius(6)
                    }

                    Text(document.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let subcategory = document.subcategory {
                    Text(subcategory.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }

                // Workflow Status Badge
                if let workflowStatus = document.workflowStatus {
                    HStack(spacing: 4) {
                        Image(systemName: workflowStatus.icon)
                            .font(.caption2)
                        Text(workflowStatus.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(colorForWorkflowStatus(workflowStatus))
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .task {
            await loadThumbnail()
        }
    }

    private var categoryColor: Color {
        switch document.category {
        case .income: return .green
        case .deduction: return .blue
        case .pillar: return .purple
        case .wealth: return .orange
        case .foreignIncome, .foreignPension, .foreignWealth, .taxTreaty, .foreignTax:
            return .teal
        case .uncategorized: return .gray
        }
    }

    private func colorForWorkflowStatus(_ status: DocumentWorkflowStatus) -> Color {
        switch status {
        case .uploading, .processing: return .gray
        case .pendingClassification: return .orange
        case .classified: return .blue
        case .pendingReview: return .yellow
        case .reviewed: return .cyan
        case .approved: return .green
        case .coverGenerated: return .purple
        case .finalized: return .indigo
        case .submitted: return .mint
        case .rejected: return .red
        }
    }

    private var cleanDocumentName: String {
        // Extract clean filename from storage URL or use document name
        // Remove storage paths like "workspaces/xxx/" and URL encoding
        let name = document.name

        // If it contains slashes, extract just the filename
        if name.contains("/") {
            let components = name.components(separatedBy: "/")
            if let filename = components.last {
                // Remove URL encoding and clean up
                return filename
                    .removingPercentEncoding?
                    .replacingOccurrences(of: "_", with: " ")
                    .replacingOccurrences(of: ".pdf", with: "")
                    .capitalized ?? name
            }
        }

        // Otherwise return name as-is, cleaned up
        return name
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: ".pdf", with: "")
    }

    private func loadThumbnail() async {
        isLoadingThumbnail = true
        defer { isLoadingThumbnail = false }

        if let thumbnail = await PDFThumbnailGenerator.generateThumbnail(from: document.storageUrl) {
            await MainActor.run {
                thumbnailImage = thumbnail
            }
        }
    }
}

// MARK: - Enhanced Empty State

struct EnhancedEmptyState: View {
    let filter: DocumentFilter
    let hasSearch: Bool
    let onUpload: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated Icon
            ZStack {
                Circle()
                    .fill(Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: emptyIcon)
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
            }

            VStack(spacing: 12) {
                Text(emptyMessage)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(emptyDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if !hasSearch && filter == .all {
                Button(action: onUpload) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                        Text("Upload First Document")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color(red: 227/255, green: 30/255, blue: 36/255))
                    .cornerRadius(12)
                    .shadow(color: Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
    }

    private var emptyIcon: String {
        if hasSearch {
            return "magnifyingglass"
        }
        switch filter {
        case .all: return "doc.text"
        case .recent: return "clock"
        case .pending: return "checkmark.circle"
        case .byCategory: return "folder"
        }
    }

    private var emptyMessage: String {
        if hasSearch {
            return "No Results Found"
        }
        switch filter {
        case .all: return "No Documents Yet"
        case .recent: return "No Recent Documents"
        case .pending: return "All Caught Up!"
        case .byCategory: return "No Categorized Documents"
        }
    }

    private var emptyDescription: String {
        if hasSearch {
            return "Try adjusting your search terms or filters"
        }
        switch filter {
        case .all: return "Upload your first document to get started with your tax filing journey"
        case .recent: return "Documents uploaded or updated in the last 30 days will appear here"
        case .pending: return "All your documents have been reviewed. Great work!"
        case .byCategory: return "Categorize your documents to see them organized here"
        }
    }
}

// MARK: - Tax Package Banner

struct TaxPackageBanner: View {
    let taxYear: Int
    let documentCount: Int
    let isRegenerating: Bool
    let isLoading: Bool
    let onPreview: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Package Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.12))
                        .frame(width: 56, height: 56)

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 227/255, green: 30/255, blue: 36/255)))
                    } else {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                    }
                }

                // Package Info
                VStack(alignment: .leading, spacing: 5) {
                    Text("Tax Submission Package \(String(taxYear))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Image(systemName: isRegenerating ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isRegenerating ? .orange : .green)

                        Text(isRegenerating ? "Updating..." : "\(documentCount) document\(documentCount == 1 ? "" : "s") ready")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(16)

            // Divider
            Divider()
                .padding(.horizontal, 16)

            // Action Button
            Button(action: onPreview) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 227/255, green: 30/255, blue: 36/255)))
                        Text("Loading...")
                            .font(.system(size: 15, weight: .semibold))
                    } else {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                        Text("View Package")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Spacer()
                }
                .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                .padding(.vertical, 14)
            }
            .disabled(isRegenerating || isLoading)
            .opacity((isRegenerating || isLoading) ? 0.5 : 1.0)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Tax Package Preview View

struct TaxPackagePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let pdfDocument: PDFDocument
    let taxYear: Int
    let documentCount: Int

    @State private var currentPage: Int = 0
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Package Info Header
                VStack(spacing: 8) {
                    Text("Tax Submission Package \(String(taxYear))")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        Label("\(documentCount) documents", systemImage: "doc.on.doc")
                        Label("\(pdfDocument.pageCount) pages", systemImage: "doc.text")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))

                Divider()

                // PDF Viewer
                PDFKitView(document: pdfDocument, currentPage: $currentPage)

                // Page Navigation
                HStack(spacing: 20) {
                    Button(action: previousPage) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(currentPage == 0)
                    .opacity(currentPage == 0 ? 0.3 : 1.0)

                    Text("Page \(currentPage + 1) of \(pdfDocument.pageCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 120)

                    Button(action: nextPage) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(currentPage >= pdfDocument.pageCount - 1)
                    .opacity(currentPage >= pdfDocument.pageCount - 1 ? 0.3 : 1.0)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = pdfDocument.dataRepresentation() {
                    ShareSheet(items: [data])
                }
            }
        }
    }

    private func nextPage() {
        if currentPage < pdfDocument.pageCount - 1 {
            currentPage += 1
        }
    }

    private func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
}

// MARK: - PDFKit View

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemGroupedBackground

        // Set up notification for page changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let page = document.page(at: currentPage), pdfView.currentPage != page {
            pdfView.go(to: page)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage)
    }

    class Coordinator: NSObject {
        @Binding var currentPage: Int

        init(currentPage: Binding<Int>) {
            _currentPage = currentPage
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let page = pdfView.currentPage,
                  let document = pdfView.document else {
                return
            }
            let pageIndex = document.index(for: page)
            currentPage = pageIndex
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    AllDocumentsView()
        .environmentObject(AuthenticationService())
}
