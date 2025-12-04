//
//  RemapDocumentSheet.swift
//  TaxedGmbH_IOS
//
//  Sheet for remapping document categories
//

import SwiftUI

struct RemapDocumentSheet: View {
    let document: TaxDocument
    let onComplete: () -> Void

    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var documentManager = DocumentManager.shared
    @State private var selectedCategory: TaxCategoryType?
    @State private var regenerateAttachment = true
    @State private var isRemapping = false
    @State private var showCategorySelector = false

    var body: some View {
        NavigationView {
            Form {
                // Current Category Section
                Section(header: Text("Current Category")) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(0.15))
                                .frame(width: 40, height: 40)

                            Image(systemName: document.category.icon)
                                .foregroundColor(categoryColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.category.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if let subcategory = document.subcategory {
                                Text(subcategory.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let attachmentNum = document.attachmentNumber {
                                Text(attachmentNum)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(categoryColor)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // New Category Section
                Section(header: Text("Select New Category")) {
                    Button(action: { showCategorySelector = true }) {
                        HStack {
                            if let selected = selectedCategory {
                                Image(systemName: selected.icon)
                                    .foregroundColor(selected.color)
                                Text(selected.displayName)
                                    .foregroundColor(.primary)
                            } else {
                                Image(systemName: "folder")
                                    .foregroundColor(.gray)
                                Text("Choose a category...")
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Options Section
                Section {
                    Toggle(isOn: $regenerateAttachment) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Regenerate Attachment Number")
                                .font(.subheadline)
                            Text("Create a new attachment number matching the new category")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Preview Section
                if let selected = selectedCategory {
                    Section(header: Text("Preview")) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(selected.color.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: selected.icon)
                                    .foregroundColor(selected.color)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(selected.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                if regenerateAttachment {
                                    Text(previewAttachmentNumber())
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(selected.color)
                                        .cornerRadius(4)
                                } else if let existingNum = document.attachmentNumber {
                                    Text(existingNum)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(selected.color)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Remap Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete()
                    }
                    .disabled(isRemapping)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: remapDocument) {
                        if isRemapping {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Remap")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(selectedCategory == nil || isRemapping)
                }
            }
        }
        .sheet(isPresented: $showCategorySelector) {
            CategorySelectorSheet(selectedCategory: $selectedCategory)
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

    private func previewAttachmentNumber() -> String {
        guard let selected = selectedCategory else { return "" }
        let code = documentManager.getShortCode(for: selected.rawValue)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let timestamp = dateFormatter.string(from: document.uploadedAt)
        let lastFour = String(timestamp.suffix(4))
        return "\(code)_\(lastFour)"
    }

    private func remapDocument() {
        guard let newCategory = selectedCategory else { return }

        isRemapping = true

        Task {
            do {
                try await documentManager.remapDocument(
                    document,
                    to: newCategory,
                    regenerateAttachment: regenerateAttachment,
                    user: authService.user
                )
                print("✅ Document remapped successfully - cover sheet will auto-generate")
                await MainActor.run {
                    isRemapping = false
                    onComplete()
                }
            } catch {
                print("❌ Failed to remap document: \(error)")
                await MainActor.run {
                    isRemapping = false
                }
            }
        }
    }
}

#Preview {
    RemapDocumentSheet(
        document: TaxDocument(
            customerId: "user123",
            name: "Test.pdf",
            storageUrl: "https://example.com/test.pdf",
            category: .income,
            subcategory: "salary",
            taxYear: 2024,
            attachmentNumber: "SAL_1234"
        ),
        onComplete: {}
    )
}
