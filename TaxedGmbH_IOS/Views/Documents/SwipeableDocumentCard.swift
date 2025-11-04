//
//  SwipeableDocumentCard.swift
//  TaxedGmbH_IOS
//
//  Tinder-style swipeable card for document review
//

import SwiftUI

struct SwipeableDocumentCard: View {
    let document: TaxDocument
    let offset: CGSize
    let rotation: Double

    @State private var showConfidenceExplanation = false

    var body: some View {
        ZStack {
            // Card background with document preview
            VStack(spacing: 0) {
                // Document thumbnail or placeholder
                ZStack {
                    if let thumbnailUrl = document.thumbnailUrl, !thumbnailUrl.isEmpty {
                        AsyncImage(url: URL(string: thumbnailUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure, .empty:
                                documentPlaceholder
                            @unknown default:
                                documentPlaceholder
                            }
                        }
                    } else {
                        documentPlaceholder
                    }
                }
                .frame(height: 300)
                .clipped()

                // Document information
                VStack(alignment: .leading, spacing: 16) {
                    // Document name with stronger typography
                    Text(document.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    // Category as a tag/badge
                    HStack(spacing: 8) {
                        Image(systemName: document.category.icon)
                            .foregroundColor(.white)
                            .font(.system(size: 12))

                        Text(document.category.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(document.category.color))
                    .cornerRadius(16)

                    // Extracted data section with enhanced cards
                    if document.amount != nil || document.aiConfidence != nil || document.extractedText != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            // Amount with card style
                            if let amount = document.amount {
                                HStack {
                                    Image(systemName: "francsign.circle.fill")
                                        .foregroundColor(.taxedPrimary)
                                        .font(.system(size: 16))
                                    Text("documents.swipe.amount".localized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(String(format: "CHF %.2f", amount))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }

                            // Confidence indicator (tappable)
                            if let confidence = document.aiConfidence {
                                Button(action: { showConfidenceExplanation = true }) {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.taxedPrimary)
                                            .font(.system(size: 16))
                                        Text("documents.swipe.accuracy".localized)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(Int(confidence * 100))%")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(confidenceColor(confidence))
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                    }
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            // Document summary with card style
                            if let summary = document.aiSummary, !summary.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(.taxedPrimary)
                                            .font(.system(size: 16))
                                        Text("documents.swipe.description".localized)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                    Text(summary)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Tax year, encryption badge, and status
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\("documents.swipe.tax_year".localized): \(String(format: "%d", document.taxYear))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Encryption badge
                            HStack(spacing: 4) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                Text("Encrypted")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        StatusBadge(status: document.status)
                    }

                    // Embedded action buttons in bottom corners
                    HStack {
                        // Reject button (bottom left)
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.red)
                                .clipShape(Circle())

                            Text("documents.swipe.reject".localized)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(20)

                        Spacer()

                        // Approve button (bottom right)
                        HStack(spacing: 6) {
                            Text("documents.swipe.approve".localized)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)

                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 12)
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)

            // Swipe overlays
            swipeOverlay
        }
        .frame(maxWidth: .infinity)
        .frame(height: 580) // Increased height for embedded buttons
        .sheet(isPresented: $showConfidenceExplanation) {
            AIConfidenceExplanationView(
                confidence: document.aiConfidence ?? 0,
                category: document.category,
                extractedFields: getExtractedFields()
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Subviews

    private var documentPlaceholder: some View {
        ZStack {
            // Document paper background effect
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    VStack(alignment: .leading, spacing: 8) {
                        // Document lines to simulate text
                        ForEach(0..<8) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(index < 2 ? 0.3 : 0.15))
                                .frame(height: index == 0 ? 12 : 8)
                                .frame(maxWidth: index == 1 ? 200 : .infinity)
                        }
                        Spacer()

                        // Category badge at bottom
                        HStack {
                            Image(systemName: document.category.icon)
                                .font(.system(size: 40))
                                .foregroundColor(Color(document.category.color).opacity(0.3))
                            Spacer()
                        }
                    }
                    .padding(20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            // Document type overlay in top right
            VStack {
                HStack {
                    Spacer()
                    Text(document.name.components(separatedBy: ".").last?.uppercased() ?? "PDF")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(document.category.color))
                        .cornerRadius(4)
                }
                Spacer()
            }
            .padding(12)
        }
    }

    private var swipeOverlay: some View {
        ZStack {
            // Gradient overlay for swipe feedback
            if offset.width > 0 {
                // Green gradient for approve (right swipe)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.0),
                        Color.green.opacity(min(Double(offset.width) / 200, 0.4))
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .cornerRadius(20)
            } else if offset.width < 0 {
                // Red gradient for reject (left swipe)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red.opacity(min(Double(abs(offset.width)) / 200, 0.4)),
                        Color.red.opacity(0.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .cornerRadius(20)
            }

            // Approve overlay (swipe right)
            if offset.width > 0 {
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .shadow(color: .green.opacity(0.5), radius: 10)

                            Text("documents.swipe.approve".localized)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .green.opacity(0.5), radius: 10)
                        }
                        .padding(30)
                        .opacity(min(Double(offset.width) / 120, 1.0))
                    }
                    Spacer()
                }
            }

            // Reject overlay (swipe left)
            if offset.width < 0 {
                VStack {
                    HStack {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .shadow(color: .red.opacity(0.5), radius: 10)

                            Text("documents.swipe.reject".localized)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .red.opacity(0.5), radius: 10)
                        }
                        .padding(30)
                        .opacity(min(Double(abs(offset.width)) / 120, 1.0))
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    private func getExtractedFields() -> [String] {
        var fields: [String] = []
        if document.amount != nil {
            fields.append("Amount")
        }
        if document.category != .uncategorized {
            fields.append("Category")
        }
        if document.aiSummary != nil {
            fields.append("Description")
        }
        if document.taxYear > 0 {
            fields.append("Tax Year")
        }
        return fields
    }
}

// MARK: - Status Badge Component

struct StatusBadge: View {
    let status: DocumentStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }

    private var statusColor: Color {
        switch status {
        case .uploading:
            return .blue
        case .processing:
            return .purple
        case .pending:
            return .orange
        case .reviewed:
            return .blue
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
}

// MARK: - AI Confidence Explanation View

struct AIConfidenceExplanationView: View {
    let confidence: Double
    let category: TaxCategory
    let extractedFields: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Confidence score header
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50))
                            .foregroundColor(.taxedPrimary)

                        Text("\(Int(confidence * 100))%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(confidenceColor)

                        Text("AI Confidence Score")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    // What this means
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What does this mean?")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(confidenceExplanation)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Extracted fields
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Extracted Fields")
                            .font(.title3)
                            .fontWeight(.bold)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(extractedFields, id: \.self) { field in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16))
                                    Text(field)
                                        .font(.body)
                                }
                            }
                        }
                    }

                    // How we calculate
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How is this calculated?")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("Our AI analyzes your document using advanced OCR and machine learning models. The confidence score reflects:")
                            .font(.body)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            ConfidenceFactorRow(icon: "text.viewfinder", text: "Text clarity and readability")
                            ConfidenceFactorRow(icon: "doc.text.magnifyingglass", text: "Document structure recognition")
                            ConfidenceFactorRow(icon: "checkmark.shield.fill", text: "Data validation checks")
                            ConfidenceFactorRow(icon: "brain", text: "Pattern matching accuracy")
                        }
                    }

                    // GDPR compliance note
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.taxedPrimary)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privacy & Security")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Your data is encrypted and processed according to GDPR and Swiss DSG standards.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("AI Confidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var confidenceColor: Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    private var confidenceExplanation: String {
        if confidence >= 0.9 {
            return "Excellent! Our AI is highly confident in the extracted data. The document was clear and all fields were easily identifiable."
        } else if confidence >= 0.8 {
            return "Very good. Our AI is confident in the extracted data. Minor uncertainties may exist, but overall quality is high."
        } else if confidence >= 0.7 {
            return "Good. The extraction was successful, though some fields may need verification. Please review the data carefully."
        } else if confidence >= 0.5 {
            return "Moderate. The document had some clarity issues. We recommend reviewing all extracted data before approval."
        } else {
            return "Low confidence. The document quality or format made extraction difficult. Please verify all data manually."
        }
    }
}

struct ConfidenceFactorRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.taxedPrimary)
                .font(.system(size: 14))
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SwipeableDocumentCard(
            document: TaxDocument(
                id: "preview1",
                customerId: "user1",
                name: "Salary Statement 2024.pdf",
                storageUrl: "https://example.com/doc.pdf",
                category: .income,
                aiConfidence: 0.95,
                aiSummary: "Annual salary statement from employer for tax year 2024",
                status: .pending,
                taxYear: 2024,
                amount: 85000.50
            ),
            offset: .zero,
            rotation: 0
        )
        .padding()

        SwipeableDocumentCard(
            document: TaxDocument(
                id: "preview2",
                customerId: "user1",
                name: "Medical Expenses Receipt.jpg",
                storageUrl: "https://example.com/doc2.pdf",
                category: .deduction,
                aiConfidence: 0.75,
                status: .approved,
                taxYear: 2024,
                amount: 450.00
            ),
            offset: CGSize(width: 50, height: 0),
            rotation: 5
        )
        .padding()
    }
}
