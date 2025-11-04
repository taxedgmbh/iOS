//
//  DashboardView.swift
//  TaxedGmbH_IOS
//
//  Main dashboard view showing tax progress and document categories
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var firestoreService = FirestoreService.shared
    @ObservedObject private var localizationService = LocalizationService.shared
    @StateObject private var categoryConfig = CategoryConfigurationModel()

    @State private var documents: [TaxDocument] = []
    @State private var completionPercentage: Double = 0.0
    @State private var categoryStats: [TaxCategory: Int] = [:]
    @State private var showUploadSheet = false
    @State private var showDocumentList = false
    @State private var showExpatHub = false
    @State private var showCategoryPicker = false

    let requiredDocumentCount = 15

    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Show welcome state if no documents
                    if documents.isEmpty {
                        WelcomeEmptyState(
                            userName: authService.user?.name ?? "User",
                            onGetStarted: { showUploadSheet = true }
                        )
                    } else {
                        // Welcome Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("dashboard.welcome_back".localized)
                                .font(.title3)
                                .foregroundColor(.gray)

                            Text(authService.user?.name ?? "")
                                .font(.title)
                                .fontWeight(.bold)

                            if let canton = authService.user?.canton {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                    Text(String(format: "dashboard.tax_period".localized, canton))
                                        .font(.subheadline)
                                }
                                .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)

                    // Progress Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("dashboard.progress".localized)
                                    .font(.headline)

                                Text(String(format: "dashboard.documents_count".localized, documents.count, requiredDocumentCount))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text(String(format: "dashboard.completion".localized, Int(completionPercentage)))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.blue)
                        }

                        ProgressView(value: completionPercentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 2, anchor: .center)

                        if completionPercentage < 100 {
                            Text(String(format: "dashboard.documents_missing".localized, requiredDocumentCount - documents.count))
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("dashboard.all_uploaded".localized)
                            }
                            .font(.caption)
                            .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.taxedPrimary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.taxedPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Category Grid with Edit Mode
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("dashboard.categories".localized)
                                .font(.headline)

                            Spacer()

                            // Edit button following Apple HIG
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    categoryConfig.isEditMode.toggle()
                                }
                            }) {
                                Text(categoryConfig.isEditMode ? "Done" : "Edit")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                            }
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(), GridItem()], spacing: 16) {
                            // Show selected categories
                            ForEach(Array(categoryConfig.selectedCategories), id: \.self) { categoryType in
                                CustomizableCategoryCard(
                                    categoryType: categoryType,
                                    documentCount: getDocumentCount(for: categoryType),
                                    isEditMode: categoryConfig.isEditMode,
                                    onRemove: {
                                        categoryConfig.toggleCategory(categoryType)
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }

                            // Add category button in edit mode
                            if categoryConfig.isEditMode {
                                Button(action: {
                                    showCategoryPicker = true
                                }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(height: 140)

                                            VStack(spacing: 8) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))

                                                Text("Add Category")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                                            }
                                        }
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("dashboard.actions".localized)
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            QuickActionButton(
                                icon: "globe.europe.africa.fill",
                                title: "dashboard.expat_guide".localized,
                                subtitle: "dashboard.expat_guide_subtitle".localized,
                                color: .orange
                            ) {
                                showExpatHub = true
                            }

                            QuickActionButton(
                                icon: "plus.circle.fill",
                                title: "dashboard.upload_document".localized,
                                subtitle: "dashboard.upload_subtitle".localized,
                                color: .blue
                            ) {
                                showUploadSheet = true
                            }

                            QuickActionButton(
                                icon: "doc.text.fill",
                                title: "dashboard.all_documents".localized,
                                subtitle: String(format: "dashboard.view_documents".localized, documents.count),
                                color: .green
                            ) {
                                showDocumentList = true
                            }

                            QuickActionButton(
                                icon: "person.crop.circle.fill",
                                title: "dashboard.profile".localized,
                                subtitle: "dashboard.profile_subtitle".localized,
                                color: .purple
                            ) {
                                // TODO: Navigate to profile
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Recent Documents
                    if !documents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("dashboard.recent".localized)
                                    .font(.headline)

                                Spacer()

                                Button("dashboard.view_all".localized) {
                                    showDocumentList = true
                                }
                                .font(.subheadline)
                            }
                            .padding(.horizontal)

                            VStack(spacing: 8) {
                                ForEach(documents.prefix(3)) { document in
                                    NavigationLink(destination: DocumentDetailView(document: document)) {
                                        RecentDocumentRow(document: document)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    }

                    // Branded Footer
                    BrandedFooterView(style: documents.isEmpty ? .compact : .full)
                        .padding(.top, 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("dashboard.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showExpatHub) {
                ExpatHubView()
            }
            .sheet(isPresented: $showUploadSheet) {
                DocumentUploadView()
            }
            .sheet(isPresented: $showDocumentList) {
                DocumentListView()
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(categoryConfig: categoryConfig)
            }
            .task {
                await loadDashboardData()
                observeDocuments()
            }
            .refreshable {
                await loadDashboardData()
            }
    }

    // Helper function to get document count for category type
    private func getDocumentCount(for categoryType: TaxCategoryType) -> Int {
        // Map TaxCategoryType to TaxCategory for document counting
        // This is a simplified mapping - you may need to adjust based on your actual category mapping
        switch categoryType {
        case .salary, .bonus, .freelance, .investment, .rental, .pension:
            return categoryStats[.income] ?? 0
        case .foreignIncome:
            return categoryStats[.foreignIncome] ?? 0
        case .mortgage, .donations, .education, .medical, .insurance, .childcare, .homeOffice:
            return categoryStats[.deduction] ?? 0
        case .property, .stocks, .crypto, .savings:
            return categoryStats[.wealth] ?? 0
        case .foreignWealth:
            return categoryStats[.foreignWealth] ?? 0
        case .pillar2, .pillar3a:
            return categoryStats[.pillar] ?? 0
        case .militaryService, .taxTreaty:
            return categoryStats[.taxTreaty] ?? 0
        }
    }

    private func loadDashboardData() async {
        guard let userId = authService.user?.id else { return }

        do {
            documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)
            categoryStats = try await firestoreService.getDocumentStats(customerId: userId)
            completionPercentage = try await firestoreService.getCompletionPercentage(
                customerId: userId,
                requiredCount: requiredDocumentCount
            )
        } catch {
            print("❌ Error loading dashboard data: \(error)")
        }
    }

    private func observeDocuments() {
        guard let userId = authService.user?.id else { return }

        firestoreService.observeCustomerDocuments(customerId: userId) { updatedDocs in
            documents = updatedDocs

            // Recalculate stats
            var stats: [TaxCategory: Int] = [:]
            for category in TaxCategory.allCases {
                stats[category] = updatedDocs.filter { $0.category == category }.count
            }
            categoryStats = stats

            // Recalculate completion
            let approvedCount = updatedDocs.filter { $0.status == .approved || $0.status == .reviewed }.count
            completionPercentage = Double(approvedCount) / Double(requiredDocumentCount) * 100.0
        }
    }
}

// MARK: - Supporting Views

struct CategoryCard: View {
    let category: TaxCategory
    let count: Int
    let totalDocuments: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(colorForCategory)

                Spacer()

                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(String(format: "dashboard.category_documents".localized, count))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorForCategory.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorForCategory.opacity(0.3), lineWidth: 1)
        )
    }

    private var colorForCategory: Color {
        switch category {
        case .income: return .green
        case .deduction: return .blue
        case .pillar: return .purple
        case .wealth: return .orange
        case .foreignIncome, .foreignPension: return .orange
        case .foreignWealth: return .yellow
        case .taxTreaty: return .cyan
        case .foreignTax: return .mint
        case .uncategorized: return .gray
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct RecentDocumentRow: View {
    let document: TaxDocument

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.category.icon)
                .font(.title3)
                .foregroundColor(colorForCategory)
                .frame(width: 36, height: 36)
                .background(colorForCategory.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(document.category.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }

    private var colorForCategory: Color {
        switch document.category {
        case .income: return .green
        case .deduction: return .blue
        case .pillar: return .purple
        case .wealth: return .orange
        case .foreignIncome, .foreignPension: return .orange
        case .foreignWealth: return .yellow
        case .taxTreaty: return .cyan
        case .foreignTax: return .mint
        case .uncategorized: return .gray
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthenticationService())
}
