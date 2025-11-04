//
//  TaxCalculatorView.swift
//  TaxedGmbH_IOS
//
//  Tax calculator for expats (Pro feature)
//

import SwiftUI

struct TaxCalculatorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var annualIncome: String = ""
    @State private var selectedCanton = "ZH"
    @State private var maritalStatus = "single"
    @State private var hasChildren = false
    @State private var numberOfChildren = 0
    @State private var showResult = false
    @State private var calculatedTax: Double = 0

    let cantons = [
        "ZH": "Zurich",
        "BE": "Bern",
        "VD": "Vaud",
        "AG": "Aargau",
        "GE": "Geneva",
        "BS": "Basel-Stadt",
        "SG": "St. Gallen",
        "LU": "Lucerne"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pro Feature Banner
                    ProFeatureBanner()

                    // Calculator Form
                    VStack(spacing: 20) {
                        // Income Input
                        VStack(alignment: .leading, spacing: 8) {
                            Label("calc.income".localized, systemImage: "dollarsign.circle")
                                .font(.headline)

                            TextField("calc.income_placeholder".localized, text: $annualIncome)
                                .keyboardType(.numberPad)
                                .textFieldStyle(CalculatorTextFieldStyle())
                        }

                        // Canton Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Label("calc.canton".localized, systemImage: "map")
                                .font(.headline)

                            Picker("Canton", selection: $selectedCanton) {
                                ForEach(Array(cantons.keys.sorted()), id: \.self) { key in
                                    Text(cantons[key] ?? key)
                                        .tag(key)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Marital Status
                        VStack(alignment: .leading, spacing: 8) {
                            Label("calc.marital".localized, systemImage: "person.2")
                                .font(.headline)

                            Picker("Marital Status", selection: $maritalStatus) {
                                Text("calc.single".localized).tag("single")
                                Text("calc.married".localized).tag("married")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }

                        // Children Toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $hasChildren) {
                                Label("calc.children".localized, systemImage: "figure.and.child.holdinghands")
                                    .font(.headline)
                            }
                            .tint(Color(red: 227/255, green: 30/255, blue: 36/255))

                            if hasChildren {
                                Stepper(value: $numberOfChildren, in: 0...10) {
                                    HStack {
                                        Text("calc.number_children".localized)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(numberOfChildren)")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)

                    // Calculate Button
                    Button {
                        calculateTax()
                    } label: {
                        HStack {
                            Image(systemName: "function")
                            Text("calc.calculate".localized)
                                .fontWeight(.semibold)
                        }
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

                    // Result Card
                    if showResult {
                        TaxResultCard(
                            income: Double(annualIncome) ?? 0,
                            canton: cantons[selectedCanton] ?? selectedCanton,
                            estimatedTax: calculatedTax
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Disclaimer
                    DisclaimerCard()
                }
                .padding()
            }
            .navigationTitle("calc.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func calculateTax() {
        // Simple tax calculation (this is a placeholder)
        let income = Double(annualIncome) ?? 0
        var baseTax = income * 0.15 // Base 15% rate

        // Canton adjustment
        switch selectedCanton {
        case "ZH": baseTax *= 1.0
        case "GE": baseTax *= 1.3
        case "VD": baseTax *= 1.2
        case "BS": baseTax *= 1.15
        default: baseTax *= 1.1
        }

        // Marital status adjustment
        if maritalStatus == "married" {
            baseTax *= 0.85
        }

        // Children deduction
        if hasChildren {
            baseTax -= (Double(numberOfChildren) * 2000)
        }

        calculatedTax = max(baseTax, 0)

        withAnimation {
            showResult = true
        }

        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Pro Feature Banner
struct ProFeatureBanner: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("calc.pro_feature".localized)
                    .font(.headline)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }

            Text("calc.pro_description".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Tax Result Card
struct TaxResultCard: View {
    let income: Double
    let canton: String
    let estimatedTax: Double

    var effectiveRate: Double {
        guard income > 0 else { return 0 }
        return (estimatedTax / income) * 100
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.green)
                Text("calc.results".localized)
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                ResultRow(
                    label: "calc.gross_income".localized,
                    value: "CHF \(Int(income).formatted())",
                    color: .primary
                )

                ResultRow(
                    label: "calc.estimated_tax".localized,
                    value: "CHF \(Int(estimatedTax).formatted())",
                    color: .orange
                )

                ResultRow(
                    label: "calc.net_income".localized,
                    value: "CHF \(Int(income - estimatedTax).formatted())",
                    color: .green
                )

                Divider()

                ResultRow(
                    label: "calc.effective_rate".localized,
                    value: String(format: "%.1f%%", effectiveRate),
                    color: .blue
                )
            }

            Text("calc.canton_specific".localized + " \(canton)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Result Row
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

// MARK: - Disclaimer Card
struct DisclaimerCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("calc.disclaimer_title".localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Text("calc.disclaimer_text".localized)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Text Field Style
struct CalculatorTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
    }
}

#Preview {
    TaxCalculatorView()
}