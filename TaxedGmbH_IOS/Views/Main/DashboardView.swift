//
//  DashboardView.swift
//  TaxedGmbH_IOS
//
//  Main dashboard view with liquid glass design
//  Following Apple HIG guidelines for accessibility and design
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var firestoreService = FirestoreService.shared
    @ObservedObject private var localizationService = LocalizationService.shared
    @StateObject private var categoryConfig = CategoryConfigurationModel()

    @State private var documents: [TaxDocument] = []
    @State private var completionPercentage: Double = 0.0
    @State private var subcategoryStats: [String: Int] = [:]
    @State private var showUploadSheet = false
    @State private var showDocumentList = false
    @State private var showExpatHub = false
    @State private var showCategoryPicker = false
    @State private var contentOpacity: Double = 0
    @State private var progressScale: CGFloat = 0.8

    // Accessibility Environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    let requiredDocumentCount = 15

    var body: some View {
        ZStack {
            // Animated Glass Background
            if !reduceTransparency {
                AnimatedGlassBackground()
            } else {
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
            }

            ScrollView {
                VStack(spacing: 24) {
                    if documents.isEmpty {
                        // Welcome Empty State with Glass Design
                        glassWelcomeEmptyState
                            .opacity(contentOpacity)
                    } else {
                        // Welcome Header
                        welcomeHeader
                            .opacity(contentOpacity)

                        // Progress Card with Glass Design
                        glassProgressCard
                            .opacity(contentOpacity)
                            .scaleEffect(progressScale)

                        // Category Grid with Edit Mode
                        categorySectionView
                            .opacity(contentOpacity)

                        // Quick Actions with Glass Design
                        quickActionsSection
                            .opacity(contentOpacity)

                        // Recent Documents
                        if !documents.isEmpty {
                            recentDocumentsSection
                                .opacity(contentOpacity)
                        }
                    }

                    // Branded Footer with Glass Design
                    glassFooter
                        .padding(.top, 20)
                        .opacity(contentOpacity)
                }
                .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("dashboard.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExpatHub) {
            UnifiedExpatCenterView()
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
            animateEntrance()
        }
        .refreshable {
            await loadDashboardData()
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("dashboard.welcome_back".localized)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            Text(authService.user?.name ?? "")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .accessibilityLabel("dashboard.welcome_name".localized(with: authService.user?.name ?? ""))

            if let canton = authService.user?.canton {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.taxedPrimary)
                        .symbolRenderingMode(.hierarchical)

                    Text(String(format: "dashboard.tax_period".localized, canton))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    // MARK: - Glass Progress Card

    private var glassProgressCard: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("dashboard.progress".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(String(format: "dashboard.documents_count".localized, documents.count, requiredDocumentCount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(completionPercentage / 100))
                        .stroke(
                            LinearGradient(
                                colors: [.taxedPrimary, .taxedPrimary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: completionPercentage)

                    Text("\(Int(completionPercentage))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.taxedPrimary)
                }
                .accessibilityLabel("dashboard.completion_percentage".localized(with: String(Int(completionPercentage))))
            }

            // Status Message
            HStack(spacing: 8) {
                Image(systemName: completionPercentage < 100 ? "info.circle.fill" : "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(completionPercentage < 100 ? .orange : .green)
                    .symbolRenderingMode(.hierarchical)

                Text(completionPercentage < 100
                    ? String(format: "dashboard.documents_missing".localized, requiredDocumentCount - documents.count)
                    : "dashboard.all_uploaded".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(completionPercentage < 100 ? .orange : .green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
        .padding(24)
        .glassCard(
            cornerRadius: 24,
            borderColor: .taxedPrimary.opacity(0.3),
            glowColor: .taxedPrimary.opacity(0.15)
        )
        .padding(.horizontal, 24)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("dashboard.progress_card".localized)
    }

    // MARK: - Category Section

    private var categorySectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("dashboard.categories".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // Edit button with glass style
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        categoryConfig.isEditMode.toggle()
                    }
                }) {
                    Text(categoryConfig.isEditMode ? "dashboard.done".localized : "dashboard.edit".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.taxedPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.taxedPrimary.opacity(0.3), lineWidth: 1)
                        )
                }
                .accessibilityLabel(categoryConfig.isEditMode ? "dashboard.done_editing".localized : "dashboard.edit_categories".localized)
                .accessibilityHint("dashboard.edit_hint".localized)
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal, 24)

            // Group categories by CategoryGroup
            ForEach(CategoryGroup.allCases, id: \.self) { group in
                let categoriesInGroup = Array(categoryConfig.selectedCategories.filter { $0.categoryGroup == group })

                if !categoriesInGroup.isEmpty || categoryConfig.isEditMode {
                    categoryGroupSection(group: group, categories: categoriesInGroup)
                }
            }

            // Add category button in edit mode
            if categoryConfig.isEditMode {
                addCategoryButton
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
    }

    private func categoryGroupSection(group: CategoryGroup, categories: [TaxCategoryType]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Group header
            HStack(spacing: 8) {
                Image(systemName: group.icon)
                    .font(.subheadline)
                    .foregroundStyle(.taxedPrimary)
                    .symbolRenderingMode(.hierarchical)

                Text(group.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(Array(categories).sorted { $0.displayName < $1.displayName }, id: \.self) { categoryType in
                    GlassCategoryCard(
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
            }
            .padding(.horizontal, 24)
        }
    }

    private var addCategoryButton: some View {
        Button(action: {
            showCategoryPicker = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.taxedPrimary)
                    .symbolRenderingMode(.hierarchical)

                Text("dashboard.add_category".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.taxedPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .foregroundStyle(.taxedPrimary.opacity(0.3))
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 24)
        .accessibilityLabel("dashboard.add_category_button".localized)
        .accessibilityHint("dashboard.add_category_hint".localized)
        .frame(minWidth: 44, minHeight: 44)
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("dashboard.actions".localized)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 24)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                // First Page Tax Return - Highlighted
                GlassQuickActionButton(
                    icon: "doc.text.fill",
                    title: "dashboard.first_page_tax_return".localized,
                    subtitle: "dashboard.first_page_subtitle".localized,
                    color: .taxedPrimary,
                    isHighlighted: true
                ) {
                    showUploadSheet = true
                }

                GlassQuickActionButton(
                    icon: "globe.europe.africa.fill",
                    title: "dashboard.expat_guide".localized,
                    subtitle: "dashboard.expat_guide_subtitle".localized,
                    color: .orange
                ) {
                    showExpatHub = true
                }

                GlassQuickActionButton(
                    icon: "plus.circle.fill",
                    title: "dashboard.upload_document".localized,
                    subtitle: "dashboard.upload_subtitle".localized,
                    color: .blue
                ) {
                    showUploadSheet = true
                }

                GlassQuickActionButton(
                    icon: "doc.text.fill",
                    title: "dashboard.all_documents".localized,
                    subtitle: String(format: "dashboard.view_documents".localized, documents.count),
                    color: .green
                ) {
                    showDocumentList = true
                }

                GlassQuickActionButton(
                    icon: "person.crop.circle.fill",
                    title: "dashboard.profile".localized,
                    subtitle: "dashboard.profile_subtitle".localized,
                    color: .purple
                ) {
                    // Navigate to profile - handled by parent
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Recent Documents Section

    private var recentDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("dashboard.recent".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button("dashboard.view_all".localized) {
                    showDocumentList = true
                }
                .font(.headline)
                .foregroundStyle(.taxedPrimary)
                .accessibilityLabel("dashboard.view_all_documents".localized)
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                ForEach(documents.prefix(3)) { document in
                    NavigationLink(destination: DocumentDetailView(document: document)) {
                        GlassRecentDocumentRow(document: document)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Glass Welcome Empty State

    private var glassWelcomeEmptyState: some View {
        VStack(spacing: 32) {
            Spacer()
                .frame(height: 40)

            // Logo with Glass Effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.taxedPrimary.opacity(0.6),
                                        Color.taxedPrimary.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                Image("taxed-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
            }
            .glow(color: .taxedPrimary, radius: 25)
            .accessibilityHidden(true)

            // Welcome Text
            VStack(spacing: 16) {
                Text("empty_state.welcome.title".localized(with: authService.user?.name ?? "User"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                Text("empty_state.welcome.subtitle".localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Quick Start Steps in Glass Card
            VStack(alignment: .leading, spacing: 20) {
                ForEach(1...4, id: \.self) { step in
                    QuickStartStepGlass(
                        number: step,
                        title: "empty_state.welcome.step\(step).title".localized,
                        description: "empty_state.welcome.step\(step).description".localized
                    )
                }
            }
            .padding(24)
            .glassCard(
                cornerRadius: 24,
                borderColor: .white.opacity(0.3)
            )
            .padding(.horizontal, 24)

            // Get Started Button
            Button(action: { showUploadSheet = true }) {
                HStack(spacing: 12) {
                    Text("empty_state.welcome.action".localized)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.taxedPrimary, .taxedPrimary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .taxedPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 24)
            .accessibilityLabel("empty_state.welcome.get_started".localized)
            .accessibilityHint("empty_state.welcome.get_started_hint".localized)

            Spacer()
        }
    }

    // MARK: - Glass Footer

    private var glassFooter: some View {
        VStack(spacing: 20) {
            Divider()
                .padding(.horizontal, 24)

            VStack(spacing: 16) {
                Image("taxed-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .accessibilityHidden(true)

                Text(currentTagline)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.taxedPrimary)
                    .multilineTextAlignment(.center)

                Text("common.version".localized(with: AppConstants.App.version))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helper Functions

    private func getDocumentCount(for categoryType: TaxCategoryType) -> Int {
        return subcategoryStats[categoryType.rawValue] ?? 0
    }

    private func loadDashboardData() async {
        guard let userId = authService.user?.id else { return }

        do {
            documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)
            subcategoryStats = try await firestoreService.getSubcategoryStats(customerId: userId)
            completionPercentage = try await firestoreService.getCompletionPercentage(
                customerId: userId,
                requiredCount: requiredDocumentCount
            )
        } catch {
            print("Error loading dashboard data: \(error)")
        }
    }

    private func observeDocuments() {
        guard let userId = authService.user?.id else { return }

        firestoreService.observeCustomerDocuments(customerId: userId) { updatedDocs in
            documents = updatedDocs

            // Recalculate subcategory stats
            var stats: [String: Int] = [:]
            for document in updatedDocs {
                if let taxCategoryType = document.taxCategoryType {
                    stats[taxCategoryType, default: 0] += 1
                } else {
                    let categoryKey = document.category.rawValue
                    stats[categoryKey, default: 0] += 1
                }
            }
            subcategoryStats = stats

            // Recalculate completion
            let approvedCount = updatedDocs.filter { $0.status == .approved || $0.status == .reviewed }.count
            completionPercentage = Double(approvedCount) / Double(requiredDocumentCount) * 100.0
        }
    }

    private func animateEntrance() {
        if reduceMotion {
            contentOpacity = 1
            progressScale = 1
        } else {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                contentOpacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                progressScale = 1
            }
        }
    }

    private var currentTagline: String {
        switch localizationService.currentLanguage {
        case .german:
            return AppConstants.Branding.tagline
        case .english:
            return AppConstants.Branding.taglineEN
        case .french:
            return AppConstants.Branding.taglineFR
        case .italian:
            return AppConstants.Branding.taglineIT
        }
    }
}

// MARK: - Supporting Views

// MARK: - Glass Category Card
struct GlassCategoryCard: View {
    let categoryType: TaxCategoryType
    let documentCount: Int
    var isEditMode: Bool = false
    var onRemove: (() -> Void)?

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main card content
            VStack(spacing: 16) {
                // Category icon with glass background
                ZStack {
                    Circle()
                        .fill(categoryType.color.opacity(0.1))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(categoryType.color.opacity(0.3), lineWidth: 1)
                        )

                    Image(systemName: categoryType.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(categoryType.color)
                        .symbolRenderingMode(.hierarchical)
                }
                .overlay(
                    // Document count badge
                    documentCount > 0 ?
                    Text("\(documentCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .padding(.horizontal, 4)
                        .background(categoryType.color)
                        .clipShape(Circle())
                        .offset(x: 22, y: -22)
                    : nil
                )

                // Category name
                VStack(spacing: 4) {
                    Text(categoryType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(documentCount) \(documentCount == 1 ? "dashboard.document".localized : "dashboard.documents".localized)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(categoryType.color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .rotationEffect(
                .degrees(isEditMode && !reduceMotion ? sin(Date().timeIntervalSinceReferenceDate * 5) * 1.0 : 0),
                anchor: .center
            )
            .animation(
                isEditMode && !reduceMotion ?
                    Animation.easeInOut(duration: 0.12).repeatForever(autoreverses: true) :
                    .default,
                value: isEditMode
            )

            // Delete button in edit mode
            if isEditMode {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onRemove?()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                            .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)

                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .offset(x: 8, y: -8)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
                .accessibilityLabel("dashboard.remove_category".localized(with: categoryType.displayName))
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .onTapGesture {
            if !isEditMode {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(categoryType.displayName). \(documentCount) \(documentCount == 1 ? "dashboard.document".localized : "dashboard.documents".localized)")
    }
}

// MARK: - Glass Quick Action Button
struct GlassQuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isHighlighted: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with glass background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHighlighted ? color.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .if(isHighlighted) { view in
            view.glow(color: color.opacity(0.2), radius: 12)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityAddTraits(.isButton)
        .frame(minHeight: 44)
    }
}

// MARK: - Glass Recent Document Row
struct GlassRecentDocumentRow: View {
    let document: TaxDocument

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

    var body: some View {
        HStack(spacing: 16) {
            // Document icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorForCategory.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: document.category.icon)
                    .font(.title3)
                    .foregroundStyle(colorForCategory)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(document.category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(document.name), \(document.category.displayName)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Quick Start Step Glass
struct QuickStartStepGlass: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Number Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.taxedPrimary, .taxedPrimary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: .taxedPrimary.opacity(0.3), radius: 4, x: 0, y: 2)

                Text("\(number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("dashboard.step".localized(with: String(number), title, description))
    }
}

// MARK: - Note
// AnimatedGlassBackground and ScaleButtonStyle are defined in AuthenticationView_LiquidGlass.swift and ProcessStageView.swift

// MARK: - Preview
#Preview {
    NavigationView {
        DashboardView()
            .environmentObject(AuthenticationService())
    }
}
