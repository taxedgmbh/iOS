//
//  CategoryConfiguration.swift
//  TaxedGmbH_IOS
//
//  Manages user's selected tax categories
//

import SwiftUI
import Combine

// MARK: - All Available Tax Categories
enum TaxCategoryType: String, CaseIterable, Codable {
    // Income Categories
    case salary = "salary"
    case bonus = "bonus"
    case freelance = "freelance"
    case investment = "investment"
    case rental = "rental"
    case pension = "pension"
    case foreignIncome = "foreign_income"

    // Deduction Categories
    case mortgage = "mortgage"
    case donations = "donations"
    case education = "education"
    case medical = "medical"
    case insurancePremiums = "insurance_premiums"
    case childcare = "childcare"
    case homeOffice = "home_office"
    case travelExpenses = "travel_expenses"

    // Asset Categories
    case property = "property"
    case stocks = "stocks"
    case crypto = "crypto"
    case foreignWealth = "foreign_wealth"
    case savings = "savings"
    case insuranceSurrenderValue = "insurance_surrender_value"

    // Swiss-specific
    case pillar2 = "pillar_2"
    case pillar3a = "pillar_3a"
    case militaryService = "military_service"
    case taxTreaty = "tax_treaty"

    // Other
    case other = "other"

    var displayName: String {
        switch self {
        case .salary: return "category.salary".localized
        case .bonus: return "category.bonus".localized
        case .freelance: return "category.freelance".localized
        case .investment: return "category.investment".localized
        case .rental: return "category.rental".localized
        case .pension: return "category.pension".localized
        case .foreignIncome: return "category.foreign_income".localized
        case .mortgage: return "category.mortgage".localized
        case .donations: return "category.donations".localized
        case .education: return "category.education".localized
        case .medical: return "category.medical".localized
        case .insurancePremiums: return "category.insurance_premiums".localized
        case .childcare: return "category.childcare".localized
        case .homeOffice: return "category.home_office".localized
        case .travelExpenses: return "category.travel_expenses".localized
        case .property: return "category.property".localized
        case .stocks: return "category.stocks".localized
        case .crypto: return "category.crypto".localized
        case .foreignWealth: return "category.foreign_wealth".localized
        case .savings: return "category.savings".localized
        case .insuranceSurrenderValue: return "category.insurance_surrender_value".localized
        case .pillar2: return "category.pillar_2".localized
        case .pillar3a: return "category.pillar_3a".localized
        case .militaryService: return "category.military_service".localized
        case .taxTreaty: return "category.tax_treaty".localized
        case .other: return "category.other".localized
        }
    }

    var icon: String {
        switch self {
        case .salary: return "banknote"
        case .bonus: return "gift"
        case .freelance: return "laptopcomputer"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .rental: return "house.fill"
        case .pension: return "person.crop.circle.badge.clock"
        case .foreignIncome: return "globe.europe.africa.fill"
        case .mortgage: return "house.lodge"
        case .donations: return "heart.fill"
        case .education: return "graduationcap.fill"
        case .medical: return "cross.case.fill"
        case .insurancePremiums: return "shield.fill"
        case .childcare: return "figure.2.and.child.holdinghands"
        case .homeOffice: return "house.and.flag"
        case .travelExpenses: return "car.fill"
        case .property: return "building.2.fill"
        case .stocks: return "chart.line.uptrend.xyaxis.circle.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .foreignWealth: return "globe.americas.fill"
        case .savings: return "banknote.fill"
        case .insuranceSurrenderValue: return "banknote.fill"
        case .pillar2: return "building.columns.fill"
        case .pillar3a: return "lock.shield.fill"
        case .militaryService: return "shield.lefthalf.filled"
        case .taxTreaty: return "doc.text.below.ecg.fill"
        case .other: return "doc.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .salary, .bonus, .freelance, .investment, .rental, .pension, .foreignIncome:
            return .green
        case .mortgage, .donations, .education, .medical, .insurancePremiums, .childcare, .homeOffice, .travelExpenses:
            return .blue
        case .property, .stocks, .crypto, .foreignWealth, .savings, .insuranceSurrenderValue:
            return .orange
        case .pillar2, .pillar3a:
            return .purple
        case .militaryService, .taxTreaty:
            return .indigo
        case .other:
            return .gray
        }
    }

    var categoryGroup: CategoryGroup {
        switch self {
        case .salary, .bonus, .freelance, .investment, .rental, .pension, .foreignIncome:
            return .income
        case .mortgage, .donations, .education, .medical, .insurancePremiums, .childcare, .homeOffice, .travelExpenses:
            return .deductions
        case .property, .stocks, .crypto, .foreignWealth, .savings, .insuranceSurrenderValue:
            return .assets
        case .pillar2, .pillar3a, .militaryService, .taxTreaty:
            return .swissSpecific
        case .other:
            return .swissSpecific
        }
    }
}

// MARK: - Category Groups
enum CategoryGroup: String, CaseIterable {
    case income = "Income"
    case deductions = "Deductions"
    case assets = "Assets"
    case swissSpecific = "Swiss Specific"

    var displayName: String {
        switch self {
        case .income: return "group.income".localized
        case .deductions: return "group.deductions".localized
        case .assets: return "group.assets".localized
        case .swissSpecific: return "group.swiss_specific".localized
        }
    }

    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .deductions: return "minus.circle.fill"
        case .assets: return "building.2.crop.circle.fill"
        case .swissSpecific: return "flag.fill"
        }
    }
}

// MARK: - Category Configuration Model
class CategoryConfigurationModel: ObservableObject {
    @Published var selectedCategories: Set<TaxCategoryType> {
        didSet {
            saveSelectedCategories()
        }
    }

    @Published var isEditMode: Bool = false

    private let userDefaultsKey = "selectedTaxCategories"

    // Default categories for new users
    private let defaultCategories: Set<TaxCategoryType> = [
        .salary,
        .insurancePremiums,
        .pillar3a,
        .pension,
        .mortgage,
        .foreignIncome,
        .other
    ]

    init() {
        // Load saved categories or use defaults
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(Set<TaxCategoryType>.self, from: savedData) {
            self.selectedCategories = decoded
        } else {
            self.selectedCategories = defaultCategories
        }
    }

    private func saveSelectedCategories() {
        if let encoded = try? JSONEncoder().encode(selectedCategories) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func toggleCategory(_ category: TaxCategoryType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }
    }

    func resetToDefaults() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedCategories = defaultCategories
        }
    }

    func selectAll() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedCategories = Set(TaxCategoryType.allCases)
        }
    }

    func clearAll() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedCategories.removeAll()
        }
    }

    var selectedCategoriesByGroup: [CategoryGroup: [TaxCategoryType]] {
        Dictionary(grouping: Array(selectedCategories).sorted { $0.displayName < $1.displayName },
                  by: { $0.categoryGroup })
    }

    var availableCategoriesByGroup: [CategoryGroup: [TaxCategoryType]] {
        Dictionary(grouping: TaxCategoryType.allCases.filter { !selectedCategories.contains($0) },
                  by: { $0.categoryGroup })
    }
}