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
    @ObservedObject private var documentManager = DocumentManager.shared
    private let coverSheetService = CoverSheetService.shared

    @State private var isLoadingPDF = false
    @State private var isGeneratingCover = false
    @State private var coverGenerationSuccess = false
    @State private var coverGenerationError: String?
    @State private var showRemapSheet = false
    @State private var showOriginal = false  // Default to showing processed version
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
                // PDF Preview Section - Enhanced with Liquid Glass
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("document_detail.preview".localized)
                            .font(.headline)
                        Spacer()
                    }

                    ZStack(alignment: .topTrailing) {
                        // Main PDF Viewer with Glass Card
                        ZStack {
                            // Always show PDFViewer (don't destroy/recreate it)
                            PDFViewerRepresentable(
                                url: showOriginal ? document.storageUrl : (document.processedDocumentUrl ?? document.storageUrl),
                                isLoading: $isLoadingPDF
                            )
                            .frame(height: 500)  // Increased from 400px to 500px
                            .glassCard(cornerRadius: 24, borderColor: categoryColor.opacity(0.5))

                            // Show loading overlay on top
                            if isLoadingPDF {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("document_detail.loading_pdf".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.ultraThinMaterial)
                                .cornerRadius(24)
                            }
                        }

                        // Floating Action Buttons - Top Right
                        if document.processedDocumentUrl != nil {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showOriginal.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: showOriginal ? "doc.badge.plus" : "doc.text")
                                        .font(.body)
                                        .imageScale(.medium)
                                    Text(showOriginal ? "document_detail.show_cover".localized : "document_detail.show_original".localized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                                .frame(minWidth: 44, minHeight: 44)
                            }
                            .accessibilityLabel(showOriginal ? "document_detail.show_cover".localized : "document_detail.show_original".localized)
                            .accessibilityHint("document_detail.toggle_pdf_view_hint".localized)
                            .accessibilityAddTraits(.isButton)
                            .floatingButton()
                            .padding([.top, .trailing], 16)
                        }
                    }
                }

                // Status Card
                StatusCard(status: document.status)

                // Category Card - Enhanced with Liquid Glass & Glow - TAPPABLE
                Button(action: { showRemapSheet = true }) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Large Category Badge with Status
                        HStack(spacing: 16) {
                            // Large colored icon circle with glow
                            ZStack {
                                Circle()
                                    .fill(categoryColor.opacity(0.15))
                                    .frame(width: 70, height: 70)

                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                categoryColor,
                                                categoryColor.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2.5
                                    )
                                    .frame(width: 70, height: 70)

                                Image(systemName: document.category.icon)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(categoryColor)
                                    .accessibilityHidden(true)
                            }
                            .glow(color: categoryColor, radius: 12)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("document_detail.category".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)

                                Text(document.category.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(categoryColor)

                                if let subcategory = document.subcategory {
                                    HStack(spacing: 6) {
                                        Image(systemName: "tag.fill")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .accessibilityHidden(true)
                                        Text(subcategory.capitalized)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                // Tap to change indicator
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(categoryColor)
                                        .accessibilityHidden(true)
                                    Text("document_detail.tap_to_change".localized)
                                        .font(.caption)
                                        .foregroundColor(categoryColor)
                                }
                                .padding(.top, 4)
                            }

                            Spacer()

                            // Status Badge + Chevron indicator
                            VStack(spacing: 8) {
                                StatusPill(status: document.status)

                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(categoryColor)
                                    .accessibilityHidden(true)
                            }
                        }

                    Divider()
                        .background(categoryColor.opacity(0.2))

                    // Quick Stats Row - 3 Column Grid
                    HStack(spacing: 16) {
                        if let attachmentNum = document.attachmentNumber {
                            QuickStatItem(
                                icon: "paperclip",
                                label: "document_detail.attachment".localized,
                                value: attachmentNum,
                                color: categoryColor
                            )
                        }

                        Divider()
                            .frame(height: 40)

                        QuickStatItem(
                            icon: "calendar",
                            label: "document_detail.tax_year".localized,
                            value: "\(document.taxYear)",
                            color: .blue
                        )

                        if let canton = document.canton {
                            Divider()
                                .frame(height: 40)

                            QuickStatItem(
                                icon: "building.columns",
                                label: "document_detail.canton".localized,
                                value: canton,
                                color: .red
                            )
                        }

                        Spacer()
                    }

                    // Amount Display (if available) with Shimmer
                    if let amount = document.amount {
                        Divider()
                            .background(categoryColor.opacity(0.2))

                        HStack {
                            Image(systemName: "francsign.circle.fill")
                                .font(.title2)
                                .foregroundColor(categoryColor)

                            Text("CHF \(String(format: "%.2f", amount))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(categoryColor)
                                .shimmer(duration: 3.0)
                        }
                    }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(20)
                .glassCard(cornerRadius: 24, borderColor: categoryColor, glowColor: categoryColor)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\("document_detail.category".localized): \(document.category.displayName)\(document.subcategory != nil ? ", \(document.subcategory!)" : "")")
                .accessibilityHint("document_detail.change_category_hint".localized)
                .accessibilityAddTraits(.isButton)

                // AI Summary - Collapsible Glass Card
                if let summary = document.aiSummary {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundColor(.purple)
                                .glow(color: .purple, radius: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI Insights")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if let confidence = document.aiConfidence {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.green)
                                        Text("\(Int(confidence * 100))% Confidence")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            Spacer()
                        }

                        Divider()
                            .background(Color.purple.opacity(0.2))

                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 20, borderColor: .purple, glowColor: .purple.opacity(0.3))
                }

                // Document Info - Glass Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                        Text("document_detail.document_info".localized)
                            .font(.headline)
                        Spacer()
                    }

                    Divider()
                        .background(Color.blue.opacity(0.2))

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
                .padding(16)
                .glassCard(cornerRadius: 20, borderColor: .blue.opacity(0.5))

                // Expert Notes (if available) - Glass Banner
                if let expertNotes = document.expertNotes, !expertNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                                .glow(color: .orange, radius: 8)

                            Text("document_detail.expert_notes".localized)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        Divider()
                            .background(Color.orange.opacity(0.2))

                        Text(expertNotes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 20, borderColor: .orange, glowColor: .orange.opacity(0.3))
                }

                // User Comments Section - Enhanced with Glass
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                            .font(.title3)
                            .foregroundColor(.cyan)
                            .accessibilityHidden(true)
                        Text("document_detail.add_comment".localized)
                            .font(.headline)
                        Spacer()
                        CompactVoiceInputButton(text: $documentNotes)
                            .frame(minWidth: 44, minHeight: 44)
                            .floatingButton()
                    }

                    Divider()
                        .background(Color.cyan.opacity(0.2))

                    // Text Editor for notes
                    TextEditor(text: $documentNotes)
                        .frame(minHeight: 100)  // Increased from 80
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1.5)
                        )
                        .accessibilityLabel("document_detail.notes_field".localized)
                        .accessibilityHint("document_detail.notes_hint".localized)

                    if !documentNotes.isEmpty || notesSaveSuccess {
                        Button(action: {
                            Task {
                                await saveNotes()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isSavingNotes {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                        .tint(.white)
                                    Text("document_detail.saving".localized)
                                } else if notesSaveSuccess {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.body)
                                        .imageScale(.medium)
                                    Text("document_detail.saved".localized)
                                } else {
                                    Image(systemName: "square.and.arrow.down.fill")
                                        .font(.body)
                                        .imageScale(.medium)
                                    Text("document_detail.save_comment".localized)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.vertical, 14)
                            .background(
                                notesSaveSuccess ?
                                LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color(red: 227/255, green: 30/255, blue: 36/255), Color(red: 200/255, green: 20/255, blue: 30/255)], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: (notesSaveSuccess ? .green : Color(red: 227/255, green: 30/255, blue: 36/255)).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isSavingNotes)
                        .accessibilityLabel(notesSaveSuccess ? "document_detail.saved".localized : "document_detail.save_comment".localized)
                        .accessibilityHint("document_detail.save_notes_hint".localized)
                    }
                }
                .padding(16)
                .glassCard(cornerRadius: 20, borderColor: .cyan.opacity(0.5))

                // Cover Sheet Section - Glass Action Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.badge.checkmark.fill")
                            .font(.title3)
                            .foregroundColor(.mint)
                        Text("document_detail.tax_office_submission".localized)
                            .font(.headline)
                        Spacer()
                    }

                    Divider()
                        .background(Color.mint.opacity(0.2))

                    if document.coverSheetGenerated == true {
                        // Show cover sheet info
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                    .glow(color: .green, radius: 6)
                                Text("document_detail.cover_generated".localized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }

                            if let processedUrl = document.processedDocumentUrl {
                                Button(action: {
                                    if let url = URL(string: processedUrl) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.up.right.square.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("document_detail.view_processed".localized)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                    }
                                    .padding(12)
                                    .background(.thinMaterial)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    } else {
                        // Generate cover sheet button
                        Button(action: {
                            Task {
                                await generateCoverSheet()
                            }
                        }) {
                            HStack(spacing: 10) {
                                if isGeneratingCover {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.9)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.body)
                                        .imageScale(.medium)
                                }

                                Text(isGeneratingCover ? "document_detail.generating".localized : "document_detail.generate_cover".localized)
                                    .fontWeight(.semibold)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.body)
                                    .imageScale(.small)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                LinearGradient(
                                    colors: [.mint, .mint.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .mint.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isGeneratingCover)

                        Text("document_detail.generate_cover_desc".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Success/Error messages
                    if coverGenerationSuccess {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("document_detail.cover_success".localized)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }

                    if let error = coverGenerationError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                .glassCard(cornerRadius: 20, borderColor: .mint.opacity(0.5))
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
                        Label("document_detail.remap_category".localized, systemImage: "arrow.triangle.2.circlepath")
                    }

                    Divider()

                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("document_detail.delete_document".localized, systemImage: "trash")
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
        .alert("document_detail.delete_document".localized, isPresented: $showDeleteConfirmation) {
            Button("document_detail.cancel".localized, role: .cancel) { }
            Button("document_detail.delete".localized, role: .destructive) {
                Task {
                    await deleteDocument()
                }
            }
        } message: {
            Text("document_detail.delete_confirmation".localized)
        }
    }

    private func generateCoverSheet() async {
        guard let user = authService.user else {
            coverGenerationError = "document_detail.user_not_found".localized
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
            coverGenerationError = "\("document_detail.cover_error".localized) \(error.localizedDescription)"
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
                .foregroundColor(iconColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("document_detail.status".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(status.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\("document_detail.status".localized): \(status.displayName)")
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

    private var iconColor: Color {
        switch status {
        case .uploading, .processing: return .blue
        case .pending: return .orange
        case .reviewed: return .blue
        case .approved: return .green
        case .rejected: return .red
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
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Status Pill (Compact Badge)
struct StatusPill: View {
    let status: DocumentStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
                .font(.caption)
                .imageScale(.small)
                .accessibilityHidden(true)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.displayName)
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

    private var statusColor: Color {
        switch status {
        case .uploading, .processing: return .blue
        case .pending: return .orange
        case .reviewed: return .cyan
        case .approved: return .green
        case .rejected: return .red
        }
    }
}

// MARK: - Quick Stat Item
struct QuickStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .imageScale(.small)
                    .foregroundColor(color)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
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
