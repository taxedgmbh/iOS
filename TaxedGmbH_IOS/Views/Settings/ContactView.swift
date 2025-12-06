//
//  ContactView.swift
//  TaxedGmbH_IOS
//
//  Contact information and support
//

import SwiftUI

struct ContactView: View {
    var body: some View {
        List {
            Section(header: Text("Contact Information")) {
                ContactRow(icon: "envelope.fill", title: "Email", value: "support@taxed.ch", action: {
                    if let url = URL(string: "mailto:support@taxed.ch") {
                        UIApplication.shared.open(url)
                    }
                })

                ContactRow(icon: "phone.fill", title: "Phone", value: "+41 79 910 77 87", action: {
                    if let url = URL(string: "tel:+41799107787") {
                        UIApplication.shared.open(url)
                    }
                })
            }

            Section(header: Text("Business Hours")) {
                HStack {
                    Text("Monday - Friday")
                    Spacer()
                    Text("9:00 - 18:00")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Saturday - Sunday")
                    Spacer()
                    Text("Closed")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Address")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TaxedGmbH")
                        .font(.headline)
                    Text("Aegertenstrasse 10")
                    Text("2503 Biel/Bienne")
                    Text("Switzerland")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
            }

            Section(header: Text("Social Media")) {
                ContactRow(icon: "link", title: "Website", value: "www.taxed.ch", action: {
                    if let url = URL(string: "https://www.taxed.ch") {
                        UIApplication.shared.open(url)
                    }
                })

                ContactRow(icon: "link", title: "LinkedIn", value: "linkedin.com/company/taxed", action: {
                    if let url = URL(string: "https://www.linkedin.com/company/taxed") {
                        UIApplication.shared.open(url)
                    }
                })
            }
        }
        .navigationTitle("more.contact".localized)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Contact")
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.body)
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        ContactView()
    }
}
