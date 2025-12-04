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
    case secondarySelfEmployment = "secondary_self_employment"
    case investment = "investment"
    case rental = "rental"
    case pension = "pension"
    case pensionFundBenefits = "pension_fund_benefits"
    case otherPensions = "other_pensions"
    case foreignIncome = "foreign_income"
    case stockOptions = "stock_options"
    case boardCompensation = "board_compensation"
    case unemploymentBenefits = "unemployment_benefits"
    case alimony = "alimony"
    case childAllowance = "child_allowance"
    case financialSupport = "financial_support"
    case capitalSettlementFederal = "capital_settlement_federal"
    case capitalSettlementState = "capital_settlement_state"
    case lotteryWinnings = "lottery_winnings"
    case withholdingTax = "withholding_tax"

    // Deduction Categories
    case mortgage = "mortgage"
    case mortgageInterest = "mortgage_interest"
    case loanInterest = "loan_interest"
    case donations = "donations"
    case politicalDonations = "political_donations"
    case education = "education"
    case educationExpenses = "education_expenses"
    case medical = "medical"
    case healthInsurance = "health_insurance"
    case insurancePremiums = "insurance_premiums"
    case childcare = "childcare"
    case homeOffice = "home_office"
    case travelExpenses = "travel_expenses"
    case professionalExpenses = "professional_expenses"
    case professionalAssociationFees = "professional_association_fees"
    case supportNeedyPersons = "support_needy_persons"
    case voluntaryAnnuities = "voluntary_annuities"
    case socialSecurity = "social_security"
    case spousalSupport = "spousal_support"
    case pillar2Buyback = "pillar_2_buyback"
    case pillar3Buyback = "pillar_3_buyback"
    case specialDeductions = "special_deductions"

    // Asset Categories
    case property = "property"
    case realEstate = "real_estate"
    case realEstateTaxValue = "real_estate_tax_value"
    case stocks = "stocks"
    case securities = "securities"
    case shareholdings = "shareholdings"
    case crypto = "crypto"
    case foreignWealth = "foreign_wealth"
    case savings = "savings"
    case bankAccounts = "bank_accounts"
    case lifeInsurance = "life_insurance"
    case insuranceSurrenderValue = "insurance_surrender_value"
    case vehicles = "vehicles"
    case vehicle = "vehicle"
    case householdGoods = "household_goods"
    case otherAssets = "other_assets"
    case totalAssets = "total_assets"

    // Liability Categories
    case businessLoan = "business_loan"
    case personalLoan = "personal_loan"
    case carLoan = "car_loan"
    case studentLoan = "student_loan"
    case loanDebt = "loan_debt"
    case creditCard = "credit_card"
    case securitiesDebt = "securities_debt"
    case privateLoan = "private_loan"
    case otherLiabilities = "other_liabilities"
    case totalLiabilities = "total_liabilities"

    // Swiss-specific
    case pillar2 = "pillar_2"
    case pillar3a = "pillar_3a"
    case militaryService = "military_service"
    case taxTreaty = "tax_treaty"

    // Other
    case other = "other"

    var displayName: String {
        return "category.\(self.rawValue)".localized
    }

    var icon: String {
        switch self {
        // Income
        case .salary, .bonus: return "banknote"
        case .freelance, .secondarySelfEmployment: return "laptopcomputer"
        case .investment, .stockOptions: return "chart.line.uptrend.xyaxis"
        case .rental: return "house.fill"
        case .pension, .pensionFundBenefits, .otherPensions: return "person.crop.circle.badge.clock"
        case .foreignIncome: return "globe.europe.africa.fill"
        case .boardCompensation: return "briefcase.fill"
        case .unemploymentBenefits: return "figure.wave"
        case .alimony, .spousalSupport: return "figure.2"
        case .childAllowance: return "figure.and.child.holdinghands"
        case .financialSupport: return "dollarsign.circle"
        case .capitalSettlementFederal, .capitalSettlementState: return "banknote.fill"
        case .lotteryWinnings: return "ticket.fill"
        case .withholdingTax: return "percent"

        // Deductions
        case .mortgage, .mortgageInterest: return "house.lodge"
        case .loanInterest: return "creditcard"
        case .donations, .politicalDonations: return "heart.fill"
        case .education, .educationExpenses: return "graduationcap.fill"
        case .medical, .healthInsurance: return "cross.case.fill"
        case .insurancePremiums: return "shield.fill"
        case .childcare: return "figure.2.and.child.holdinghands"
        case .homeOffice: return "house.and.flag"
        case .travelExpenses, .professionalExpenses: return "car.fill"
        case .professionalAssociationFees: return "person.3.fill"
        case .supportNeedyPersons: return "hands.sparkles.fill"
        case .voluntaryAnnuities: return "calendar.badge.clock"
        case .socialSecurity: return "shield.checkered"
        case .pillar2Buyback, .pillar3Buyback: return "arrow.up.circle.fill"
        case .specialDeductions: return "star.fill"

        // Assets
        case .property, .realEstate, .realEstateTaxValue: return "building.2.fill"
        case .stocks, .securities, .shareholdings: return "chart.line.uptrend.xyaxis.circle.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .foreignWealth: return "globe.americas.fill"
        case .savings, .bankAccounts: return "banknote.fill"
        case .lifeInsurance, .insuranceSurrenderValue: return "shield.lefthalf.filled"
        case .vehicles, .vehicle: return "car.2.fill"
        case .householdGoods: return "house.fill"
        case .otherAssets, .totalAssets: return "folder.fill"

        // Liabilities
        case .businessLoan, .personalLoan, .carLoan, .studentLoan, .loanDebt, .privateLoan: return "creditcard.fill"
        case .creditCard: return "creditcard.and.123"
        case .securitiesDebt: return "chart.line.downtrend.xyaxis"
        case .otherLiabilities, .totalLiabilities: return "exclamationmark.triangle.fill"

        // Swiss-specific
        case .pillar2: return "building.columns.fill"
        case .pillar3a: return "lock.shield.fill"
        case .militaryService: return "shield.lefthalf.filled"
        case .taxTreaty: return "doc.text.below.ecg.fill"

        // Other
        case .other: return "doc.circle.fill"
        }
    }

    var color: Color {
        switch self {
        // Income - Green
        case .salary, .bonus, .freelance, .secondarySelfEmployment, .investment, .rental, .pension,
             .pensionFundBenefits, .otherPensions, .foreignIncome, .stockOptions, .boardCompensation,
             .unemploymentBenefits, .alimony, .childAllowance, .financialSupport,
             .capitalSettlementFederal, .capitalSettlementState, .lotteryWinnings, .withholdingTax:
            return .green

        // Deductions - Blue
        case .mortgage, .mortgageInterest, .loanInterest, .donations, .politicalDonations, .education,
             .educationExpenses, .medical, .healthInsurance, .insurancePremiums, .childcare, .homeOffice,
             .travelExpenses, .professionalExpenses, .professionalAssociationFees, .supportNeedyPersons,
             .voluntaryAnnuities, .socialSecurity, .spousalSupport, .pillar2Buyback, .pillar3Buyback,
             .specialDeductions:
            return .blue

        // Assets - Orange
        case .property, .realEstate, .realEstateTaxValue, .stocks, .securities, .shareholdings, .crypto,
             .foreignWealth, .savings, .bankAccounts, .lifeInsurance, .insuranceSurrenderValue,
             .vehicles, .vehicle, .householdGoods, .otherAssets, .totalAssets:
            return .orange

        // Liabilities - Red
        case .businessLoan, .personalLoan, .carLoan, .studentLoan, .loanDebt, .creditCard,
             .securitiesDebt, .privateLoan, .otherLiabilities, .totalLiabilities:
            return .red

        // Swiss-specific - Purple/Indigo
        case .pillar2, .pillar3a:
            return .purple
        case .militaryService, .taxTreaty:
            return .indigo

        // Other - Gray
        case .other:
            return .gray
        }
    }

    var categoryGroup: CategoryGroup {
        switch self {
        // Income
        case .salary, .bonus, .freelance, .secondarySelfEmployment, .investment, .rental, .pension,
             .pensionFundBenefits, .otherPensions, .foreignIncome, .stockOptions, .boardCompensation,
             .unemploymentBenefits, .alimony, .childAllowance, .financialSupport,
             .capitalSettlementFederal, .capitalSettlementState, .lotteryWinnings, .withholdingTax:
            return .income

        // Deductions
        case .mortgage, .mortgageInterest, .loanInterest, .donations, .politicalDonations, .education,
             .educationExpenses, .medical, .healthInsurance, .insurancePremiums, .childcare, .homeOffice,
             .travelExpenses, .professionalExpenses, .professionalAssociationFees, .supportNeedyPersons,
             .voluntaryAnnuities, .socialSecurity, .spousalSupport, .pillar2Buyback, .pillar3Buyback,
             .specialDeductions:
            return .deductions

        // Assets
        case .property, .realEstate, .realEstateTaxValue, .stocks, .securities, .shareholdings, .crypto,
             .foreignWealth, .savings, .bankAccounts, .lifeInsurance, .insuranceSurrenderValue,
             .vehicles, .vehicle, .householdGoods, .otherAssets, .totalAssets:
            return .assets

        // Liabilities
        case .businessLoan, .personalLoan, .carLoan, .studentLoan, .loanDebt, .creditCard,
             .securitiesDebt, .privateLoan, .otherLiabilities, .totalLiabilities:
            return .liabilities

        // Swiss-specific
        case .pillar2, .pillar3a, .militaryService, .taxTreaty:
            return .swissSpecific

        // Other
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
    case liabilities = "Liabilities"
    case swissSpecific = "Swiss Specific"

    var displayName: String {
        switch self {
        case .income: return "group.income".localized
        case .deductions: return "group.deductions".localized
        case .assets: return "group.assets".localized
        case .liabilities: return "group.liabilities".localized
        case .swissSpecific: return "group.swiss_specific".localized
        }
    }

    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .deductions: return "minus.circle.fill"
        case .assets: return "building.2.crop.circle.fill"
        case .liabilities: return "creditcard.circle.fill"
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