//
//  DocumentDetailView.swift
//  TaxedGmbH_IOS
//
//  Detailed view of a tax document showing AI classification results
//

import SwiftUI
import FirebaseStorage

struct DocumentDetailView: View {
    let document: TaxDocument

    @EnvironmentObject var authService: AuthenticationService
    private let coverSheetService = CoverSheetService.shared

    @State private var imageData: Data?
    @State private var isLoadingImage = false
    @State private var isGeneratingCover = false
    @State private var coverGenerationSuccess = false
    @State private var coverGenerationError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Document Image
                if isLoadingImage {
                    ProgressView("document_detail.loading_image".localized)
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                } else if let data = imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("document_detail.image_unavailable".localized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }

                // Status Card
                StatusCard(status: document.status)

                // Classification Card
                VStack(alignment: .leading, spacing: 12) {
                    Label("document_detail.ai_classification".localized, systemImage: "brain.head.profile")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("document_detail.category".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Image(systemName: document.category.icon)
                                Text(document.category.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }

                        Spacer()

                        if let confidence = document.aiConfidence {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("document_detail.confidence".localized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(Int(confidence * 100))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(confidence > 0.8 ? .green : .orange)
                            }
                        }
                    }

                    if let subcategory = document.subcategory {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("document_detail.subcategory".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(subcategory.capitalized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)

                // AI Summary
                if let summary = document.aiSummary {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("document_detail.summary".localized, systemImage: "text.alignleft")
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
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        isLoadingImage = true
        defer { isLoadingImage = false }

        do {
            let storageRef = Storage.storage().reference(forURL: document.storageUrl)
            let maxSize: Int64 = 10 * 1024 * 1024 // 10MB
            let data = try await storageRef.data(maxSize: maxSize)
            imageData = data
        } catch {
            print("❌ Error loading image: \(error)")
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
