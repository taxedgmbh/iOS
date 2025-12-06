//
//  PrivacyPolicyView.swift
//  TaxedGmbH_IOS
//
//  Privacy Policy View
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: .paddingSpacious) {
                    // Last Updated
                    Text("privacy.last_updated".localized(with: "24.11.2024"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Introduction
                    Group {
                        Text("privacy.introduction.title".localized)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("privacy.introduction.content".localized)
                            .font(.body)
                    }

                    // Data Collection
                    Group {
                        Text("privacy.data_collection.title".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.top)

                        Text("privacy.data_collection.content".localized)
                            .font(.body)

                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("privacy.data_collection.personal".localized)
                            bulletPoint("privacy.data_collection.tax".localized)
                            bulletPoint("privacy.data_collection.documents".localized)
                            bulletPoint("privacy.data_collection.usage".localized)
                        }
                    }

                    // Data Storage
                    Group {
                        Text("privacy.data_storage.title".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.top)

                        Text("privacy.data_storage.content".localized)
                            .font(.body)
                    }

                    // Data Usage
                    Group {
                        Text("privacy.data_usage.title".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.top)

                        Text("privacy.data_usage.content".localized)
                            .font(.body)

                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("privacy.data_usage.service".localized)
                            bulletPoint("privacy.data_usage.support".localized)
                            bulletPoint("privacy.data_usage.compliance".localized)
                        }
                    }

                    // Data Sharing
                    Group {
                        Text("privacy.data_sharing.title".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.top)

                        Text("privacy.data_sharing.content".localized)
                            .font(.body)
                    }

                    // User Rights
                    Group {
                        Text("privacy.user_rights.title".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.top)

                        Text("privacy.user_rights.content".localized)
                            .font(.body)

                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("privacy.user_rights.access".localized)
                            bulletPoint("privacy.user_rights.correction".localized)
                            bulletPoint("privacy.user_rights.deletion".localized)
                            bulletPoint("privacy.user_rights.portability".localized)
                        }
                    }

                    // Security
                    Group {
                        Text("privacy.security.title".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.top)

                        Text("privacy.security.content".localized)
                            .font(.body)
                    }

                    // Contact
                    Group {
                        Text("privacy.contact.title".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.top)

                        Text("privacy.contact.content".localized)
                            .font(.body)

                        Link("support@taxed.ch", destination: URL(string: "mailto:support@taxed.ch")!)
                            .foregroundColor(.taxedPrimary)
                    }
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("common.done".localized) {
                    dismiss()
                }
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

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}