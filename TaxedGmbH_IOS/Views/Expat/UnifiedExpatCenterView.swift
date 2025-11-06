//
//  UnifiedExpatCenterView.swift
//  TaxedGmbH_IOS
//
//  Unified expat center combining all expat features in one optimized interface
//

import SwiftUI
import Combine

struct UnifiedExpatCenterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localizationService = LocalizationService.shared
    @StateObject private var checklistService = ChecklistService.shared
    @StateObject private var expatManager = ExpatDataManager()

    @State private var selectedTab = 0
    @State private var showOnboarding = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                ExpatTabBar(selectedTab: $selectedTab)

                // Tab Content
                TabView(selection: $selectedTab) {
                    // Dashboard Tab
                    ExpatDashboardView(
                        checklistService: checklistService,
                        expatManager: expatManager,
                        showOnboarding: $showOnboarding
                    )
                    .tag(0)

                    // Documents Tab
                    IntegratedDocumentPrepView(expatManager: expatManager)
                        .tag(1)

                    // Calculator Tab
                    IntegratedTaxCalculatorView(expatManager: expatManager)
                        .tag(2)

                    // Resources Tab
                    ExpatResourcesView(expatManager: expatManager)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(tabTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showOnboarding = true
                        } label: {
                            Label("Show Tutorial", systemImage: "questionmark.circle")
                        }

                        Button {
                            checklistService.resetChecklist()
                        } label: {
                            Label("Reset Progress", systemImage: "arrow.counterclockwise")
                        }

                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Close", systemImage: "xmark")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                ExpatOnboardingView()
            }
        }
    }

    private var tabTitle: String {
        switch selectedTab {
        case 0: return "Expat Center"
        case 1: return "Documents"
        case 2: return "Tax Calculator"
        case 3: return "Resources"
        default: return "Expat Center"
        }
    }
}

// MARK: - Expat Data Manager
class ExpatDataManager: ObservableObject {
    @Published var userProfile = ExpatUserProfile()
    @Published var documentProgress: [DocumentCategory: Double] = [:]
    @Published var calculatorHistory: [TaxCalculation] = []
    @Published var savedResources: [ExpatResource] = []

    struct ExpatUserProfile {
        var canton: String = "ZH"
        var arrivalYear: Int = Calendar.current.component(.year, from: Date())
        var hasSwissSpouse: Bool = false
        var hasChildren: Bool = false
        var numberOfChildren: Int = 0
        var employmentType: String = "employed" // employed, self-employed, mixed
    }

    enum DocumentCategory: String, CaseIterable {
        case personal = "Personal"
        case income = "Income"
        case deductions = "Deductions"
        case wealth = "Wealth & Assets"
    }

    struct TaxCalculation: Identifiable {
        let id = UUID()
        let date: Date
        let income: Double
        let canton: String
        let estimatedTax: Double
        let effectiveRate: Double
    }

    struct ExpatResource: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let url: String?
        let type: ResourceType

        enum ResourceType {
            case guide, official, treaty, tool
        }
    }
}

// MARK: - Custom Tab Bar
struct ExpatTabBar: View {
    @Binding var selectedTab: Int

    let tabs = [
        (icon: "house.fill", title: "Dashboard"),
        (icon: "doc.text.fill", title: "Documents"),
        (icon: "function", title: "Calculator"),
        (icon: "book.fill", title: "Resources")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == index ? Color(red: 227/255, green: 30/255, blue: 36/255) : .gray)

                        Text(tabs[index].title)
                            .font(.caption2)
                            .foregroundColor(selectedTab == index ? Color(red: 227/255, green: 30/255, blue: 36/255) : .gray)

                        // Selection Indicator
                        Rectangle()
                            .fill(selectedTab == index ? Color(red: 227/255, green: 30/255, blue: 36/255) : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

// MARK: - Dashboard View
struct ExpatDashboardView: View {
    @ObservedObject var checklistService: ChecklistService
    @ObservedObject var expatManager: ExpatDataManager
    @Binding var showOnboarding: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome Card with Progress
                DashboardWelcomeCard(
                    checklistService: checklistService,
                    showOnboarding: $showOnboarding
                )

                // Quick Stats
                DashboardStatsGrid(expatManager: expatManager)

                // Important Dates Timeline
                DashboardTimelineCard()

                // Recent Activity
                DashboardActivityCard(expatManager: expatManager)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Dashboard Components
struct DashboardWelcomeCard: View {
    @ObservedObject var checklistService: ChecklistService
    @Binding var showOnboarding: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to Your\nExpat Tax Center")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(checklistService.checkedCount) of \(checklistService.totalItems) tasks completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                CircularProgressIndicator(
                    progress: checklistService.completionPercentage,
                    size: 80
                )
            }

            if !checklistService.isComplete {
                Button {
                    showOnboarding = true
                } label: {
                    HStack {
                        Text("Continue Setup")
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 227/255, green: 30/255, blue: 36/255))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct DashboardStatsGrid: View {
    @ObservedObject var expatManager: ExpatDataManager

    var body: some View {
        LazyVGrid(columns: [GridItem(), GridItem()], spacing: 12) {
            StatCard(
                icon: "calendar",
                value: "Mar 31",
                label: "Filing Deadline",
                color: .orange
            )

            StatCard(
                icon: "doc.text",
                value: "\(expatManager.documentProgress.count)",
                label: "Documents",
                color: .blue
            )

            StatCard(
                icon: "map",
                value: expatManager.userProfile.canton,
                label: "Canton",
                color: .green
            )

            StatCard(
                icon: "clock",
                value: "\(2025 - expatManager.userProfile.arrivalYear)y",
                label: "In Switzerland",
                color: .purple
            )
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DashboardTimelineCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tax Timeline 2025", systemImage: "calendar")
                .font(.headline)

            VStack(spacing: 0) {
                TimelineRow(
                    date: "Jan-Feb",
                    title: "Gather Documents",
                    isActive: true,
                    isCompleted: false
                )

                TimelineRow(
                    date: "Mar 31",
                    title: "Filing Deadline",
                    isActive: false,
                    isCompleted: false
                )

                TimelineRow(
                    date: "Jun 30",
                    title: "Extension Deadline",
                    isActive: false,
                    isCompleted: false
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct TimelineRow: View {
    let date: String
    let title: String
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isCompleted ? Color.green : (isActive ? Color(red: 227/255, green: 30/255, blue: 36/255) : Color.gray.opacity(0.3)))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(date)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(isActive ? .primary : .secondary)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isActive ? .primary : .secondary)
            }

            Spacer()

            if isActive {
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
            }
        }
        .padding(.vertical, 8)
    }
}

struct DashboardActivityCard: View {
    @ObservedObject var expatManager: ExpatDataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Activity", systemImage: "clock")
                .font(.headline)

            if expatManager.calculatorHistory.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("No recent activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(expatManager.calculatorHistory.prefix(3)) { calculation in
                    HStack {
                        Image(systemName: "function")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Tax Calculation")
                                .font(.subheadline)
                            Text("CHF \(Int(calculation.income)) • \(calculation.canton)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(calculation.effectiveRate))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Integrated Document Prep View
struct IntegratedDocumentPrepView: View {
    @ObservedObject var expatManager: ExpatDataManager
    @State private var selectedCategory: ExpatDataManager.DocumentCategory = .personal

    var body: some View {
        VStack(spacing: 0) {
            // Category Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExpatDataManager.DocumentCategory.allCases, id: \.self) { category in
                        DocumentCategoryChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))

            ScrollView {
                VStack(spacing: 16) {
                    // Progress Card
                    DocumentProgressCard(
                        category: selectedCategory,
                        progress: expatManager.documentProgress[selectedCategory] ?? 0
                    )

                    // Document List
                    DocumentListSection(category: selectedCategory)

                    // Tips
                    DocumentTipsCard(category: selectedCategory)
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct DocumentCategoryChip: View {
    let category: ExpatDataManager.DocumentCategory
    let isSelected: Bool
    let action: () -> Void

    var iconName: String {
        switch category {
        case .personal: return "person.text.rectangle"
        case .income: return "dollarsign.circle"
        case .deductions: return "minus.circle"
        case .wealth: return "building.2"
        }
    }

    var color: Color {
        switch category {
        case .personal: return .blue
        case .income: return .green
        case .deductions: return .orange
        case .wealth: return .purple
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? color : .gray)

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.15) : Color(UIColor.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct DocumentProgressCard: View {
    let category: ExpatDataManager.DocumentCategory
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(category.rawValue) Documents")
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: categoryColor))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    var categoryColor: Color {
        switch category {
        case .personal: return .blue
        case .income: return .green
        case .deductions: return .orange
        case .wealth: return .purple
        }
    }
}

struct DocumentListSection: View {
    let category: ExpatDataManager.DocumentCategory

    var documents: [(name: String, required: Bool)] {
        switch category {
        case .personal:
            return [
                ("Passport Copy", true),
                ("Residence Permit", true),
                ("Registration Certificate", true),
                ("Marriage Certificate", false)
            ]
        case .income:
            return [
                ("Salary Certificates", true),
                ("Bank Statements", true),
                ("Foreign Income Proof", false),
                ("Investment Income", false)
            ]
        case .deductions:
            return [
                ("Health Insurance", true),
                ("Pillar 3a Statements", false),
                ("Professional Expenses", false),
                ("Charitable Donations", false)
            ]
        case .wealth:
            return [
                ("Property Documents", false),
                ("Stock Portfolio", false),
                ("Crypto Holdings", false),
                ("Foreign Assets", false)
            ]
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(documents, id: \.name) { document in
                DocumentRow(
                    name: document.name,
                    required: document.required
                )
            }
        }
    }
}

struct DocumentRow: View {
    let name: String
    let required: Bool
    @State private var isChecked = false

    var body: some View {
        HStack {
            Button {
                isChecked.toggle()
            } label: {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .strikethrough(isChecked)

                Text(required ? "Required" : "Optional")
                    .font(.caption)
                    .foregroundColor(required ? .orange : .secondary)
            }

            Spacer()

            Button {
                // Upload action
            } label: {
                Image(systemName: "arrow.up.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct DocumentTipsCard: View {
    let category: ExpatDataManager.DocumentCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quick Tips", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 6) {
                TipRow(text: "Keep original documents safe")
                TipRow(text: "Make certified copies when needed")
                TipRow(text: "Translate foreign documents")
                TipRow(text: "Organize by category")
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .foregroundColor(.yellow)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Integrated Tax Calculator
struct IntegratedTaxCalculatorView: View {
    @ObservedObject var expatManager: ExpatDataManager
    @State private var income: String = ""
    @State private var showResult = false
    @State private var calculation: ExpatDataManager.TaxCalculation?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Calculator Header
                CalculatorHeaderCard()

                // Input Form
                CalculatorInputForm(
                    income: $income,
                    expatManager: expatManager
                )

                // Calculate Button
                Button {
                    performCalculation()
                } label: {
                    Label("Calculate Tax", systemImage: "function")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(red: 227/255, green: 30/255, blue: 36/255), Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .disabled(income.isEmpty)

                // Result
                if let calculation = calculation, showResult {
                    CalculatorResultCard(calculation: calculation)
                        .transition(.scale.combined(with: .opacity))
                }

                // History
                if !expatManager.calculatorHistory.isEmpty {
                    CalculatorHistoryCard(history: expatManager.calculatorHistory)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func performCalculation() {
        guard let incomeValue = Double(income) else { return }

        let baseTax = incomeValue * 0.15
        let cantonMultiplier: Double = {
            switch expatManager.userProfile.canton {
            case "GE": return 1.3
            case "VD": return 1.2
            case "BS": return 1.15
            default: return 1.0
            }
        }()

        var estimatedTax = baseTax * cantonMultiplier

        if expatManager.userProfile.hasSwissSpouse {
            estimatedTax *= 0.85
        }

        if expatManager.userProfile.hasChildren {
            estimatedTax -= Double(expatManager.userProfile.numberOfChildren) * 2000
        }

        let newCalculation = ExpatDataManager.TaxCalculation(
            date: Date(),
            income: incomeValue,
            canton: expatManager.userProfile.canton,
            estimatedTax: max(estimatedTax, 0),
            effectiveRate: (max(estimatedTax, 0) / incomeValue) * 100
        )

        calculation = newCalculation
        expatManager.calculatorHistory.insert(newCalculation, at: 0)

        withAnimation {
            showResult = true
        }
    }
}

struct CalculatorHeaderCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "function")
                .font(.largeTitle)
                .foregroundColor(.purple)

            Text("Swiss Tax Calculator")
                .font(.headline)

            Text("Get an estimate of your taxes based on your situation")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

struct CalculatorInputForm: View {
    @Binding var income: String
    @ObservedObject var expatManager: ExpatDataManager

    var body: some View {
        VStack(spacing: 16) {
            // Income Input
            VStack(alignment: .leading) {
                Label("Annual Income (CHF)", systemImage: "dollarsign.circle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("100000", text: $income)
                    .keyboardType(.numberPad)
                    .font(.title2)
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
            }

            // Canton Selector
            VStack(alignment: .leading) {
                Label("Canton", systemImage: "map")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Menu {
                    ForEach(["ZH", "GE", "VD", "BS", "BE", "AG"], id: \.self) { canton in
                        Button(canton) {
                            expatManager.userProfile.canton = canton
                        }
                    }
                } label: {
                    HStack {
                        Text(expatManager.userProfile.canton)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
                }
            }

            // Family Status
            VStack(spacing: 12) {
                Toggle("Swiss Spouse", isOn: $expatManager.userProfile.hasSwissSpouse)
                Toggle("Children", isOn: $expatManager.userProfile.hasChildren)

                if expatManager.userProfile.hasChildren {
                    Stepper("Number: \(expatManager.userProfile.numberOfChildren)",
                           value: $expatManager.userProfile.numberOfChildren,
                           in: 0...10)
                        .padding(.leading)
                }
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct CalculatorResultCard: View {
    let calculation: ExpatDataManager.TaxCalculation

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.green)
                Text("Tax Estimation")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                ResultRow(
                    label: "Gross Income",
                    value: "CHF \(Int(calculation.income).formatted())",
                    color: .primary
                )

                ResultRow(
                    label: "Estimated Tax",
                    value: "CHF \(Int(calculation.estimatedTax).formatted())",
                    color: .orange
                )

                ResultRow(
                    label: "Net Income",
                    value: "CHF \(Int(calculation.income - calculation.estimatedTax).formatted())",
                    color: .green
                )

                Divider()

                HStack {
                    Text("Effective Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(calculation.effectiveRate))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct CalculatorHistoryCard: View {
    let history: [ExpatDataManager.TaxCalculation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Calculations", systemImage: "clock")
                .font(.headline)

            ForEach(history.prefix(3)) { calc in
                HStack {
                    VStack(alignment: .leading) {
                        Text("CHF \(Int(calc.income))")
                            .font(.subheadline)
                        Text(calc.canton)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(Int(calc.effectiveRate))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(6)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Resources View
struct ExpatResourcesView: View {
    @ObservedObject var expatManager: ExpatDataManager

    let resources = [
        (title: "Swiss Tax Guide", subtitle: "Complete expat tax guide", icon: "book.fill", isExternal: false),
        (title: "Official Tax Portal", subtitle: "Federal tax administration", icon: "globe", isExternal: true),
        (title: "Tax Treaties", subtitle: "Double taxation agreements", icon: "doc.text", isExternal: false),
        (title: "Canton Calculator", subtitle: "Compare canton rates", icon: "map", isExternal: false),
        (title: "Expert Directory", subtitle: "Find tax advisors", icon: "person.2", isExternal: true)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Featured Resource
                FeaturedResourceCard()

                // Resource Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Resources")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(resources, id: \.title) { resource in
                        ResourceItemRow(
                            title: resource.title,
                            subtitle: resource.subtitle,
                            icon: resource.icon,
                            isExternal: resource.isExternal
                        )
                    }
                }

                // FAQ Section
                FAQSection()
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct FeaturedResourceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Featured")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
            }

            Text("2025 Tax Changes for Expats")
                .font(.headline)

            Text("Important updates to Swiss tax law affecting international residents")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                // Open resource
            } label: {
                Text("Learn More")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ResourceItemRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isExternal: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: isExternal ? "arrow.up.right.square" : "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct FAQSection: View {
    @State private var expandedFAQ: Int? = nil

    let faqs = [
        (q: "When is the tax filing deadline?", a: "March 31st for most cantons, with possible extensions"),
        (q: "Do I pay taxes on worldwide income?", a: "Yes, Switzerland taxes worldwide income for residents"),
        (q: "Can I deduct foreign taxes paid?", a: "Yes, through tax treaties to avoid double taxation")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequently Asked Questions")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(0..<faqs.count, id: \.self) { index in
                    ExpatFAQRow(
                        question: faqs[index].q,
                        answer: faqs[index].a,
                        isExpanded: expandedFAQ == index
                    ) {
                        withAnimation {
                            expandedFAQ = expandedFAQ == index ? nil : index
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

struct ExpatFAQRow: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if isExpanded {
                    Text(answer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Circular Progress Indicator
struct CircularProgressIndicator: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 227/255, green: 30/255, blue: 36/255), Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    UnifiedExpatCenterView()
}