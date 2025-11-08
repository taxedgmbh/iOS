//
//  AllDocumentsView.swift
//  TaxedGmbH_IOS
//
//  Unified document view with Apple HIG-compliant design
//

import SwiftUI
import FirebaseStorage

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

    @State private var selectedFilter: DocumentFilter = .all
    @State private var searchText = ""
    @State private var showUploadSheet = false
    @State private var showSortMenu = false

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
            .onAppear {
                loadDocuments()
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
        guard let userId = authService.user?.id else { return }

        // Load workspace documents if workspace exists, otherwise fall back to user documents
        Task {
            do {
                try await workspaceManager.loadUserWorkspaces(for: userId)

                if let workspaceId = workspaceManager.activeWorkspace?.id {
                    await documentManager.loadDocuments(forWorkspace: workspaceId)
                } else {
                    // Fallback to loading all user documents (legacy mode)
                    await documentManager.loadDocuments(for: userId)
                }
            } catch {
                print("❌ Error loading workspaces: \(error)")
                // Fallback to user documents on error
                await documentManager.loadDocuments(for: userId)
            }
        }
    }

    private func refresh() {
        loadDocuments()
    }

    private func refreshAsync() async {
        guard let userId = authService.user?.id else { return }

        // Load workspace documents if workspace exists, otherwise fall back to user documents
        do {
            try await workspaceManager.loadUserWorkspaces(for: userId)

            if let workspaceId = workspaceManager.activeWorkspace?.id {
                await documentManager.loadDocuments(forWorkspace: workspaceId)
            } else {
                // Fallback to loading all user documents (legacy mode)
                await documentManager.loadDocuments(for: userId)
            }
        } catch {
            print("❌ Error loading workspaces: \(error)")
            // Fallback to user documents on error
            await documentManager.loadDocuments(for: userId)
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
                Text(document.name)
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

#Preview {
    AllDocumentsView()
        .environmentObject(AuthenticationService())
}
