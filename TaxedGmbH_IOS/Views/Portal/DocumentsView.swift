//
//  DocumentsView.swift
//  TaxedGmbH_IOS
//
//  The client portal, which is one surface: documents.
//
//  Deliberately one screen rather than the five tabs this app used to show over
//  features with no backend. Documents are the reason a client signs in.
//

import SwiftUI
import QuickLook

struct DocumentsView: View {
    let householdId: String

    @EnvironmentObject private var session: PortalSession
    @StateObject private var service = PortalDocumentsService()
    @State private var showUpload = false
    @State private var previewURL: URL?
    @State private var downloadingId: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Section { ErrorBanner(message: errorMessage) }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            ForEach(service.grouped, id: \.category) { group in
                Section(DriveCategory.label(for: group.category)) {
                    ForEach(group.documents) { document in
                        DocumentRow(
                            document: document,
                            isDownloading: downloadingId == document.fileId
                        ) {
                            Task { await open(document) }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if service.isLoading && service.documents.isEmpty {
                ProgressView()
            } else if !service.isLoading && service.documents.isEmpty && errorMessage == nil {
                // A household whose Drive folders do not exist yet is NOT an
                // empty document list. Saying "nothing here yet" to someone
                // whose store has not been built reads as "my documents are
                // gone".
                if session.household?.hasDocumentStore == false {
                    setupState
                } else {
                    emptyState
                }
            }
        }
        .refreshable { await reload() }
        .navigationTitle("documents.title".localized)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showUpload = true
                } label: {
                    Label("documents.upload".localized, systemImage: "plus")
                }
                .disabled(service.categories.isEmpty)
            }
        }
        .sheet(isPresented: $showUpload) {
            UploadSheet(
                householdId: householdId,
                categories: service.categories,
                service: service
            ) {
                Task { await reload() }
            }
        }
        .quickLookPreview($previewURL)
        .task { await reload() }
    }

    private var emptyState: some View {
        MessageScreen(
            systemImage: "tray",
            title: "documents.empty.title".localized,
            message: "documents.empty.message".localized
        ) {
            Button("documents.upload".localized) { showUpload = true }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(service.categories.isEmpty)
        }
    }

    private var setupState: some View {
        MessageScreen(
            systemImage: "shippingbox",
            title: "documents.setup.title".localized,
            message: "documents.setup.message".localized
        ) {
            EmptyView()
        }
    }

    private func reload() async {
        await service.load(householdId: householdId)
        errorMessage = service.error?.localizedDescription
    }

    /// Downloads, then previews. Documents proxy through the API — Drive has no
    /// signed-URL equivalent for private files — so there is no link to open.
    private func open(_ document: PortalDocument) async {
        downloadingId = document.fileId
        errorMessage = nil
        defer { downloadingId = nil }
        do {
            previewURL = try await service.download(document, householdId: householdId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct DocumentRow: View {
    let document: PortalDocument
    let isDownloading: Bool
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: .paddingStandard) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.taxedPrimary)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: .paddingTight)

                if isDownloading {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(document.name)
        .accessibilityHint("documents.open_hint".localized)
    }

    private var subtitle: String {
        var parts = [Format.fileSize(document.size), Format.date(document.indexedAt)]
        // Worth saying: it explains a file the client does not remember sending.
        if document.isFromDrive { parts.append("documents.added_in_drive".localized) }
        return parts.joined(separator: " · ")
    }

    private var icon: String {
        switch document.mimeType {
        case let type? where type.hasPrefix("image/"): return "photo"
        case "application/pdf": return "doc.richtext"
        default: return "doc"
        }
    }
}
