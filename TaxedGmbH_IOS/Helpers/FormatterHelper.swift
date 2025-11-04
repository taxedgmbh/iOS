//
//  FormatterHelper.swift
//  TaxedGmbH_IOS
//
//  Formatting utilities for dates, currency, and numbers
//

import Foundation

struct FormatterHelper {

    // MARK: - Currency Formatter

    static func formatCurrency(_ amount: Double, locale: Locale = Locale(identifier: "de_CH")) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = "CHF"
        formatter.currencySymbol = "CHF"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: amount)) ?? "CHF 0.00"
    }

    // MARK: - Date Formatters

    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_CH")
        return formatter.string(from: date)
    }

    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_CH")
        return formatter.string(from: date)
    }

    static func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "de_CH")
            return "Heute, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "de_CH")
            return "Gestern, \(formatter.string(from: date))"
        } else {
            let components = calendar.dateComponents([.day], from: date, to: now)
            if let days = components.day, days < 7 {
                return "\(days) Tage her"
            } else {
                return formatDate(date)
            }
        }
    }

    static func formatTaxYear(_ year: Int) -> String {
        return "Steuerperiode \(year)"
    }

    // MARK: - Number Formatters

    static func formatPercentage(_ value: Double, decimals: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.locale = Locale(identifier: "de_CH")

        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }

    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Swiss Canton Formatter

    static func formatCanton(_ canton: String) -> String {
        // Map canton codes to full names
        let cantonNames: [String: String] = [
            "ZH": "Zürich",
            "BE": "Bern",
            "LU": "Luzern",
            "UR": "Uri",
            "SZ": "Schwyz",
            "OW": "Obwalden",
            "NW": "Nidwalden",
            "GL": "Glarus",
            "ZG": "Zug",
            "FR": "Freiburg",
            "SO": "Solothurn",
            "BS": "Basel-Stadt",
            "BL": "Basel-Landschaft",
            "SH": "Schaffhausen",
            "AR": "Appenzell Ausserrhoden",
            "AI": "Appenzell Innerrhoden",
            "SG": "St. Gallen",
            "GR": "Graubünden",
            "AG": "Aargau",
            "TG": "Thurgau",
            "TI": "Tessin",
            "VD": "Waadt",
            "VS": "Wallis",
            "NE": "Neuenburg",
            "GE": "Genf",
            "JU": "Jura"
        ]

        return cantonNames[canton.uppercased()] ?? canton
    }
}
