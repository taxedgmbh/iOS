//
//  ForeignIncome.swift
//  TaxedGmbH_IOS
//
//  Model for foreign income with tax treaty and double taxation support
//

import Foundation
import FirebaseFirestore

// MARK: - Tax Treaty Countries

enum TaxTreatyCountry: String, Codable, CaseIterable {
    // Major expat countries
    case usa = "US"
    case uk = "GB"
    case germany = "DE"
    case france = "FR"
    case italy = "IT"
    case austria = "AT"
    case netherlands = "NL"
    case belgium = "BE"
    case spain = "ES"
    case portugal = "PT"
    case sweden = "SE"
    case denmark = "DK"
    case norway = "NO"
    case finland = "FI"
    case poland = "PL"
    case czechia = "CZ"
    case canada = "CA"
    case australia = "AU"
    case newZealand = "NZ"
    case japan = "JP"
    case singapore = "SG"
    case india = "IN"
    case china = "CN"
    case brazil = "BR"
    case mexico = "MX"
    case southAfrica = "ZA"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .usa: return "United States"
        case .uk: return "United Kingdom"
        case .germany: return "Germany"
        case .france: return "France"
        case .italy: return "Italy"
        case .austria: return "Austria"
        case .netherlands: return "Netherlands"
        case .belgium: return "Belgium"
        case .spain: return "Spain"
        case .portugal: return "Portugal"
        case .sweden: return "Sweden"
        case .denmark: return "Denmark"
        case .norway: return "Norway"
        case .finland: return "Finland"
        case .poland: return "Poland"
        case .czechia: return "Czech Republic"
        case .canada: return "Canada"
        case .australia: return "Australia"
        case .newZealand: return "New Zealand"
        case .japan: return "Japan"
        case .singapore: return "Singapore"
        case .india: return "India"
        case .china: return "China"
        case .brazil: return "Brazil"
        case .mexico: return "Mexico"
        case .southAfrica: return "South Africa"
        case .other: return "Other"
        }
    }

    var flag: String {
        switch self {
        case .usa: return "🇺🇸"
        case .uk: return "🇬🇧"
        case .germany: return "🇩🇪"
        case .france: return "🇫🇷"
        case .italy: return "🇮🇹"
        case .austria: return "🇦🇹"
        case .netherlands: return "🇳🇱"
        case .belgium: return "🇧🇪"
        case .spain: return "🇪🇸"
        case .portugal: return "🇵🇹"
        case .sweden: return "🇸🇪"
        case .denmark: return "🇩🇰"
        case .norway: return "🇳🇴"
        case .finland: return "🇫🇮"
        case .poland: return "🇵🇱"
        case .czechia: return "🇨🇿"
        case .canada: return "🇨🇦"
        case .australia: return "🇦🇺"
        case .newZealand: return "🇳🇿"
        case .japan: return "🇯🇵"
        case .singapore: return "🇸🇬"
        case .india: return "🇮🇳"
        case .china: return "🇨🇳"
        case .brazil: return "🇧🇷"
        case .mexico: return "🇲🇽"
        case .southAfrica: return "🇿🇦"
        case .other: return "🌍"
        }
    }

    static var popular: [TaxTreatyCountry] {
        [.usa, .uk, .germany, .france, .italy, .austria, .netherlands]
    }
}

// MARK: - Foreign Income Type

enum ForeignIncomeType: String, Codable {
    case employment = "employment"
    case selfEmployment = "self_employment"
    case pension = "pension"
    case socialSecurity = "social_security"
    case investment = "investment"
    case rental = "rental"
    case capitalGains = "capital_gains"
    case dividends = "dividends"
    case interest = "interest"
    case royalties = "royalties"
    case other = "other"

    var displayName: String {
        switch self {
        case .employment: return "foreign_income.type.employment".localized
        case .selfEmployment: return "foreign_income.type.self_employment".localized
        case .pension: return "foreign_income.type.pension".localized
        case .socialSecurity: return "foreign_income.type.social_security".localized
        case .investment: return "foreign_income.type.investment".localized
        case .rental: return "foreign_income.type.rental".localized
        case .capitalGains: return "foreign_income.type.capital_gains".localized
        case .dividends: return "foreign_income.type.dividends".localized
        case .interest: return "foreign_income.type.interest".localized
        case .royalties: return "foreign_income.type.royalties".localized
        case .other: return "foreign_income.type.other".localized
        }
    }
}

// MARK: - Foreign Income Model

struct ForeignIncome: Codable, Identifiable {
    var id: String
    var customerId: String
    var documentId: String?  // Link to associated TaxDocument

    // Source Information
    var sourceCountry: TaxTreatyCountry
    var incomeType: ForeignIncomeType
    var description: String

    // Financial Information
    var amountForeignCurrency: Double
    var currencyCode: String  // ISO 4217 (e.g., USD, EUR, GBP)
    var amountCHF: Double?  // Converted amount
    var exchangeRate: Double?  // Exchange rate used
    var exchangeRateDate: Date?  // Date of exchange rate

    // Tax Information
    var taxPaidInSourceCountry: Double?  // Foreign tax withheld
    var taxPaidCHF: Double?  // Foreign tax in CHF
    var hasTaxTreaty: Bool  // Does tax treaty apply?
    var doubleTaxationRelief: Bool  // Claiming relief?

    // Swiss Tax Information
    var taxYear: Int
    var canton: String?

    // Expert Review
    var expertNotes: String?
    var verifiedByExpert: Bool

    // Timestamps
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        customerId: String,
        documentId: String? = nil,
        sourceCountry: TaxTreatyCountry,
        incomeType: ForeignIncomeType,
        description: String,
        amountForeignCurrency: Double,
        currencyCode: String,
        amountCHF: Double? = nil,
        exchangeRate: Double? = nil,
        exchangeRateDate: Date? = nil,
        taxPaidInSourceCountry: Double? = nil,
        taxPaidCHF: Double? = nil,
        hasTaxTreaty: Bool = true,
        doubleTaxationRelief: Bool = true,
        taxYear: Int,
        canton: String? = nil,
        expertNotes: String? = nil,
        verifiedByExpert: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.customerId = customerId
        self.documentId = documentId
        self.sourceCountry = sourceCountry
        self.incomeType = incomeType
        self.description = description
        self.amountForeignCurrency = amountForeignCurrency
        self.currencyCode = currencyCode
        self.amountCHF = amountCHF
        self.exchangeRate = exchangeRate
        self.exchangeRateDate = exchangeRateDate
        self.taxPaidInSourceCountry = taxPaidInSourceCountry
        self.taxPaidCHF = taxPaidCHF
        self.hasTaxTreaty = hasTaxTreaty
        self.doubleTaxationRelief = doubleTaxationRelief
        self.taxYear = taxYear
        self.canton = canton
        self.expertNotes = expertNotes
        self.verifiedByExpert = verifiedByExpert
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Convert to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "customerId": customerId,
            "sourceCountry": sourceCountry.rawValue,
            "incomeType": incomeType.rawValue,
            "description": description,
            "amountForeignCurrency": amountForeignCurrency,
            "currencyCode": currencyCode,
            "hasTaxTreaty": hasTaxTreaty,
            "doubleTaxationRelief": doubleTaxationRelief,
            "taxYear": taxYear,
            "verifiedByExpert": verifiedByExpert,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]

        if let documentId = documentId { dict["documentId"] = documentId }
        if let amountCHF = amountCHF { dict["amountCHF"] = amountCHF }
        if let exchangeRate = exchangeRate { dict["exchangeRate"] = exchangeRate }
        if let exchangeRateDate = exchangeRateDate {
            dict["exchangeRateDate"] = Timestamp(date: exchangeRateDate)
        }
        if let taxPaidInSourceCountry = taxPaidInSourceCountry {
            dict["taxPaidInSourceCountry"] = taxPaidInSourceCountry
        }
        if let taxPaidCHF = taxPaidCHF { dict["taxPaidCHF"] = taxPaidCHF }
        if let canton = canton { dict["canton"] = canton }
        if let expertNotes = expertNotes { dict["expertNotes"] = expertNotes }

        return dict
    }

    // Create from Firestore dictionary
    static func fromDictionary(id: String, data: [String: Any]) -> ForeignIncome? {
        guard let customerId = data["customerId"] as? String,
              let sourceCountryString = data["sourceCountry"] as? String,
              let sourceCountry = TaxTreatyCountry(rawValue: sourceCountryString),
              let incomeTypeString = data["incomeType"] as? String,
              let incomeType = ForeignIncomeType(rawValue: incomeTypeString),
              let description = data["description"] as? String,
              let amountForeignCurrency = data["amountForeignCurrency"] as? Double,
              let currencyCode = data["currencyCode"] as? String,
              let taxYear = data["taxYear"] as? Int else {
            return nil
        }

        let hasTaxTreaty = data["hasTaxTreaty"] as? Bool ?? true
        let doubleTaxationRelief = data["doubleTaxationRelief"] as? Bool ?? true
        let verifiedByExpert = data["verifiedByExpert"] as? Bool ?? false
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let exchangeRateDate = (data["exchangeRateDate"] as? Timestamp)?.dateValue()

        return ForeignIncome(
            id: id,
            customerId: customerId,
            documentId: data["documentId"] as? String,
            sourceCountry: sourceCountry,
            incomeType: incomeType,
            description: description,
            amountForeignCurrency: amountForeignCurrency,
            currencyCode: currencyCode,
            amountCHF: data["amountCHF"] as? Double,
            exchangeRate: data["exchangeRate"] as? Double,
            exchangeRateDate: exchangeRateDate,
            taxPaidInSourceCountry: data["taxPaidInSourceCountry"] as? Double,
            taxPaidCHF: data["taxPaidCHF"] as? Double,
            hasTaxTreaty: hasTaxTreaty,
            doubleTaxationRelief: doubleTaxationRelief,
            taxYear: taxYear,
            canton: data["canton"] as? String,
            expertNotes: data["expertNotes"] as? String,
            verifiedByExpert: verifiedByExpert,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
