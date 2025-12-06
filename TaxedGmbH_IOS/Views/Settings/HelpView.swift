//
//  HelpView.swift
//  TaxedGmbH_IOS
//
//  Help and FAQ view
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section(header: Text("Getting Started")) {
                HelpItem(question: "How do I upload documents?", answer: "Tap the Documents tab and use the camera or file picker to upload tax documents.")
                HelpItem(question: "How do I contact my tax expert?", answer: "Use the Chat tab to message your assigned tax expert directly.")
            }

            Section(header: Text("Tax Filing")) {
                HelpItem(question: "When is the tax deadline?", answer: "Tax deadlines vary by canton. Check the Tax Deadlines section in More for your specific deadline.")
                HelpItem(question: "What documents do I need?", answer: "Common documents include salary certificates, bank statements, and insurance receipts.")
            }

            Section(header: Text("Account & Security")) {
                HelpItem(question: "How is my data protected?", answer: "Your data is encrypted with AES-256 and stored in Swiss data centers complying with Swiss data protection laws.")
                HelpItem(question: "How do I reset my password?", answer: "Tap 'Forgot Password' on the login screen to receive a reset link via email.")
            }
        }
        .navigationTitle("more.help".localized)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Help")
    }
}

struct HelpItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        HelpView()
    }
}
