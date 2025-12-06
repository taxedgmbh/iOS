//
//  DynamicTaxFieldsView.swift
//  TaxedGmbH_IOS
//
//  Dynamic form fields based on canton-specific tax index mappings
//  Replaces static FinancialInputView with data-driven field rendering
//

import SwiftUI

struct DynamicTaxFieldsView: View {
    let mapping: TaxIndexMapping
    @Binding var fieldValues: [String: String]
    let onSave: () async -> Void

    @State private var isSaving = false
    @State private var saveSuccess = false

    // Currency & FX state (if required by mapping)
    @State private var selectedCurrency: String = "CHF"
    @State private var exchangeRate: String = ""
    @State private var showFXOptions = false

    private let currencies = ["CHF", "EUR", "USD", "GBP", "JPY", "CAD", "AUD"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header: Index Information
            headerSection

            // Dynamic Fields based on mapping
            ForEach(mapping.fields) { field in
                fieldInputView(for: field)
            }

            // Currency/FX Section (if required)
            if mapping.currencyRequired {
                currencySection
            }

            if mapping.fxRequired {
                fxConversionSection
            }

            // Notes (if available)
            if let notes = mapping.notes, !notes.isEmpty {
                notesSection(notes: notes)
            }

            // Save Button
            saveButton
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Index: \(mapping.index)")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text(mapping.canton)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }

            if !mapping.subCategory.isEmpty {
                Text(mapping.subCategory)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let person = mapping.person, !person.isEmpty {
                Text(person)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Field Input View

    @ViewBuilder
    private func fieldInputView(for field: FieldDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(field.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if field.required {
                    Text("*")
                        .foregroundColor(.red)
                }

                Spacer()

                if field.type == .currency {
                    Text(selectedCurrency)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            switch field.type {
            case .currency:
                TextField("0.00", text: binding(for: field.name))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

            case .percentage:
                HStack {
                    TextField("0.00", text: binding(for: field.name))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("%")
                        .foregroundColor(.secondary)
                }

            case .integer:
                TextField("0", text: binding(for: field.name))
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

            case .date:
                DatePicker("", selection: dateBinding(for: field.name), displayedComponents: .date)
                    .labelsHidden()

            case .text:
                TextField("Enter \(field.name)", text: binding(for: field.name))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Currency Section

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Currency")
                .font(.subheadline)
                .fontWeight(.medium)

            Picker("Currency", selection: $selectedCurrency) {
                ForEach(currencies, id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            if selectedCurrency != "CHF" {
                Text("ℹ️ Amounts in foreign currencies will be converted using ESTV rates")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - FX Conversion Section

    private var fxConversionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Foreign Currency Conversion", isOn: $showFXOptions)
                .font(.subheadline)
                .fontWeight(.medium)

            if showFXOptions {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exchange Rate (to CHF)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Exchange rate", text: $exchangeRate)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("ℹ️ Use ESTV official rates: Mid-year for income, Year-end for wealth")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Important Information", systemImage: "info.circle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)

            Text(notes)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: {
            Task {
                isSaving = true
                await onSave()
                isSaving = false
                saveSuccess = true

                // Reset success state after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    saveSuccess = false
                }
            }
        }) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if saveSuccess {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Saved!")
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Save Field Data")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(saveSuccess ? Color.green : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isSaving || !isFormValid)
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        // Check that all required fields have values
        for field in mapping.fields where field.required {
            let value = fieldValues[field.name, default: ""]
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }
        return true
    }

    // MARK: - Bindings

    private func binding(for fieldName: String) -> Binding<String> {
        Binding(
            get: { fieldValues[fieldName, default: ""] },
            set: { fieldValues[fieldName] = $0 }
        )
    }

    private func dateBinding(for fieldName: String) -> Binding<Date> {
        Binding(
            get: {
                if let dateString = fieldValues[fieldName],
                   let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
                return Date()
            },
            set: {
                let formatter = ISO8601DateFormatter()
                fieldValues[fieldName] = formatter.string(from: $0)
            }
        )
    }
}

// MARK: - Preview

struct DynamicTaxFieldsView_Previews: PreviewProvider {
    static var previews: some View {
        // Note: Preview requires a TaxIndexMapping loaded from Firestore
        // For now, showing placeholder with mock data
        Text("DynamicTaxFieldsView Preview")
            .font(.title)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }
}
