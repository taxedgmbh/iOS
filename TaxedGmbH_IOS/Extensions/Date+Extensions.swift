//
//  Date+Extensions.swift
//  TaxedGmbH_IOS
//
//  Date extensions for common operations
//

import Foundation

extension Date {

    // MARK: - Formatting

    var formatted: String {
        return FormatterHelper.formatDate(self)
    }

    var formattedWithTime: String {
        return FormatterHelper.formatDateTime(self)
    }

    var relativeFormatted: String {
        return FormatterHelper.formatRelativeDate(self)
    }

    // MARK: - Calendar Operations

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: self.startOfDay) ?? self
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: self.startOfMonth) ?? self
    }

    var year: Int {
        return Calendar.current.component(.year, from: self)
    }

    var month: Int {
        return Calendar.current.component(.month, from: self)
    }

    // MARK: - Comparison

    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }

    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }

    // MARK: - Swiss Tax Year

    var taxYear: Int {
        // In Switzerland, tax year is previous year
        let currentYear = self.year
        return currentYear - 1
    }

    static var currentTaxYear: Int {
        return Date().taxYear
    }
}
