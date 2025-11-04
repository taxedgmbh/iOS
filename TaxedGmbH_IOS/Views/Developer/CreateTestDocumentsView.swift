//
//  CreateTestDocumentsView.swift
//  TaxedGmbH_IOS
//
//  Developer utility to create test documents in Firestore
//

import SwiftUI

struct CreateTestDocumentsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var firestoreService = FirestoreService.shared

    @State private var isCreating = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    @State private var createdCount = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text("Developer Tool")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Create Test Documents for Testing")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This will create 5 test documents in Firestore:")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Lohnausweis 2024", systemImage: "doc.text.fill")
                            Label("Spesenbeleg Restaurant", systemImage: "doc.text.fill")
                            Label("Bank Statement UBS", systemImage: "doc.text.fill")
                            Label("Health Insurance Premium", systemImage: "doc.text.fill")
                            Label("Pillar 3a Certificate", systemImage: "doc.text.fill")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Create Button
                    if !isCreating {
                        Button {
                            Task {
                                await createTestDocuments()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Create Test Documents")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // Loading
                    if isCreating {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Creating test documents...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }

                    // Success Message
                    if let success = successMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)

                            Text(success)
                                .font(.headline)
                                .foregroundColor(.green)

                            Text("Go to Documents tab to see them")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Error Message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                                .font(.subheadline)
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Dev Tools")
                        .font(.headline)
                }
            }
        }
    }

    private func createTestDocuments() async {
        guard let userId = authService.user?.id else {
            errorMessage = "Not logged in"
            return
        }

        isCreating = true
        errorMessage = nil
        successMessage = nil
        createdCount = 0

        let testDocuments: [(name: String, category: TaxCategory, subcategory: String, amount: Double?, aiConfidence: Double, summary: String)] = [
            (
                name: "Lohnausweis_2024.pdf",
                category: .income,
                subcategory: "lohnausweis",
                amount: 85000.50,
                aiConfidence: 0.95,
                summary: "Lohnausweis from employer XYZ AG"
            ),
            (
                name: "Spesenbeleg_Restaurant.pdf",
                category: .deduction,
                subcategory: "spesenbeleg",
                amount: 125.80,
                aiConfidence: 0.88,
                summary: "Business lunch expense - Restaurant ABC"
            ),
            (
                name: "Bank_Statement_UBS.pdf",
                category: .wealth,
                subcategory: "bank_statement",
                amount: 45000.00,
                aiConfidence: 0.91,
                summary: "UBS Bank Statement - December 2024"
            ),
            (
                name: "Health_Insurance_Premium.pdf",
                category: .deduction,
                subcategory: "health_insurance",
                amount: 4500.00,
                aiConfidence: 0.93,
                summary: "CSS Health Insurance Annual Premium"
            ),
            (
                name: "Pillar_3a_Certificate.pdf",
                category: .pillar,
                subcategory: "pillar_3a",
                amount: 7056.00,
                aiConfidence: 0.97,
                summary: "Pillar 3a contribution certificate"
            )
        ]

        do {
            for testDoc in testDocuments {
                let document = TaxDocument(
                    customerId: userId,
                    name: testDoc.name,
                    storageUrl: "https://firebasestorage.googleapis.com/test/\(testDoc.name)",
                    category: testDoc.category,
                    subcategory: testDoc.subcategory,
                    aiConfidence: testDoc.aiConfidence,
                    extractedText: "Test document - \(testDoc.name)",
                    aiSummary: testDoc.summary,
                    status: testDoc.aiConfidence > 0.9 ? .pending : .processing,
                    taxYear: 2024,
                    canton: authService.user?.canton,
                    amount: testDoc.amount
                )

                try await firestoreService.createDocument(document)
                createdCount += 1
                print("✅ Created test document: \(testDoc.name)")
            }

            isCreating = false
            successMessage = "Successfully created \(createdCount) test documents!"

        } catch {
            isCreating = false
            errorMessage = "Failed to create documents: \(error.localizedDescription)"
            print("❌ Error creating test documents: \(error)")
        }
    }
}

#Preview {
    CreateTestDocumentsView()
        .environmentObject(AuthenticationService())
}
