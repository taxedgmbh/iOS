//
//  DocumentDetailView.swift
//  TaxedGmbH_IOS
//
//  Detailed view of a tax document showing AI classification results
//

import SwiftUI
import FirebaseStorage
import PDFKit

struct DocumentDetailView: View {
    let document: TaxDocument

    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var documentManager = DocumentManager.shared
    private let coverSheetService = CoverSheetService.shared

    @State private var isLoadingPDF = false
    @State private var isGeneratingCover = false
    @State private var coverGenerationSuccess = false
    @State private var coverGenerationError: String?
    @State private var showRemapSheet = false
    @State private var showCoverSheet = false
    @State private var showDeleteConfirmation = false
    @State private var documentNotes: String = ""
    @State private var isSavingNotes = false
    @State private var notesSaveSuccess = false
    @State private var isDeleting = false
    @Environment(\.dismiss) private var dismiss

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // PDF Preview Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Document Preview")
                            .font(.headline)
                        Spacer()
                        if document.coverSheetUrl != nil {
                            Button(action: { showCoverSheet.toggle() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: showCoverSheet ? "doc.text" : "doc.badge.plus")
                                        .font(.caption)
                                    Text(showCoverSheet ? "Original" : "Cover Sheet")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 400)

                        // Always show PDFViewer (don't destroy/recreate it)
                        PDFViewerRepresentable(
                            url: showCoverSheet && document.coverSheetUrl != nil ? document.coverSheetUrl! : document.storageUrl,
                            isLoading: $isLoadingPDF
                        )
                        .cornerRadius(12)
                        .frame(height: 400)

                        // Show loading overlay on top
                        if isLoadingPDF {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading PDF...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemGray6).opacity(0.9))
                            .cornerRadius(12)
                        }
                    }
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                }

                // Status Card
                StatusCard(status: document.status)

                // Category Card - Prominent Display
                VStack(alignment: .leading, spacing: 16) {
                    // Large Category Badge
                    HStack(spacing: 16) {
                        // Large colored icon circle
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(0.15))
                                .frame(width: 60, height: 60)

                            Circle()
                                .stroke(categoryColor, lineWidth: 2)
                                .frame(width: 60, height: 60)

                            Image(systemName: document.category.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(categoryColor)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("document_detail.category".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)

                            Text(document.category.displayName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(categoryColor)

                            if let subcategory = document.subcategory {
                                Text(subcategory.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }

                    // Attachment Number & Tax Info Row
                    HStack(spacing: 12) {
                        if let attachmentNum = document.attachmentNumber {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Attachment")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                Text(attachmentNum)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(categoryColor)
                                    .cornerRadius(6)
                            }
                        }

                        Divider()
                            .frame(height: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tax Year")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            Text("\(document.taxYear)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        if let canton = document.canton {
                            Divider()
                                .frame(height: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Canton")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                Text(canton)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }

                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: categoryColor.opacity(0.1), radius: 8, x: 0, y: 2)

                // Document Summary
                if let summary = document.aiSummary {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Summary", systemImage: "text.alignleft")
                            .font(.headline)

                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }

                // Amount (if available)
                if let amount = document.amount {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("document_detail.amount".localized, systemImage: "francsign.circle")
                            .font(.headline)

                        Text("CHF \(String(format: "%.2f", amount))")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }

                // Document Info
                VStack(alignment: .leading, spacing: 12) {
                    Label("document_detail.document_info".localized, systemImage: "info.circle")
                        .font(.headline)

                    InfoRow(label: "document_detail.filename".localized, value: document.name)
                    InfoRow(label: "document_detail.tax_year".localized, value: "\(document.taxYear)")

                    if let canton = document.canton {
                        InfoRow(label: "document_detail.canton".localized, value: canton)
                    }

                    InfoRow(
                        label: "document_detail.uploaded".localized,
                        value: document.uploadedAt.formatted(date: .abbreviated, time: .shortened)
                    )

                    if let processedAt = document.processedAt {
                        InfoRow(
                            label: "document_detail.processed".localized,
                            value: processedAt.formatted(date: .abbreviated, time: .shortened)
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)

                // Expert Notes (if available)
                if let expertNotes = document.expertNotes, !expertNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("document_detail.expert_notes".localized, systemImage: "note.text")
                            .font(.headline)

                        Text(expertNotes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }

                // User Comments Section with Voice Input
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Add Comment", systemImage: "text.bubble")
                            .font(.headline)
                        Spacer()
                        CompactVoiceInputButton(text: $documentNotes)
                    }

                    // Text Editor for notes
                    TextEditor(text: $documentNotes)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    if !documentNotes.isEmpty || notesSaveSuccess {
                        Button(action: {
                            Task {
                                await saveNotes()
                            }
                        }) {
                            HStack {
                                if isSavingNotes {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Saving...")
                                } else if notesSaveSuccess {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Saved!")
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Comment")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(notesSaveSuccess ? Color.green : Color(red: 227/255, green: 30/255, blue: 36/255))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isSavingNotes)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)

                // Cover Sheet Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Tax Office Submission", systemImage: "doc.badge.checkmark")
                        .font(.headline)

                    if document.coverSheetGenerated == true {
                        // Show cover sheet info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Cover sheet generated")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            if let coverUrl = document.coverSheetUrl {
                                Button(action: {
                                    if let url = URL(string: coverUrl) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Label("View Cover Sheet", systemImage: "arrow.up.right.square")
                                        .font(.caption)
                                }
                            }

                            if let processedUrl = document.processedDocumentUrl {
                                Button(action: {
                                    if let url = URL(string: processedUrl) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Label("View Processed Document", systemImage: "arrow.up.right.square")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        // Generate cover sheet button
                        Button(action: {
                            Task {
                                await generateCoverSheet()
                            }
                        }) {
                            HStack {
                                if isGeneratingCover {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "doc.badge.plus")
                                }

                                Text(isGeneratingCover ? "Generating..." : "Generate Cover Sheet")
                                    .fontWeight(.semibold)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                        .disabled(isGeneratingCover)

                        Text("Generate a Swiss tax office cover sheet for this document")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Success/Error messages
                    if coverGenerationSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Cover sheet generated successfully!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }

                    if let error = coverGenerationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle("document_detail.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Load existing notes when view appears
            documentNotes = document.userNotes ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showRemapSheet = true }) {
                        Label("Remap Category", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Divider()

                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete Document", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                }
            }
        }
        .sheet(isPresented: $showRemapSheet) {
            RemapDocumentSheet(document: document) {
                showRemapSheet = false
                // Auto-generate cover sheet after remapping
                Task {
                    await autoGenerateCoverSheet()
                }
            }
        }
        .alert("Delete Document", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteDocument()
                }
            }
        } message: {
            Text("Are you sure you want to delete this document? This action cannot be undone.")
        }
    }

    private func generateCoverSheet() async {
        guard let user = authService.user else {
            coverGenerationError = "User not found"
            return
        }

        isGeneratingCover = true
        coverGenerationError = nil
        coverGenerationSuccess = false

        do {
            let (coverUrl, processedUrl) = try await coverSheetService.processCoverSheet(
                for: document,
                user: user
            )

            print("✅ Cover sheet generated: \(coverUrl)")
            print("✅ Processed document: \(processedUrl)")

            coverGenerationSuccess = true

            // Auto-hide success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                coverGenerationSuccess = false
            }
        } catch {
            print("❌ Cover sheet generation failed: \(error)")
            coverGenerationError = "Failed to generate cover sheet: \(error.localizedDescription)"
        }

        isGeneratingCover = false
    }

    private func autoGenerateCoverSheet() async {
        guard let user = authService.user else { return }

        print("🔄 Auto-generating cover sheet after document change...")

        do {
            let (coverUrl, processedUrl) = try await coverSheetService.processCoverSheet(
                for: document,
                user: user
            )

            print("✅ Auto-generated cover sheet: \(coverUrl)")
            print("✅ Auto-generated processed document: \(processedUrl)")

            await MainActor.run {
                coverGenerationSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    coverGenerationSuccess = false
                }
            }
        } catch {
            print("❌ Auto cover sheet generation failed: \(error)")
        }
    }

    private func saveNotes() async {
        isSavingNotes = true
        notesSaveSuccess = false

        do {
            try await documentManager.updateDocumentNotes(document, notes: documentNotes)

            await MainActor.run {
                isSavingNotes = false
                notesSaveSuccess = true

                // Hide success message after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    notesSaveSuccess = false
                }
            }
        } catch {
            print("❌ Failed to save notes: \(error)")
            await MainActor.run {
                isSavingNotes = false
            }
        }
    }

    private func deleteDocument() async {
        isDeleting = true

        do {
            print("🗑️ Deleting document: \(document.name)")
            try await documentManager.deleteDocument(document)

            print("✅ Document deleted successfully")

            // Navigate back immediately after successful deletion
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ Failed to delete document: \(error)")
            // Show error to user (could add an error state here)
            await MainActor.run {
                isDeleting = false
            }
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let status: DocumentStatus

    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("document_detail.status".localized)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(status.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }

    private var statusIcon: String {
        switch status {
        case .uploading, .processing: return "arrow.clockwise.circle.fill"
        case .pending: return "clock.fill"
        case .reviewed: return "eye.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .uploading, .processing: return Color.blue.opacity(0.15)
        case .pending: return Color.orange.opacity(0.15)
        case .reviewed: return Color.blue.opacity(0.15)
        case .approved: return Color.green.opacity(0.15)
        case .rejected: return Color.red.opacity(0.15)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationView {
        DocumentDetailView(
            document: TaxDocument(
                customerId: "user123",
                name: "Lohnausweis_2024.pdf",
                storageUrl: "https://example.com/doc.pdf",
                category: .income,
                subcategory: "salary",
                aiConfidence: 0.95,
                aiSummary: "Lohnausweis für 2024, Bruttoeinkommen CHF 85,000",
                status: .reviewed,
                taxYear: 2024,
                amount: 85000.00
            )
        )
    }
}
