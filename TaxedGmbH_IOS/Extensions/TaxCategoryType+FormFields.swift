//
//  TaxCategoryType+FormFields.swift
//  TaxedGmbH_IOS
//
//  Extension to TaxCategoryType providing canton-specific tax form field mappings
//  Centralizes all tax categorization, eliminating fragmentation across the codebase
//

import Foundation

// MARK: - Form Field Mapping Structure

struct TaxFormFieldMapping {
    let fieldNumber: String        // Raw field number: "1.1", "181", "8"
    let labelNumber: String        // Display format: "Ziffer 1.1", "Code 181", "Feld 8"
    let mainCategory: TaxFormMainCategory
    let formCategory: TaxFormCategory
    let subcategory: String?

    init(fieldNumber: String, labelPrefix: String, mainCategory: TaxFormMainCategory, formCategory: TaxFormCategory, subcategory: String? = nil) {
        self.fieldNumber = fieldNumber
        self.labelNumber = "\(labelPrefix) \(fieldNumber)"
        self.mainCategory = mainCategory
        self.formCategory = formCategory
        self.subcategory = subcategory
    }
}

// MARK: - TaxCategoryType Extension

extension TaxCategoryType {

    // MARK: - Canton-Specific Field Numbers

    /// Get the raw field number for a specific canton and person
    /// - Parameters:
    ///   - canton: Canton code ("ZH", "ZG", "BS")
    ///   - person: Taxpayer person number (1 or 2) for joint filings, defaults to 1
    /// - Returns: Field number string or nil if not applicable
    func getFieldNumber(canton: String, person: Int = 1) -> String? {
        return getFieldMapping(canton: canton, person: person)?.fieldNumber
    }

    /// Get the formatted label number for display on cover sheets
    /// - Parameters:
    ///   - canton: Canton code ("ZH", "ZG", "BS")
    ///   - person: Taxpayer person number (1 or 2) for joint filings, defaults to 1
    /// - Returns: Formatted label (e.g., "Ziffer 1.1") or nil if not applicable
    func getLabelNumber(canton: String, person: Int = 1) -> String? {
        return getFieldMapping(canton: canton, person: person)?.labelNumber
    }

    /// Get complete field mapping for a canton and person
    /// - Parameters:
    ///   - canton: Canton code ("ZH", "ZG", "BS")
    ///   - person: Taxpayer person number (1 or 2) for joint filings, defaults to 1
    /// - Returns: TaxFormFieldMapping or nil if not applicable
    func getFieldMapping(canton: String, person: Int = 1) -> TaxFormFieldMapping? {
        switch canton.uppercased() {
        case "ZH":
            return getZurichMapping(person: person)
        case "ZG":
            return getZugMapping(person: person)
        case "BS":
            return getBaselMapping(person: person)
        default:
            return nil
        }
    }

    // MARK: - Official Tax Form Categories

    /// Get the main category from official Swiss tax forms
    var mainFormCategory: TaxFormMainCategory {
        switch self {
        // Income
        case .salary, .bonus, .freelance, .secondarySelfEmployment, .investment, .rental, .pension, .pensionFundBenefits, .otherPensions, .foreignIncome, .unemploymentBenefits, .financialSupport, .childAllowance, .stockOptions, .boardCompensation, .lotteryWinnings, .capitalSettlementFederal, .capitalSettlementState, .spousalSupport:
            return .einkommen

        // Deductions
        case .mortgageInterest, .loanInterest, .donations, .education, .medical, .insurancePremiums, .childcare, .homeOffice, .travelExpenses, .healthInsurance, .professionalExpenses, .educationExpenses, .alimony, .supportNeedyPersons, .voluntaryAnnuities, .politicalDonations, .professionalAssociationFees, .pillar2Buyback, .pillar3Buyback, .specialDeductions, .socialSecurity, .withholdingTax:
            return .abzuege

        // Wealth/Assets
        case .property, .bankAccounts, .stocks, .crypto, .foreignWealth, .savings, .insuranceSurrenderValue, .lifeInsurance, .householdGoods, .vehicles, .securities, .realEstate, .realEstateTaxValue, .otherAssets, .totalAssets, .shareholdings, .vehicle:
            return .vermoegen

        // Liabilities
        case .mortgage, .personalLoan, .creditCard, .businessLoan, .carLoan, .studentLoan, .otherLiabilities, .loanDebt, .totalLiabilities, .securitiesDebt, .privateLoan:
            return .schulden

        // Swiss-specific (treated as personal/special)
        case .pillar2, .pillar3a, .militaryService, .taxTreaty, .other:
            return .persoenliches
        }
    }

    /// Get the specific form category (more granular than main category)
    var formCategory: TaxFormCategory {
        switch self {
        // Income - Employment
        case .salary, .bonus, .unemploymentBenefits, .childAllowance, .stockOptions, .boardCompensation:
            return .unselbstaendigeErwerbstaetigkeit

        // Income - Self-Employment
        case .freelance, .secondarySelfEmployment:
            return .selbstaendigeErwerbstaetigkeit

        // Income - Investments
        case .investment:
            return .wertschriftenUndGuthaben

        // Income - Property
        case .rental:
            return .liegenschaften

        // Income - Pension
        case .pension, .pensionFundBenefits, .otherPensions, .foreignIncome:
            return .vorsorge

        // Income - Other income
        case .financialSupport, .lotteryWinnings, .capitalSettlementFederal, .capitalSettlementState, .spousalSupport:
            return .uebrigeEinkuenfte

        // Deductions - Professional expenses
        case .professionalExpenses, .travelExpenses, .homeOffice, .professionalAssociationFees:
            return .berufsauslagen

        // Deductions - Insurance
        case .insurancePremiums, .healthInsurance:
            return .versicherungen

        // Deductions - Education
        case .education, .educationExpenses:
            return .weiterbildung

        // Deductions - Support payments
        case .alimony, .supportNeedyPersons, .voluntaryAnnuities:
            return .unterhalt

        // Deductions - Donations
        case .donations, .politicalDonations:
            return .spenden

        // Deductions - Childcare
        case .childcare:
            return .kinderbetreuung

        // Deductions - Interest
        case .mortgageInterest, .loanInterest:
            return .schuldzinsen

        // Deductions - Pillar buybacks and special
        case .pillar2Buyback, .pillar3Buyback, .specialDeductions:
            return .vorsorge

        // Deductions - Other
        case .medical, .socialSecurity, .withholdingTax:
            return .versicherungen

        // Wealth - Bank accounts
        case .bankAccounts, .savings:
            return .bankguthaben

        // Wealth - Securities
        case .stocks, .securities, .crypto, .shareholdings:
            return .wertpapiere

        // Wealth - Real estate
        case .property, .realEstate, .realEstateTaxValue:
            return .immobilien

        // Wealth - Vehicles
        case .vehicles, .vehicle:
            return .fahrzeuge

        // Wealth - Other
        case .foreignWealth, .insuranceSurrenderValue, .lifeInsurance, .householdGoods, .otherAssets, .totalAssets:
            return .uebrigesVermoegen

        // Liabilities - Mortgages
        case .mortgage:
            return .hypotheken

        // Liabilities - Loans
        case .personalLoan, .businessLoan, .carLoan, .studentLoan, .loanDebt, .securitiesDebt, .privateLoan:
            return .kredite

        // Liabilities - Other
        case .creditCard, .otherLiabilities, .totalLiabilities:
            return .uebrigeSchulden

        // Swiss-specific
        case .pillar2, .pillar3a, .militaryService, .taxTreaty, .other:
            return .vorsorge
        }
    }

    // MARK: - Private Canton Mappings

    private func getZurichMapping(person: Int = 1) -> TaxFormFieldMapping? {
        switch self {
        // INCOME - Unselbständige Erwerbstätigkeit (Employment Income)
        case .salary:
            let index = person == 2 ? "101" : "100"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Haupterwerb \(personLabel)")
        case .bonus:
            let index = person == 2 ? "103" : "102"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Nebenerwerb \(personLabel)")
        case .stockOptions:
            let index = person == 2 ? "101" : "100"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Included in gross salary")
        case .boardCompensation:
            let index = person == 2 ? "101" : "100"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Board fees in gross salary")

        // INCOME - Selbständige Erwerbstätigkeit (Self-Employment)
        case .freelance:
            let index = person == 2 ? "121" : "120"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .selbstaendigeErwerbstaetigkeit, subcategory: "Haupterwerb \(personLabel)")
        case .secondarySelfEmployment:
            let index = person == 2 ? "123" : "122"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .selbstaendigeErwerbstaetigkeit, subcategory: "Nebenerwerb \(personLabel)")

        // INCOME - Sozialversicherungen (Social Insurance)
        case .pension:
            let index = person == 2 ? "131" : "130"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .vorsorge, subcategory: "AHV/IV Renten \(personLabel)")
        case .unemploymentBenefits:
            return TaxFormFieldMapping(fieldNumber: "140", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Arbeitslosenentschädigung")
        case .childAllowance:
            return TaxFormFieldMapping(fieldNumber: "142", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Kinder- und Familienzulagen")

        // INCOME - Pension income (after AHV/IV)
        case .pensionFundBenefits:
            let index = person == 2 ? "135" : "134"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .vorsorge, subcategory: "BVG/Pensionskasse \(personLabel)")
        case .otherPensions:
            let index = person == 2 ? "137" : "136"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .vorsorge, subcategory: "Andere Renten \(personLabel)")

        // INCOME - Other benefits and support
        case .financialSupport:
            let index = person == 2 ? "143" : "141"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Unterstützung \(personLabel)")

        // INCOME - Wertschriftenertrag (Securities Income)
        case .investment:
            return TaxFormFieldMapping(fieldNumber: "150", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .wertschriftenUndGuthaben, subcategory: "Ertrag aus Wertschriften")
        case .lotteryWinnings:
            return TaxFormFieldMapping(fieldNumber: "151", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Lotteriegewinne")

        // INCOME - Capital settlements
        case .capitalSettlementFederal:
            let index = person == 2 ? "161" : "160"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Bundessteuer Kapitalabfindungen \(personLabel)")
        case .capitalSettlementState:
            return TaxFormFieldMapping(fieldNumber: "162", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Staatssteuer Kapitalabfindungen")

        // INCOME - Übrige Einkünfte (Other Income)
        case .foreignIncome:
            return TaxFormFieldMapping(fieldNumber: "163", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Weitere Einkünfte")
        case .spousalSupport:
            return TaxFormFieldMapping(fieldNumber: "164", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Unterhalt an Ehegatten")

        // INCOME - Real Estate
        case .rental:
            return TaxFormFieldMapping(fieldNumber: "188", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .liegenschaften, subcategory: "Nettoertrag aus Liegenschaften")

        // DEDUCTIONS - Professional Expenses
        case .professionalExpenses:
            let index = person == 2 ? "240" : "220"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Berufsauslagen \(personLabel)")
        case .travelExpenses:
            let index = person == 2 ? "240" : "220"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Included in professional expenses")
        case .homeOffice:
            let index = person == 2 ? "240" : "220"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Included in professional expenses")

        // DEDUCTIONS - Interest
        case .loanInterest, .mortgageInterest:
            return TaxFormFieldMapping(fieldNumber: "250", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .schuldzinsen)

        // DEDUCTIONS - Maintenance & Alimony
        case .alimony:
            return TaxFormFieldMapping(fieldNumber: "254", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .unterhalt, subcategory: "Unterhaltsbeiträge an Ehegatten")
        case .supportNeedyPersons:
            return TaxFormFieldMapping(fieldNumber: "255", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .unterhalt, subcategory: "Unterstützung bedürftiger Personen")
        case .voluntaryAnnuities:
            return TaxFormFieldMapping(fieldNumber: "256", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .unterhalt, subcategory: "Freiwillig überbundene Renten")

        // DEDUCTIONS - Pillar 3a
        case .pillar3a:
            let index = person == 2 ? "261" : "260"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Säule 3a \(personLabel)")
        case .pillar2:
            return TaxFormFieldMapping(fieldNumber: "280", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Beiträge 2. Säule")

        // DEDUCTIONS - Insurance
        case .healthInsurance, .insurancePremiums:
            return TaxFormFieldMapping(fieldNumber: "270", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Versicherungsprämien, Zinsen")

        // DEDUCTIONS - Education
        case .education, .educationExpenses:
            return TaxFormFieldMapping(fieldNumber: "292", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .weiterbildung, subcategory: "Berufsorientierte Aus- und Weiterbildung")

        // DEDUCTIONS - Medical
        case .medical:
            return TaxFormFieldMapping(fieldNumber: "320", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Krankheits- und Unfallkosten")

        // DEDUCTIONS - Donations
        case .donations:
            return TaxFormFieldMapping(fieldNumber: "324", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .spenden, subcategory: "Gemeinnützige Zuwendungen")
        case .politicalDonations:
            return TaxFormFieldMapping(fieldNumber: "310", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .spenden, subcategory: "Politische Parteien")

        // DEDUCTIONS - Professional association
        case .professionalAssociationFees:
            return TaxFormFieldMapping(fieldNumber: "350", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Mitgliederbeiträge Berufsverbände")

        // DEDUCTIONS - Pillar buybacks
        case .pillar2Buyback:
            return TaxFormFieldMapping(fieldNumber: "365", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Einkauf in 2. Säule")
        case .pillar3Buyback:
            return TaxFormFieldMapping(fieldNumber: "370", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Einkauf in 3. Säule")

        // DEDUCTIONS - Childcare
        case .childcare:
            return TaxFormFieldMapping(fieldNumber: "376", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .kinderbetreuung, subcategory: "Fremdbetreuete Kinder max. 25'000")

        // DEDUCTIONS - Special deductions
        case .specialDeductions:
            return TaxFormFieldMapping(fieldNumber: "390", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Sonderabzüge")

        // WEALTH - Securities & Bank Accounts
        case .securities, .stocks:
            return TaxFormFieldMapping(fieldNumber: "400", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .wertpapiere, subcategory: "Wertschriften und Guthaben")
        case .bankAccounts, .savings:
            return TaxFormFieldMapping(fieldNumber: "400", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .bankguthaben, subcategory: "Wertschriften und Guthaben")
        case .crypto:
            return TaxFormFieldMapping(fieldNumber: "400", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .wertpapiere, subcategory: "Included in securities")

        // WEALTH - Insurance
        case .insuranceSurrenderValue:
            return TaxFormFieldMapping(fieldNumber: "406", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Lebens- und Rentenversicherungen")
        case .lifeInsurance:
            return TaxFormFieldMapping(fieldNumber: "404", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Kapitalversicherungen")

        // WEALTH - Vehicles
        case .vehicle, .vehicles:
            return TaxFormFieldMapping(fieldNumber: "412", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .fahrzeuge, subcategory: "Motorfahrzeuge")

        // WEALTH - Household goods
        case .householdGoods:
            return TaxFormFieldMapping(fieldNumber: "414", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Hausrat und persönliche Gegenstände")

        // WEALTH - Real Estate
        case .property, .realEstate:
            return TaxFormFieldMapping(fieldNumber: "421", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .immobilien, subcategory: "Liegenschaften (Verkehrswert)")
        case .realEstateTaxValue:
            return TaxFormFieldMapping(fieldNumber: "422", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .immobilien, subcategory: "Liegenschaften Steuerwert")

        // WEALTH - Other Assets
        case .foreignWealth:
            return TaxFormFieldMapping(fieldNumber: "416", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Übrige Vermögenswerte")
        case .otherAssets:
            return TaxFormFieldMapping(fieldNumber: "430", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Übrige Vermögenswerte")
        case .totalAssets:
            return TaxFormFieldMapping(fieldNumber: "460", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Total Vermögen")
        case .shareholdings:
            return TaxFormFieldMapping(fieldNumber: "490", labelPrefix: "Ziffer", mainCategory: .vermoegen, formCategory: .wertpapiere, subcategory: "Beteiligungen (5% und mehr)")

        // LIABILITIES - Mortgages
        case .mortgage:
            return TaxFormFieldMapping(fieldNumber: "470", labelPrefix: "Ziffer", mainCategory: .schulden, formCategory: .hypotheken, subcategory: "Schulden")

        // LIABILITIES - Loans
        case .personalLoan, .businessLoan, .carLoan, .studentLoan, .loanDebt:
            return TaxFormFieldMapping(fieldNumber: "470", labelPrefix: "Ziffer", mainCategory: .schulden, formCategory: .kredite, subcategory: "Schulden")
        case .creditCard, .otherLiabilities:
            return TaxFormFieldMapping(fieldNumber: "470", labelPrefix: "Ziffer", mainCategory: .schulden, formCategory: .uebrigeSchulden, subcategory: "Schulden")

        // LIABILITIES - Total and specific debts
        case .totalLiabilities:
            return TaxFormFieldMapping(fieldNumber: "510", labelPrefix: "Ziffer", mainCategory: .schulden, formCategory: .uebrigeSchulden, subcategory: "Total Schulden")
        case .securitiesDebt:
            return TaxFormFieldMapping(fieldNumber: "516", labelPrefix: "Ziffer", mainCategory: .schulden, formCategory: .kredite, subcategory: "Schulden aus Wertpapierkauf")
        case .privateLoan:
            return TaxFormFieldMapping(fieldNumber: "519", labelPrefix: "Ziffer", mainCategory: .schulden, formCategory: .kredite, subcategory: "Privatdarlehen")

        // Swiss-specific & Other
        case .militaryService:
            return TaxFormFieldMapping(fieldNumber: "280", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Weitere Abzüge")
        case .taxTreaty:
            return TaxFormFieldMapping(fieldNumber: "396", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Ausländische Einkünfte")
        case .socialSecurity:
            return TaxFormFieldMapping(fieldNumber: "280", labelPrefix: "Ziffer", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "AHV/IV Beiträge")
        case .withholdingTax:
            return TaxFormFieldMapping(fieldNumber: "150", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .wertschriftenUndGuthaben, subcategory: "Subject to withholding")
        case .other:
            return TaxFormFieldMapping(fieldNumber: "163", labelPrefix: "Ziffer", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Weitere Einkünfte")
        }
    }

    private func getZugMapping(person: Int = 1) -> TaxFormFieldMapping? {
        switch self {
        // INCOME - Employment (6 indices: 100, 101, 105, 106, 110, 111)
        case .salary:
            let index = person == 2 ? "101" : "100"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Nettolohn \(personLabel)")
        case .bonus, .stockOptions, .boardCompensation:
            let index = person == 2 ? "111" : "110"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Weitere Gehaltsnebenleistungen \(personLabel)")

        // INCOME - Self-Employment (4 indices: 115, 116, 125, 126)
        case .freelance:
            let index = person == 2 ? "116" : "115"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .einkommen, formCategory: .selbstaendigeErwerbstaetigkeit, subcategory: "Selbständige Erwerbstätigkeit \(personLabel)")

        // INCOME - Social Insurance (12 indices: 130, 131, 135, 136, 140, 141, 145, 146, 150, 151, 155, 156)
        case .pension:
            let index = person == 2 ? "131" : "130"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .einkommen, formCategory: .vorsorge, subcategory: "AHV-/IV-Rente \(personLabel)")
        case .pensionFundBenefits, .otherPensions:
            let index = person == 2 ? "136" : "135"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .einkommen, formCategory: .vorsorge, subcategory: "Renten/Pensionen \(personLabel)")
        case .unemploymentBenefits:
            let index = person == 2 ? "151" : "150"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Arbeitslosentaggelder \(personLabel)")
        case .financialSupport, .childAllowance:
            let index = person == 2 ? "156" : "155"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Kinder-/Familienzulagen \(personLabel)")

        // INCOME - Securities (1 index: 160)
        case .investment, .stocks, .securities, .lotteryWinnings:
            return TaxFormFieldMapping(fieldNumber: "160", labelPrefix: "Code", mainCategory: .einkommen, formCategory: .wertschriftenUndGuthaben, subcategory: "Wertschriftenertrag/Guthaben/Lotteriegewinne")

        // INCOME - Other Income (4 indices: 170, 171, 173, 174)
        case .alimony, .spousalSupport:
            return TaxFormFieldMapping(fieldNumber: "170", labelPrefix: "Code", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Unterhaltsbeiträge Ehegatten/Partner")
        case .capitalSettlementFederal, .capitalSettlementState:
            return TaxFormFieldMapping(fieldNumber: "174", labelPrefix: "Code", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Kapitalabfindungen für wiederkehrende Leistungen")
        case .foreignIncome:
            return TaxFormFieldMapping(fieldNumber: "173", labelPrefix: "Code", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Weitere Einkünfte")

        // INCOME - Property (2 indices: 181, 183)
        case .rental, .realEstate, .property:
            return TaxFormFieldMapping(fieldNumber: "181", labelPrefix: "Code", mainCategory: .einkommen, formCategory: .liegenschaften, subcategory: "Ertrag/Nutzniessung private Liegenschaften")

        // DEDUCTIONS - Job Costs (2 indices: 201, 202)
        case .professionalExpenses, .travelExpenses:
            let index = person == 2 ? "202" : "201"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Berufsauslagen \(personLabel)")

        // DEDUCTIONS - Debt Interest (1 index: 205)
        case .loanInterest, .mortgageInterest:
            return TaxFormFieldMapping(fieldNumber: "205", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .schuldzinsen, subcategory: "Private Schuldzinsen")

        // DEDUCTIONS - Maintenance (2 indices: 210, 211)
        case .voluntaryAnnuities:
            return TaxFormFieldMapping(fieldNumber: "210", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .unterhalt, subcategory: "Unterhaltsbeiträge Ehegatten")
        case .supportNeedyPersons:
            return TaxFormFieldMapping(fieldNumber: "211", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .unterhalt, subcategory: "Unterhaltsbeiträge Kinder")

        // DEDUCTIONS - Pillar 3a (2 indices: 220, 221)
        case .pillar3a:
            let index = person == 2 ? "221" : "220"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Gebundene Vorsorge Säule 3a \(personLabel)")

        // DEDUCTIONS - Insurance (1 index: 230)
        case .insurancePremiums, .healthInsurance:
            return TaxFormFieldMapping(fieldNumber: "230", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Versicherungsprämien/Sparkapitalzinsen")

        // DEDUCTIONS - Further Deductions (9 indices: 240, 245, 246, 250, 251, 252, 253, 255, 257, 258)
        case .socialSecurity:
            return TaxFormFieldMapping(fieldNumber: "240", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "AHV-Beiträge/NBUV-Prämien")
        case .education, .educationExpenses:
            let index = person == 2 ? "246" : "245"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .abzuege, formCategory: .weiterbildung, subcategory: "Aus-/Weiterbildungskosten \(personLabel)")
        case .pillar2, .pillar2Buyback:
            let index = person == 2 ? "251" : "250"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Beiträge 2. Säule inkl. Einkauf \(personLabel)")
        case .politicalDonations:
            return TaxFormFieldMapping(fieldNumber: "252", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .spenden, subcategory: "Zuwendungen politische Parteien")
        case .childcare:
            return TaxFormFieldMapping(fieldNumber: "253", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .kinderbetreuung, subcategory: "Kinderdrittbetreuungskosten")
        case .medical:
            return TaxFormFieldMapping(fieldNumber: "257", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Behinderungsbedingte Kosten")

        // DEDUCTIONS - Dual Income (1 index: 260)
        case .homeOffice:
            return TaxFormFieldMapping(fieldNumber: "260", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Sonderabzug Erwerbstätigkeit beider Eheleute")

        // DEDUCTIONS - Donations (1 index: 296)
        case .donations:
            return TaxFormFieldMapping(fieldNumber: "296", labelPrefix: "Code", mainCategory: .abzuege, formCategory: .spenden, subcategory: "Gemeinnützige Zuwendungen")

        // ASSETS - Movable Assets (6 indices: 600, 601, 603, 604, 606, 416)
        case .bankAccounts, .savings:
            return TaxFormFieldMapping(fieldNumber: "600", labelPrefix: "Code", mainCategory: .vermoegen, formCategory: .bankguthaben, subcategory: "Wertschriften/Guthaben")
        case .crypto:
            return TaxFormFieldMapping(fieldNumber: "601", labelPrefix: "Code", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Bargeld/Gold/Edelmetalle")
        case .lifeInsurance, .insuranceSurrenderValue:
            return TaxFormFieldMapping(fieldNumber: "603", labelPrefix: "Code", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Lebensversicherungen")
        case .vehicles, .vehicle:
            return TaxFormFieldMapping(fieldNumber: "604", labelPrefix: "Code", mainCategory: .vermoegen, formCategory: .fahrzeuge, subcategory: "Motorfahrzeuge")
        case .otherAssets, .householdGoods, .foreignWealth:
            return TaxFormFieldMapping(fieldNumber: "606", labelPrefix: "Code", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Übrige Vermögenswerte")

        // ASSETS - Business Assets (4 indices: 620, 621, 622, 623)
        case .shareholdings:
            let index = person == 2 ? "623" : "622"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .vermoegen, formCategory: .wertpapiere, subcategory: "Vermögensanteile Personengesellschaften \(personLabel)")

        // LIABILITIES - Debts (3 indices: 640, 642, 643)
        case .mortgage, .personalLoan, .carLoan, .studentLoan, .loanDebt, .creditCard, .otherLiabilities:
            return TaxFormFieldMapping(fieldNumber: "640", labelPrefix: "Code", mainCategory: .schulden, formCategory: .hypotheken, subcategory: "Privatschulden")
        case .businessLoan:
            let index = person == 2 ? "643" : "642"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Code", mainCategory: .schulden, formCategory: .kredite, subcategory: "Geschäftsschulden \(personLabel)")

        // ZG-SPECIFIC INDICES - Documented as searchable strings
        // Additional ZG indices without direct category mappings:
        // "106" = Aus Haupterwerbstätigkeit (Nettolohn) Person 2 - variant
        // "112" = Angaben nicht steuerbare Einkünfte Person 1
        // "113" = Angaben nicht steuerbare Einkünfte Person 2
        // "126" = Personengesellschaft Person 2
        // "140" = Leibrenten (40%) Person 1
        // "141" = Leibrenten (40%) Person 2
        // "145" = Erwerbsausfallentschädigung Person 1
        // "146" = Erwerbsausfallentschädigung Person 2
        // "171" = Unterhaltsbeiträge für minderjährige Kinder
        // "183" = Wohnrecht
        // "190" = Total der Einkünfte
        // "211" = Unterhaltsbeiträge Kinder (mapped above)
        // "255" = Kosten Vermögensverwaltung
        // "258" = Weitere Abzüge
        // "280" = Total Abzüge
        // "285" = Total Einkünfte Übertrag
        // "286" = Total Abzüge Übertrag
        // "287" = Nettoeinkommen
        // "295" = Krankheits-/Unfallkosten
        // "299" = Reineinkommen
        // "400" = Abzug Eheleute/Partner Kanton
        // "401" = Abzug Eheleute/Partner Bund
        // "402" = Abzug übrige Steuerpflichtige
        // "403" = Kinderabzug
        // "403a" = Kinderabzug Zusatz
        // "404" = Kindereigenbetreuungsabzug
        // "405" = Unterstützungsabzug
        // "407" = Mietzinsabzug
        // "410" = Reduktion wirtschaftliche Doppelbelastung
        // "490" = Steuerbares Einkommen gesamt
        // "500-1" = Anteil Kanton Zug
        // "610" = Liegenschaften (mapped via .realEstate above)
        // "621" = Aktiven Geschäftsvermögen Person 2
        // "630" = Total Vermögenswerte
        // "650" = Total Schulden
        // "660" = Reinvermögen
        // "671" = Abzug Eheleute/Partner (steuerfreier Betrag)
        // "672" = Abzug übrige Steuerpflichtige (steuerfreier Betrag)
        // "673" = Abzug minderjährige Kinder (steuerfreier Betrag)
        // "690" = Steuerbares Gesamtvermögen
        // "700" = Steuerpflicht mehrere Kantone/Länder

        case .other:
            return TaxFormFieldMapping(fieldNumber: "173", labelPrefix: "Code", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Weitere Einkünfte / ZG calculation fields")

        default:
            return nil
        }
    }

    private func getBaselMapping(person: Int = 1) -> TaxFormFieldMapping? {
        switch self {
        // INCOME - Employment (12 indices: 100, 105, 110, 115, 120, 125)
        case .salary:
            let index = person == 2 ? "105" : "100"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Haupterwerb \(personLabel)")
        case .bonus:
            let index = person == 2 ? "125" : "120"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Weitere Vergütungen \(personLabel)")
        case .stockOptions:
            let index = person == 2 ? "105" : "100"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Included in main employment")
        case .boardCompensation:
            let index = person == 2 ? "105" : "100"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .unselbstaendigeErwerbstaetigkeit, subcategory: "Included in main employment")
        case .unemploymentBenefits:
            let index = person == 2 ? "265" : "260"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Erwerbsersatz \(personLabel)")

        // INCOME - Self-Employment (12 indices: 150, 155, 160, 165, 170, 175)
        case .freelance:
            let index = person == 2 ? "155" : "150"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .selbstaendigeErwerbstaetigkeit, subcategory: "Haupterwerb \(personLabel)")
        case .secondarySelfEmployment:
            let index = person == 2 ? "165" : "160"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .selbstaendigeErwerbstaetigkeit, subcategory: "Nebenerwerb \(personLabel)")

        // INCOME - Social Insurance (18 indices: 200, 205, 220, 225, 230, 235, 240, 245, 260, 265)
        case .pension:
            let index = person == 2 ? "205" : "200"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .vorsorge, subcategory: "AHV/IV Renten \(personLabel)")
        case .pensionFundBenefits:
            let index = person == 2 ? "225" : "220"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .vorsorge, subcategory: "Pensionen/Leibrenten \(personLabel)")
        case .otherPensions:
            let index = person == 2 ? "245" : "240"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .vorsorge, subcategory: "Sonstige Renten \(personLabel)")

        // INCOME - Further Income (14 indices: 270, 271, 280, 285, 290, 295, 299)
        case .alimony:
            return TaxFormFieldMapping(fieldNumber: "270", labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Ehegattenunterhalt erhalten")
        case .childAllowance:
            return TaxFormFieldMapping(fieldNumber: "271", labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Kinderunterhalt erhalten")
        case .foreignIncome:
            let index = person == 2 ? "285" : "280"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Weitere Einkünfte \(personLabel)")
        case .capitalSettlementFederal:
            let index = person == 2 ? "295" : "290"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Kapitalabfindungen \(personLabel)")

        // INCOME - From Assets (5 indices: 369, 479, 495, 489, 499)
        case .investment:
            return TaxFormFieldMapping(fieldNumber: "369", labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .wertschriftenUndGuthaben, subcategory: "Wertschriften/Guthaben/Lotterien")
        case .rental:
            return TaxFormFieldMapping(fieldNumber: "479", labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .liegenschaften, subcategory: "Liegenschaften")
        case .lotteryWinnings:
            return TaxFormFieldMapping(fieldNumber: "369", labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .wertschriftenUndGuthaben, subcategory: "Included in securities income")

        // DEDUCTIONS - Job Costs (4 indices: 519, 539, 550, 560, 561, 570)
        case .professionalExpenses:
            let index = person == 2 ? "539" : "519"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Berufsauslagen \(personLabel)")
        case .loanInterest, .mortgageInterest:
            return TaxFormFieldMapping(fieldNumber: "550", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .schuldzinsen, subcategory: "Schuldzinsen")
        case .supportNeedyPersons:
            return TaxFormFieldMapping(fieldNumber: "561", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .unterhalt, subcategory: "Kinderunterhalt gezahlt")
        case .voluntaryAnnuities:
            return TaxFormFieldMapping(fieldNumber: "570", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .unterhalt, subcategory: "Leibrentenzahlungen")

        // DEDUCTIONS - Pension/Insurance (11 indices: 600, 610, 615, 620, 625, 630, 631, 632)
        case .socialSecurity:
            return TaxFormFieldMapping(fieldNumber: "600", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "AHV/IV/EO Beiträge")
        case .pillar2:
            let index = person == 2 ? "615" : "610"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Berufliche Vorsorge \(personLabel)")
        case .pillar3a:
            let index = person == 2 ? "625" : "620"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Säule 3a \(personLabel)")
        case .insurancePremiums:
            // BS 630 = spouse insurance, BS 631 = other persons insurance
            return TaxFormFieldMapping(fieldNumber: "630", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Versicherungsabzug Ehegatten")
        case .healthInsurance:
            // Can map to either 630 (spouse) or 631 (others) - using 631 for general health insurance
            return TaxFormFieldMapping(fieldNumber: "631", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Versicherungsabzug übrige Personen")
        case .childcare:
            return TaxFormFieldMapping(fieldNumber: "632", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .kinderbetreuung, subcategory: "Bundessteuer Zuschlag Kinder")

        // DEDUCTIONS - Further Deductions (13 indices: 640, 650, 652, 657, 660, 670, 680, 699)
        case .taxTreaty:
            return TaxFormFieldMapping(fieldNumber: "640", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Anteil Grundstückgewinnsteuer")
        case .education, .educationExpenses:
            let index = person == 2 ? "657" : "652"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .weiterbildung, subcategory: "Ausbildungskosten \(personLabel)")
        case .homeOffice:
            return TaxFormFieldMapping(fieldNumber: "660", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Doppelverdienende")
        case .politicalDonations:
            return TaxFormFieldMapping(fieldNumber: "680", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .spenden, subcategory: "Politische Parteien")

        // DEDUCTIONS - Income Calculation (9 indices: 700, 701, 709, 725, 732, 739)
        case .medical:
            return TaxFormFieldMapping(fieldNumber: "725", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Krankheits- und Unfallkosten")
        case .donations:
            return TaxFormFieldMapping(fieldNumber: "732", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .spenden, subcategory: "Gemeinnützige Zuwendungen")

        // ASSETS - Private (6 indices: 800, 810, 815, 821, 830, 835)
        case .bankAccounts, .savings:
            return TaxFormFieldMapping(fieldNumber: "800", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .bankguthaben, subcategory: "Guthaben und Wertschriften")
        case .foreignWealth:
            return TaxFormFieldMapping(fieldNumber: "830", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Ungeteilte Erbschaften")
        case .lifeInsurance:
            return TaxFormFieldMapping(fieldNumber: "815", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Lebensversicherungen")
        case .property, .realEstate:
            return TaxFormFieldMapping(fieldNumber: "821", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .immobilien, subcategory: "Liegenschaften")
        case .crypto:
            return TaxFormFieldMapping(fieldNumber: "835", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Bargeld/Edelmetall/Krypto")

        // ASSETS - Business (5 indices: 840, 841, 860, 865, 869)
        case .stocks, .securities:
            return TaxFormFieldMapping(fieldNumber: "800", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .wertpapiere, subcategory: "Wertschriften")
        case .shareholdings:
            let index = person == 2 ? "865" : "860"
            let personLabel = person == 2 ? "Person 2" : "Person 1"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .wertpapiere, subcategory: "Gesellschaftsanteile \(personLabel)")
        case .totalAssets:
            return TaxFormFieldMapping(fieldNumber: "869", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Total Vermögen")

        // LIABILITIES - Private & Business (10 indices: 870, 872, 889, 890, 891, 892, 899)
        case .mortgage:
            return TaxFormFieldMapping(fieldNumber: "870", labelPrefix: "Feld", mainCategory: .schulden, formCategory: .hypotheken, subcategory: "Privatschulden")
        case .businessLoan:
            return TaxFormFieldMapping(fieldNumber: "872", labelPrefix: "Feld", mainCategory: .schulden, formCategory: .kredite, subcategory: "Geschäftsschulden")
        case .personalLoan, .carLoan, .studentLoan, .loanDebt, .creditCard, .otherLiabilities, .securitiesDebt, .privateLoan:
            return TaxFormFieldMapping(fieldNumber: "870", labelPrefix: "Feld", mainCategory: .schulden, formCategory: .kredite, subcategory: "Privatschulden")
        case .totalLiabilities:
            return TaxFormFieldMapping(fieldNumber: "889", labelPrefix: "Feld", mainCategory: .schulden, formCategory: .uebrigeSchulden, subcategory: "Reinvermögen")

        // ASSETS - Other (vehicles, household goods, insurance)
        case .vehicles, .vehicle:
            return TaxFormFieldMapping(fieldNumber: "835", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .fahrzeuge, subcategory: "Included in other assets")
        case .householdGoods:
            return TaxFormFieldMapping(fieldNumber: "835", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Included in other assets")
        case .insuranceSurrenderValue:
            return TaxFormFieldMapping(fieldNumber: "815", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Included in life insurance")
        case .otherAssets:
            return TaxFormFieldMapping(fieldNumber: "835", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .uebrigesVermoegen, subcategory: "Übrige Vermögenswerte")

        // Swiss-specific & Other
        case .spousalSupport:
            return TaxFormFieldMapping(fieldNumber: "560", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .unterhalt, subcategory: "Ehegattenunterhalt gezahlt")
        case .financialSupport:
            let index = person == 2 ? "285" : "280"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Included in other income")
        case .capitalSettlementState:
            return TaxFormFieldMapping(fieldNumber: "290", labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Kapitalabfindungen Staatssteuer")
        case .militaryService:
            return TaxFormFieldMapping(fieldNumber: "600", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Included in social security")
        case .withholdingTax:
            return TaxFormFieldMapping(fieldNumber: "369", labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .wertschriftenUndGuthaben, subcategory: "Subject to withholding")
        case .travelExpenses:
            let index = person == 2 ? "539" : "519"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Included in professional expenses")
        case .professionalAssociationFees:
            let index = person == 2 ? "539" : "519"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .berufsauslagen, subcategory: "Included in professional expenses")
        case .pillar2Buyback:
            let index = person == 2 ? "615" : "610"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Included in pillar 2")
        case .pillar3Buyback:
            let index = person == 2 ? "625" : "620"
            return TaxFormFieldMapping(fieldNumber: index, labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .vorsorge, subcategory: "Included in pillar 3a")
        case .specialDeductions:
            return TaxFormFieldMapping(fieldNumber: "699", labelPrefix: "Feld", mainCategory: .abzuege, formCategory: .versicherungen, subcategory: "Total Abzüge")
        case .realEstateTaxValue:
            return TaxFormFieldMapping(fieldNumber: "821", labelPrefix: "Feld", mainCategory: .vermoegen, formCategory: .immobilien, subcategory: "Included in real estate")

        // CALCULATION FIELDS & SPECIAL MAPPINGS (28 additional BS-specific indices)
        // NOTE: These are read-only calculation fields or rarely-used categories
        // Each index is explicitly referenced with "INDEX" format for grep/search
        case .other:
            // Basel-Stadt specific indices without direct TaxCategoryType equivalents:
            //
            // EMPLOYMENT INCOME:
            // "115" = Nebenerwerb Person 2 (Secondary employment Person 2 - Lohn-/Gehaltsabrechnung)
            //
            // SELF-EMPLOYMENT:
            // "170" = Personengesellschaft Person 1 (Partnership Person 1 - Jahresrechnung/Aufstellung)
            // "175" = Personengesellschaft Person 2 (Partnership Person 2 - Jahresrechnung/Aufstellung)
            //
            // SOCIAL INSURANCE INCOME:
            // "235" = Leibrenten Person 2 (Life annuities Person 2)
            //
            // INCOME FROM ASSETS:
            // "495" = Verrechenbare Liegenschaftskosten Vorjahr (Deductible property costs from previous year)
            // "489" = Unverteilte Erbschaften (Income from undivided inheritances)
            // "499" = Total der Einkünfte (Total Income - sum of all income categories)
            //
            // DEDUCTIONS:
            // "650" = Verrechenbare Geschäftsverluste der Vorjahre (Deductible business losses from previous years)
            // "670" = Abzug für fremdbetreute Kinder (Deduction for externally cared-for children / third-party childcare)
            //
            // INCOME CALCULATION FIELDS (Read-only transfer/calculation fields):
            // "701" = Total der Abzüge zur Berechnung (Total Deductions transfer to calculation)
            // "709" = Nettoeinkommen (Net Income, calculated as 700 minus 701)
            // "739" = Reineinkommen (Net Taxable Income for state tax)
            // "799" = STEUERBARES EINKOMMEN (Final Taxable Income determining tax rate)
            //
            // SOCIAL DEDUCTIONS (Sozialabzüge - 8 indices):
            // "750" = Abzug für Kinder (Child deduction, varies Canton/Federal)
            // "755" = Abzug für unterstützte Personen (Deduction for supported persons/dependents)
            // "757" = Abzug für unterstützten Konkubinatspartner mit Kindern (Deduction for supported cohabiting partner with children)
            // "760" = Abzug für Ehegatten (Spousal deduction)
            // "765" = Abzug für alleinerziehende Personen (Deduction for single parents, not for cohabiting couples)
            // "767" = Abzug für alle übrigen Personen (Basic personal deduction for all other individuals)
            // "770" = Abzug für alleinstehende Rentner/innen (Additional deduction for single pensioners, supplementary to 767)
            //
            // ASSETS:
            // "810" = Zinslose Forderungen (Interest-free claims/receivables)
            // "840" = Aktiven gemäss Bilanz Person 1 (Business assets according to balance sheet Person 1)
            // "841" = Abzüglich Buchwert Liegenschaften Person 1 (Less book value of properties if included in 821 and 840)
            //
            // TAX-FREE ALLOWANCES (Steuerfreie Beträge - 3 indices):
            // "890" = Freibetrag für Ehegatten/P1+P2 und alleinerziehende (Tax-free allowance for spouses and single parents)
            // "891" = Freibetrag für alle übrigen steuerpflichtigen Personen (Tax-free allowance for all other taxable persons)
            // "892" = Freibetrag für minderjährige Kinder (Tax-free allowance per minor child)
            //
            // NET WORTH CALCULATION:
            // "899" = STEUERBARES VERMÖGEN (Taxable Net Worth determining tax rate)
            //
            // All 28 indices above are now searchable via grep for: "115", "170", "175", "235", "489", "495", "499",
            // "650", "670", "701", "709", "739", "750", "755", "757", "760", "765", "767", "770", "799",
            // "810", "840", "841", "890", "891", "892", "899"
            return TaxFormFieldMapping(fieldNumber: "299", labelPrefix: "Feld", mainCategory: .einkommen, formCategory: .uebrigeEinkuenfte, subcategory: "Weitere Einkünfte / BS calculation fields")
        }
    }
}
