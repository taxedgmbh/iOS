//
//  TermsOfServiceView.swift
//  TaxedGmbH_IOS
//
//  Terms of Service View
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hasAccepted: Bool = false

    let isOnboarding: Bool

    init(isOnboarding: Bool = false) {
        self.isOnboarding = isOnboarding
    }

    var body: some View {
        NavigationView {
            mainContent
        }
    }

    private var mainContent: some View {
        ZStack {
            contentView
            if isOnboarding {
                bottomButton
            }
        }
        .navigationTitle("terms.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Terms of Service")
        .navigationBarItems(
            trailing: navigationBarButton
        )
    }

    @ViewBuilder
    private var navigationBarButton: some View {
        if !isOnboarding {
            Button("common.done".localized) {
                dismiss()
            }
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .paddingSpacious) {
                // Last Updated
                Text("terms.last_updated".localized(with: "24.11.2024"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Introduction
                Group {
                    Text("terms.introduction.title".localized)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("terms.introduction.content".localized)
                        .font(.body)
                }

                serviceSection
                obligationsSection
                paymentSection
                liabilitySection
                intellectualPropertySection
                terminationSection
                governingLawSection
                contactSection

                // Accept checkbox for onboarding
                if isOnboarding {
                    HStack {
                        Button(action: { hasAccepted.toggle() }) {
                            Image(systemName: hasAccepted ? "checkmark.square.fill" : "square")
                                .foregroundColor(hasAccepted ? .taxedPrimary : .secondary)
                        }
                        Text("terms.accept".localized)
                            .font(.body)
                    }
                    .padding(.top, .paddingStandard)
                    .padding(.bottom, 80) // Space for button
                }
            }
            .padding()
        }
    }

    private var serviceSection: some View {
        Group {
            Text("terms.service.title".localized)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            Text("terms.service.content".localized)
                .font(.body)

            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("terms.service.tax_preparation".localized)
                bulletPoint("terms.service.document_management".localized)
                bulletPoint("terms.service.tax_calculations".localized)
                bulletPoint("terms.service.expert_chat".localized)
            }
        }
    }

    private var obligationsSection: some View {
        Group {
            Text("terms.obligations.title".localized)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            Text("terms.obligations.content".localized)
                .font(.body)

            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("terms.obligations.accurate_info".localized)
                bulletPoint("terms.obligations.legal_compliance".localized)
                bulletPoint("terms.obligations.account_security".localized)
                bulletPoint("terms.obligations.timely_submission".localized)
            }
        }
    }

    private var paymentSection: some View {
        Group {
            Text("terms.payment.title".localized)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            Text("terms.payment.content".localized)
                .font(.body)
        }
    }

    private var liabilitySection: some View {
        Group {
            Text("terms.liability.title".localized)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            Text("terms.liability.content".localized)
                .font(.body)

            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("terms.liability.disclaimer1".localized)
                bulletPoint("terms.liability.disclaimer2".localized)
                bulletPoint("terms.liability.disclaimer3".localized)
            }
        }
    }

    private var intellectualPropertySection: some View {
        Group {
            Text("terms.intellectual_property.title".localized)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            Text("terms.intellectual_property.content".localized)
                .font(.body)
        }
    }

    private var terminationSection: some View {
        Group {
            Text("terms.termination.title".localized)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            Text("terms.termination.content".localized)
                .font(.body)
        }
    }

    private var governingLawSection: some View {
        Group {
            Text("terms.governing_law.title".localized)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            Text("terms.governing_law.content".localized)
                .font(.body)
        }
    }

    private var contactSection: some View {
        Group {
            Text("terms.contact.title".localized)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            VStack(alignment: .leading, spacing: 4) {
                Text("Taxed GmbH")
                    .fontWeight(.medium)
                Text("terms.contact.address".localized)
                Link("support@taxed.ch", destination: URL(string: "mailto:support@taxed.ch")!)
                    .foregroundColor(.taxedPrimary)
                Link("www.taxed.ch", destination: URL(string: "https://www.taxed.ch")!)
                    .foregroundColor(.taxedPrimary)
            }
            .font(.body)
        }
    }

    private var bottomButton: some View {
        VStack {
            Spacer()
            Button(action: {
                if hasAccepted {
                    // Save acceptance
                    UserDefaults.standard.set(true, forKey: "hasAcceptedTerms")
                    UserDefaults.standard.set(Date(), forKey: "termsAcceptanceDate")
                    dismiss()
                }
            }) {
                Text("terms.continue".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hasAccepted ? Color.taxedPrimary : Color.gray)
                    .cornerRadius(.cornerRadiusMedium)
            }
            .disabled(!hasAccepted)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground).opacity(0),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    @ViewBuilder
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
            Text(text)
                .font(.body)
        }
    }
}

struct TermsOfServiceView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TermsOfServiceView(isOnboarding: false)
            TermsOfServiceView(isOnboarding: true)
        }
    }
}