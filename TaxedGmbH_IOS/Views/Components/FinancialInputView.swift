//
//  FinancialInputView.swift
//  TaxedGmbH_IOS
//
//  Reusable component for entering financial amounts with foreign currency support
//  Includes ESTV exchange rate handling and pro-rata calculations
//

import SwiftUI

/// Exchange rate type for ESTV compliance
enum ExchangeRateType: String, Codable {
    case annual = "annual"        // Jahres-Durchschnittskurs
    case midYear = "mid_year"     // Halbjahres-Durchschnittskurs
    case yearEnd = "year_end"     // Jahresendkurs
    case monthly = "monthly"      // Monats-Durchschnittskurs
    case custom = "custom"        // Custom rate
    case manual = "manual"        // Manual entry
}

/// Financial data model for the input view
struct FinancialData {
    var amount: Double?
    var currency: String = "CHF"
    var originalAmount: Double?
    var foreignCurrency: String?
    var exchangeRate: Double?
    var exchangeRateType: ExchangeRateType?
    var exchangeRateDate: Date?
    var estvRateSource: String?
    var isProRated: Bool = false
    var annualizedAmount: Double?
    var proRataMonths: Int?
    var proRataStartDate: Date?
    var proRataEndDate: Date?
}

struct FinancialInputView: View {
    @Binding var financialData: FinancialData
    @State private var amountText: String = ""
    @State private var originalAmountText: String = ""
    @State private var exchangeRateText: String = ""
    @State private var annualizedAmountText: String = ""
    @State private var showAdvancedOptions = false
    @State private var isForeignCurrency = false

    // Common currencies for Swiss tax purposes
    private let currencies = ["CHF", "EUR", "USD", "GBP", "JPY", "CAD", "AUD"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Amount and Currency Section
            VStack(alignment: .leading, spacing: 12) {
                Text("financial_input.amount".localized)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    // Amount input
                    TextField("financial_input.amount_placeholder".localized, text: $amountText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)
                        .onChange(of: amountText) { _, newValue in
                            financialData.amount = Double(newValue)
                        }

                    // Currency picker
                    Picker("financial_input.currency".localized, selection: $financialData.currency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100)
                    .onChange(of: financialData.currency) { _, newValue in
                        isForeignCurrency = newValue != "CHF"
                        if !isForeignCurrency {
                            // Reset foreign currency fields when switching to CHF
                            financialData.originalAmount = nil
                            financialData.foreignCurrency = nil
                            financialData.exchangeRate = nil
                            financialData.exchangeRateType = nil
                            financialData.estvRateSource = nil
                            originalAmountText = ""
                            exchangeRateText = ""
                        }
                    }
                }
            }

            // Foreign Currency Section (only shown for non-CHF)
            if isForeignCurrency {
                VStack(alignment: .leading, spacing: 12) {
                    Text("financial_input.foreign_currency".localized)
                        .font(.headline)
                        .foregroundColor(.orange)

                    // Original amount in foreign currency
                    HStack(spacing: 8) {
                        Image(systemName: "coloncurrencysign.circle.fill")
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("financial_input.original_amount".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("0.00", text: $originalAmountText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: originalAmountText) { _, newValue in
                                    financialData.originalAmount = Double(newValue)
                                    financialData.foreignCurrency = financialData.currency
                                }
                        }
                    }

                    // ESTV Exchange Rate
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("financial_input.exchange_rate".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("financial_input.exchange_rate_placeholder".localized, text: $exchangeRateText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: exchangeRateText) { _, newValue in
                                    financialData.exchangeRate = Double(newValue)
                                }
                        }
                    }

                    // Exchange Rate Type Picker
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.purple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("financial_input.rate_type".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("financial_input.rate_type".localized, selection: Binding(
                                get: { financialData.exchangeRateType ?? .midYear },
                                set: { financialData.exchangeRateType = $0 }
                            )) {
                                Text("financial_input.rate_type.mid_year".localized).tag(ExchangeRateType.midYear)
                                Text("financial_input.rate_type.year_end".localized).tag(ExchangeRateType.yearEnd)
                                Text("financial_input.rate_type.custom".localized).tag(ExchangeRateType.custom)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }

                    // ESTV Rate Source (optional)
                    if showAdvancedOptions {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("financial_input.estv_source".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("financial_input.estv_source_placeholder".localized,
                                         text: Binding(
                                            get: { financialData.estvRateSource ?? "" },
                                            set: { financialData.estvRateSource = $0.isEmpty ? nil : $0 }
                                         ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }

                    // Exchange Rate Date
                    if showAdvancedOptions {
                        DatePicker(
                            "financial_input.rate_date".localized,
                            selection: Binding(
                                get: { financialData.exchangeRateDate ?? Date() },
                                set: { financialData.exchangeRateDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .font(.caption)
                    }

                    // Toggle for advanced options
                    Button(action: {
                        withAnimation {
                            showAdvancedOptions.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: showAdvancedOptions ? "chevron.up" : "chevron.down")
                            Text(showAdvancedOptions ? "financial_input.hide_advanced".localized : "financial_input.show_advanced".localized)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.05))
                .cornerRadius(12)
            }

            // Pro-Rata Section (Unterjährige Steuererklärung)
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $financialData.isProRated) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.indigo)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("financial_input.pro_rata".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("financial_input.pro_rata_subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if financialData.isProRated {
                    VStack(alignment: .leading, spacing: 12) {
                        // Annualized Amount
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("financial_input.annualized_amount".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("financial_input.annualized_placeholder".localized, text: $annualizedAmountText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: annualizedAmountText) { _, newValue in
                                        financialData.annualizedAmount = Double(newValue)
                                    }
                            }
                        }

                        // Pro-rata period (dates)
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("financial_input.period_start".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                DatePicker("", selection: Binding(
                                    get: { financialData.proRataStartDate ?? Date() },
                                    set: { financialData.proRataStartDate = $0 }
                                ), displayedComponents: .date)
                                .labelsHidden()
                            }

                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("financial_input.period_end".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                DatePicker("", selection: Binding(
                                    get: { financialData.proRataEndDate ?? Date() },
                                    set: { financialData.proRataEndDate = $0 }
                                ), displayedComponents: .date)
                                .labelsHidden()
                            }
                        }

                        // Calculated months (read-only display)
                        if let start = financialData.proRataStartDate,
                           let end = financialData.proRataEndDate {
                            let months = calculateMonthsBetween(start: start, end: end)

                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("financial_input.calculated_months".localized(with: String(months)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .onAppear {
                                financialData.proRataMonths = months
                            }
                            .onChange(of: start) { _, _ in
                                financialData.proRataMonths = calculateMonthsBetween(start: start, end: end)
                            }
                            .onChange(of: end) { _, _ in
                                financialData.proRataMonths = calculateMonthsBetween(start: start, end: end)
                            }
                        }
                    }
                    .padding()
                    .background(Color.indigo.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }

    // MARK: - Helper Methods

    /// Calculate months between two dates
    private func calculateMonthsBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: start, to: end)
        return max((components.month ?? 0) + 1, 1) // +1 to include both start and end months
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var financialData = FinancialData()

    NavigationView {
        ScrollView {
            FinancialInputView(financialData: $financialData)
        }
        .navigationTitle("financial_input.title".localized)
    }
}
