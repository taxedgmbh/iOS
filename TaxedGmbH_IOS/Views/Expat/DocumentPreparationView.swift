//
//  DocumentPreparationView.swift
//  TaxedGmbH_IOS
//
//  Document preparation guide for expats
//

import SwiftUI

struct DocumentPreparationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory = 0

    let categories = [
        DocumentPrepCategory(
            id: 0,
            title: "prep.category.personal".localized,
            icon: "person.text.rectangle.fill",
            color: .blue,
            documents: [
                DocumentItem(name: "prep.doc.passport".localized, required: true),
                DocumentItem(name: "prep.doc.permit".localized, required: true),
                DocumentItem(name: "prep.doc.registration".localized, required: true),
                DocumentItem(name: "prep.doc.marriage".localized, required: false)
            ]
        ),
        DocumentPrepCategory(
            id: 1,
            title: "prep.category.income".localized,
            icon: "dollarsign.circle.fill",
            color: .green,
            documents: [
                DocumentItem(name: "prep.doc.salary_cert".localized, required: true),
                DocumentItem(name: "prep.doc.bank_statements".localized, required: true),
                DocumentItem(name: "prep.doc.foreign_income".localized, required: false),
                DocumentItem(name: "prep.doc.investment_income".localized, required: false)
            ]
        ),
        DocumentPrepCategory(
            id: 2,
            title: "prep.category.deductions".localized,
            icon: "minus.circle.fill",
            color: .orange,
            documents: [
                DocumentItem(name: "prep.doc.health_insurance".localized, required: true),
                DocumentItem(name: "prep.doc.pillar_3a".localized, required: false),
                DocumentItem(name: "prep.doc.moving_expenses".localized, required: false),
                DocumentItem(name: "prep.doc.professional_expenses".localized, required: false)
            ]
        ),
        DocumentPrepCategory(
            id: 3,
            title: "prep.category.wealth".localized,
            icon: "building.2.fill",
            color: .purple,
            documents: [
                DocumentItem(name: "prep.doc.property".localized, required: false),
                DocumentItem(name: "prep.doc.stocks".localized, required: false),
                DocumentItem(name: "prep.doc.crypto".localized, required: false),
                DocumentItem(name: "prep.doc.foreign_assets".localized, required: false)
            ]
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories) { category in
                            CategoryTab(
                                category: category,
                                isSelected: selectedCategory == category.id
                            ) {
                                withAnimation {
                                    selectedCategory = category.id
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))

                // Document List
                ScrollView {
                    VStack(spacing: 16) {
                        // Category Header
                        HStack {
                            Image(systemName: categories[selectedCategory].icon)
                                .font(.title2)
                                .foregroundColor(categories[selectedCategory].color)

                            Text(categories[selectedCategory].title)
                                .font(.title2)
                                .fontWeight(.bold)

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Documents
                        VStack(spacing: 12) {
                            ForEach(categories[selectedCategory].documents) { document in
                                DocumentItemRow(document: document)
                            }
                        }
                        .padding(.horizontal)

                        // Tips Section
                        TipsCard(category: categories[selectedCategory])
                            .padding()
                    }
                }
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("prep.title".localized)
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
}

// MARK: - Models
struct DocumentPrepCategory: Identifiable {
    let id: Int
    let title: String
    let icon: String
    let color: Color
    let documents: [DocumentItem]
}

struct DocumentItem: Identifiable {
    let id = UUID()
    let name: String
    let required: Bool
}

// MARK: - Category Tab
struct CategoryTab: View {
    let category: DocumentPrepCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? category.color : .gray)

                Text(category.title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color.opacity(0.15) : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Document Item Row
struct DocumentItemRow: View {
    let document: DocumentItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.required ? "exclamationmark.circle.fill" : "info.circle.fill")
                .foregroundColor(document.required ? .orange : .blue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(document.required ? "prep.required".localized : "prep.optional".localized)
                    .font(.caption)
                    .foregroundColor(document.required ? .orange : .secondary)
            }

            Spacer()

            Image(systemName: "arrow.down.circle")
                .foregroundColor(.secondary)
                .font(.title3)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Tips Card
struct TipsCard: View {
    let category: DocumentPrepCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("prep.tips.title".localized)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text("•")
                    Text("prep.tips.organize".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .top) {
                    Text("•")
                    Text("prep.tips.translate".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .top) {
                    Text("•")
                    Text("prep.tips.copies".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    DocumentPreparationView()
}