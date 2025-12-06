//
//  CategoryPickerView.swift
//  TaxedGmbH_IOS
//
//  Category selection sheet following Apple HIG
//

import SwiftUI

struct CategoryPickerView: View {
    @ObservedObject var categoryConfig: CategoryConfigurationModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @State private var searchText = ""
    @State private var taxIndexes: [TaxCategoryType: String?] = [:]
    @State private var isLoadingIndexes = true

    var filteredCategories: [CategoryGroup: [TaxCategoryType]] {
        let available = categoryConfig.availableCategoriesByGroup

        if searchText.isEmpty {
            return available
        }

        var filtered: [CategoryGroup: [TaxCategoryType]] = [:]
        for (group, categories) in available {
            let matchingCategories = categories.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
            if !matchingCategories.isEmpty {
                filtered[group] = matchingCategories
            }
        }
        return filtered
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Search bar (Apple HIG style)
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

                    // Quick actions
                    if searchText.isEmpty {
                        VStack(spacing: 12) {
                            Text("Quick Actions")
                                .font(.headline)
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                QuickActionChip(
                                    title: "Select All",
                                    icon: "checkmark.circle.fill",
                                    color: .blue
                                ) {
                                    categoryConfig.selectAll()
                                    dismiss()
                                }

                                QuickActionChip(
                                    title: "Reset to Defaults",
                                    icon: "arrow.counterclockwise",
                                    color: .orange
                                ) {
                                    categoryConfig.resetToDefaults()
                                    dismiss()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Categories by group
                    ForEach(CategoryGroup.allCases, id: \.self) { group in
                        if let categories = filteredCategories[group], !categories.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Group header
                                HStack {
                                    Image(systemName: group.icon)
                                        .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                                    Text(group.displayName)
                                        .font(.headline)
                                }
                                .padding(.horizontal)

                                // Category grid for this group
                                LazyVGrid(columns: [GridItem(), GridItem()], spacing: 12) {
                                    ForEach(categories.sorted { $0.displayName < $1.displayName }, id: \.self) { category in
                                        CategorySelectionCard(
                                            category: category,
                                            isSelected: categoryConfig.selectedCategories.contains(category),
                                            taxIndex: taxIndexes[category] ?? nil
                                        ) {
                                            categoryConfig.toggleCategory(category)
                                            // Haptic feedback
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Empty state
                    if filteredCategories.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No categories found")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Try adjusting your search")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }

                    // Info footer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Categories")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("Select categories that match your tax situation. You can always add or remove categories later.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Add Categories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
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
            print("⚠️ CategoryPickerView: No canton selected - cannot load tax indexes")
            isLoadingIndexes = false
            return
        }

        print("📊 CategoryPickerView: Loading tax indexes for canton: \(canton)")

        // Get all available categories
        let allCategories = categoryConfig.availableCategoriesByGroup.values.flatMap { $0 }

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
                    print("✅ CategoryPickerView: Loaded index for \(category.rawValue): \(mapping.index)")
                } else {
                    await MainActor.run {
                        taxIndexes[category] = nil
                    }
                    print("⚠️ CategoryPickerView: No index found for \(category.rawValue)")
                }
            } catch {
                print("❌ CategoryPickerView: Error loading index for \(category.rawValue): \(error)")
                await MainActor.run {
                    taxIndexes[category] = nil
                }
            }
        }

        await MainActor.run {
            isLoadingIndexes = false
        }
        print("✅ CategoryPickerView: Tax index loading complete")
    }
}

// MARK: - Category Selection Card
struct CategorySelectionCard: View {
    let category: TaxCategoryType
    let isSelected: Bool
    let taxIndex: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(category.color)
                        .frame(width: 24, height: 24)

                    Text(category.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                    }
                }

                // Tax index badge (bottom-aligned)
                if let index = taxIndex {
                    HStack {
                        Spacer()
                        Text("Ziffer \(index)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(category.color.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color(red: 227/255, green: 30/255, blue: 36/255) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Action Chip
struct QuickActionChip: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .cornerRadius(20)
        }
    }
}

// MARK: - Preview
#Preview {
    CategoryPickerView(categoryConfig: CategoryConfigurationModel())
}