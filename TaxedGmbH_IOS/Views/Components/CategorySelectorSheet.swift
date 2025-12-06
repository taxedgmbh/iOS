//
//  CategorySelectorSheet.swift
//  TaxedGmbH_IOS
//
//  Unified category selector for document categorization
//  Used by: DocumentUploadView, RemapDocumentSheet
//

import SwiftUI

/// Reusable category selector sheet for single-selection of tax categories
/// Provides search, grouping, and visual grid layout with tax index preview
struct CategorySelectorSheet: View {
    @Binding var selectedCategory: TaxCategoryType?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @State private var searchText = ""
    @State private var taxIndexes: [TaxCategoryType: String?] = [:]
    @State private var isLoadingIndexes = true

    // Get all available categories
    private var allCategories: [TaxCategoryType] {
        TaxCategoryType.allCases.filter { $0 != .other }
    }

    private var filteredCategoriesByGroup: [CategoryGroup: [TaxCategoryType]] {
        var grouped: [CategoryGroup: [TaxCategoryType]] = [:]

        let categoriesToShow = searchText.isEmpty ? allCategories :
            allCategories.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }

        for category in categoriesToShow {
            grouped[category.categoryGroup, default: []].append(category)
        }

        return grouped
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search categories", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Categories by group
                    ForEach(CategoryGroup.allCases, id: \.self) { group in
                        if let categories = filteredCategoriesByGroup[group], !categories.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                // Group header
                                HStack {
                                    Image(systemName: group.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                                    Text(group.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal)

                                // Category grid
                                LazyVGrid(columns: [GridItem(), GridItem()], spacing: 8) {
                                    ForEach(categories.sorted { $0.displayName < $1.displayName }, id: \.self) { category in
                                        CategoryOptionButton(
                                            category: category,
                                            isSelected: selectedCategory == category,
                                            taxIndex: taxIndexes[category] ?? nil
                                        ) {
                                            selectedCategory = category
                                            // Haptic feedback
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            // Dismiss after selection
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("document_upload.select_category.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await loadTaxIndexes()
                }
            }
        }
    }

    // MARK: - Tax Index Loading
    private func loadTaxIndexes() async {
        guard let canton = authService.user?.canton else {
            print("⚠️ No canton selected - cannot load tax indexes")
            isLoadingIndexes = false
            return
        }

        print("📊 Loading tax indexes for canton: \(canton)")

        // Load index for each category
        for category in allCategories {
            do {
                if let mapping = try await TaxIndexService.shared.getIndexMapping(
                    canton: canton,
                    category: category,
                    person: nil
                ) {
                    await MainActor.run {
                        taxIndexes[category] = mapping.index
                    }
                    print("✅ Loaded index for \(category.rawValue): \(mapping.index)")
                } else {
                    await MainActor.run {
                        taxIndexes[category] = nil
                    }
                    print("⚠️ No index found for \(category.rawValue)")
                }
            } catch {
                print("❌ Error loading index for \(category.rawValue): \(error)")
                await MainActor.run {
                    taxIndexes[category] = nil
                }
            }
        }

        await MainActor.run {
            isLoadingIndexes = false
        }
        print("✅ Tax index loading complete")
    }
}

// MARK: - Category Option Button
struct CategoryOptionButton: View {
    let category: TaxCategoryType
    let isSelected: Bool
    let taxIndex: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? category.color.opacity(0.15) : Color(UIColor.systemGray6))
                        .frame(height: 100) // Increased from 80 to fit index badge

                    VStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 24))
                            .foregroundColor(category.color)

                        Text(category.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        // Tax index badge
                        if let index = taxIndex {
                            Text("Ziffer \(index)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(category.color.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                    .padding(8)

                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                                    .font(.title3)
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color(red: 227/255, green: 30/255, blue: 36/255) : Color.clear, lineWidth: 2)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CategorySelectorSheet(selectedCategory: .constant(nil))
        .environmentObject(AuthenticationService())
}
