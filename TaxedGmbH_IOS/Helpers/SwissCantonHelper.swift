//
//  SwissCantonHelper.swift
//  TaxedGmbH_IOS
//
//  Helper for Swiss canton data and tax deadlines
//

import Foundation

/// Swiss Canton data structure
struct SwissCanton: Identifiable, Hashable {
    let id: String  // Canton abbreviation (e.g., "ZH", "BE")
    let nameDe: String
    let nameEn: String
    let nameFr: String
    let nameIt: String
    let taxDeadline: String  // Typical tax filing deadline
    let hasOnlinePortal: Bool
    let portalUrl: String?

    var displayName: String {
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        switch locale {
        case "de":
            return nameDe
        case "fr":
            return nameFr
        case "it":
            return nameIt
        default:
            return nameEn
        }
    }
}

/// Helper class for Swiss canton operations
class SwissCantonHelper {
    static let shared = SwissCantonHelper()

    /// All 26 Swiss cantons
    let allCantons: [SwissCanton] = [
        SwissCanton(id: "ZH", nameDe: "Zürich", nameEn: "Zurich", nameFr: "Zurich", nameIt: "Zurigo", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.zh.ch/de/steuern-finanzen"),
        SwissCanton(id: "BE", nameDe: "Bern", nameEn: "Bern", nameFr: "Berne", nameIt: "Berna", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.be.ch/de/start/themen/steuern"),
        SwissCanton(id: "LU", nameDe: "Luzern", nameEn: "Lucerne", nameFr: "Lucerne", nameIt: "Lucerna", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://steuern.lu.ch"),
        SwissCanton(id: "UR", nameDe: "Uri", nameEn: "Uri", nameFr: "Uri", nameIt: "Uri", taxDeadline: "31. März", hasOnlinePortal: false, portalUrl: nil),
        SwissCanton(id: "SZ", nameDe: "Schwyz", nameEn: "Schwyz", nameFr: "Schwytz", nameIt: "Svitto", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.sz.ch/steuern"),
        SwissCanton(id: "OW", nameDe: "Obwalden", nameEn: "Obwalden", nameFr: "Obwald", nameIt: "Obvaldo", taxDeadline: "31. März", hasOnlinePortal: false, portalUrl: nil),
        SwissCanton(id: "NW", nameDe: "Nidwalden", nameEn: "Nidwalden", nameFr: "Nidwald", nameIt: "Nidvaldo", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.nw.ch/steuern"),
        SwissCanton(id: "GL", nameDe: "Glarus", nameEn: "Glarus", nameFr: "Glaris", nameIt: "Glarona", taxDeadline: "31. März", hasOnlinePortal: false, portalUrl: nil),
        SwissCanton(id: "ZG", nameDe: "Zug", nameEn: "Zug", nameFr: "Zoug", nameIt: "Zugo", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.zg.ch/steuern"),
        SwissCanton(id: "FR", nameDe: "Freiburg", nameEn: "Fribourg", nameFr: "Fribourg", nameIt: "Friburgo", taxDeadline: "31. Mars", hasOnlinePortal: true, portalUrl: "https://www.fr.ch/de/staat-und-recht/steuern"),
        SwissCanton(id: "SO", nameDe: "Solothurn", nameEn: "Solothurn", nameFr: "Soleure", nameIt: "Soletta", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://so.ch/steuern"),
        SwissCanton(id: "BS", nameDe: "Basel-Stadt", nameEn: "Basel-City", nameFr: "Bâle-Ville", nameIt: "Basilea Città", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.steuerverwaltung.bs.ch"),
        SwissCanton(id: "BL", nameDe: "Basel-Landschaft", nameEn: "Basel-Country", nameFr: "Bâle-Campagne", nameIt: "Basilea Campagna", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.bl.ch/steuern"),
        SwissCanton(id: "SH", nameDe: "Schaffhausen", nameEn: "Schaffhausen", nameFr: "Schaffhouse", nameIt: "Sciaffusa", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://sh.ch/steuern"),
        SwissCanton(id: "AR", nameDe: "Appenzell Ausserrhoden", nameEn: "Appenzell Outer Rhodes", nameFr: "Appenzell Rhodes-Extérieures", nameIt: "Appenzello Esterno", taxDeadline: "31. März", hasOnlinePortal: false, portalUrl: nil),
        SwissCanton(id: "AI", nameDe: "Appenzell Innerrhoden", nameEn: "Appenzell Inner Rhodes", nameFr: "Appenzell Rhodes-Intérieures", nameIt: "Appenzello Interno", taxDeadline: "31. März", hasOnlinePortal: false, portalUrl: nil),
        SwissCanton(id: "SG", nameDe: "St. Gallen", nameEn: "St. Gallen", nameFr: "Saint-Gall", nameIt: "San Gallo", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.sg.ch/steuern-finanzen"),
        SwissCanton(id: "GR", nameDe: "Graubünden", nameEn: "Grisons", nameFr: "Grisons", nameIt: "Grigioni", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.gr.ch/steuern"),
        SwissCanton(id: "AG", nameDe: "Aargau", nameEn: "Aargau", nameFr: "Argovie", nameIt: "Argovia", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://www.ag.ch/steuern"),
        SwissCanton(id: "TG", nameDe: "Thurgau", nameEn: "Thurgau", nameFr: "Thurgovie", nameIt: "Turgovia", taxDeadline: "31. März", hasOnlinePortal: true, portalUrl: "https://steuerverwaltung.tg.ch"),
        SwissCanton(id: "TI", nameDe: "Tessin", nameEn: "Ticino", nameFr: "Tessin", nameIt: "Ticino", taxDeadline: "31 marzo", hasOnlinePortal: true, portalUrl: "https://www4.ti.ch/dfe/dc"),
        SwissCanton(id: "VD", nameDe: "Waadt", nameEn: "Vaud", nameFr: "Vaud", nameIt: "Vaud", taxDeadline: "31 mars", hasOnlinePortal: true, portalUrl: "https://www.vd.ch/impots"),
        SwissCanton(id: "VS", nameDe: "Wallis", nameEn: "Valais", nameFr: "Valais", nameIt: "Vallese", taxDeadline: "31 mars", hasOnlinePortal: true, portalUrl: "https://www.vs.ch/impots"),
        SwissCanton(id: "NE", nameDe: "Neuenburg", nameEn: "Neuchâtel", nameFr: "Neuchâtel", nameIt: "Neuchâtel", taxDeadline: "31 mars", hasOnlinePortal: true, portalUrl: "https://www.ne.ch/impots"),
        SwissCanton(id: "GE", nameDe: "Genf", nameEn: "Geneva", nameFr: "Genève", nameIt: "Ginevra", taxDeadline: "31 mars", hasOnlinePortal: true, portalUrl: "https://www.ge.ch/impots"),
        SwissCanton(id: "JU", nameDe: "Jura", nameEn: "Jura", nameFr: "Jura", nameIt: "Giura", taxDeadline: "31 mars", hasOnlinePortal: true, portalUrl: "https://www.jura.ch/impots")
    ]

    /// Get canton by ID
    func getCanton(byId id: String) -> SwissCanton? {
        return allCantons.first { $0.id == id }
    }

    /// Get canton display name for current locale
    func getCantonDisplayName(forId id: String) -> String {
        return getCanton(byId: id)?.displayName ?? id
    }

    /// Get tax deadline for canton
    func getTaxDeadline(forCantonId id: String) -> String {
        return getCanton(byId: id)?.taxDeadline ?? "31. März"
    }

    /// Check if canton has online portal
    func hasOnlinePortal(cantonId: String) -> Bool {
        return getCanton(byId: cantonId)?.hasOnlinePortal ?? false
    }

    /// Get portal URL for canton
    func getPortalUrl(forCantonId id: String) -> URL? {
        guard let urlString = getCanton(byId: id)?.portalUrl else { return nil }
        return URL(string: urlString)
    }

    /// Calculate next tax filing deadline based on current date
    func getNextTaxDeadline(forYear year: Int, cantonId: String) -> Date? {
        let calendar = Calendar.current
        // Most cantons have March 31 deadline for the following year
        // e.g., for 2024 taxes, deadline is March 31, 2025
        let components = DateComponents(year: year + 1, month: 3, day: 31)
        return calendar.date(from: components)
    }

    /// Get days until tax deadline
    func getDaysUntilDeadline(forYear year: Int, cantonId: String) -> Int? {
        guard let deadline = getNextTaxDeadline(forYear: year, cantonId: cantonId) else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: deadline)
        return components.day
    }
}
