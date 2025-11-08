//
//  DataManagementView.swift
//  TaxedGmbH_IOS
//
//  Data management, export, and account deletion
//

import SwiftUI
import Firebase
import FirebaseStorage

struct DataManagementView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showExportAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var isExporting = false
    @State private var isDeleting = false
    @State private var exportMessage = ""
    @State private var showExportSuccess = false

    private let deleteConfirmationPhrase = "DELETE"

    var body: some View {
        List {
            // Export Data
            Section {
                Button(action: {
                    showExportAlert = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.data.export_data".localized)
                                .foregroundColor(.primary)
                            Text("settings.data.export_data.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)

                if showExportSuccess {
                    Label {
                        Text(exportMessage)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            } header: {
                Text("settings.data.export".localized)
            } footer: {
                Text("settings.data.export.footer".localized)
            }

            // Storage Usage
            Section {
                HStack {
                    Image(systemName: "externaldrive")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(width: 32)

                    Text("settings.data.storage_usage".localized)
                    Spacer()
                    Text("settings.data.calculating".localized)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(width: 32)

                    Text("settings.data.documents_count".localized)
                    Spacer()
                    Text("-")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("settings.data.usage".localized)
            }

            // Data Portability (GDPR)
            Section {
                NavigationLink(destination: Text("settings.data.gdpr_info".localized)) {
                    HStack {
                        Image(systemName: "lock.doc")
                            .font(.title3)
                            .foregroundColor(.green)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.data.portability".localized)
                            Text("settings.data.portability.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("settings.data.privacy".localized)
            } footer: {
                Text("settings.data.privacy.footer".localized)
            }

            // Delete Account
            Section {
                Button(action: {
                    showDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.data.delete_account".localized)
                                .foregroundColor(.red)
                            Text("settings.data.delete_account.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if isDeleting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isDeleting)
            } header: {
                Text("settings.data.danger_zone".localized)
            } footer: {
                Text("settings.data.danger_zone.footer".localized)
            }
        }
        .navigationTitle("settings.data.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("settings.data.export_alert.title".localized, isPresented: $showExportAlert) {
            Button("settings.data.cancel".localized, role: .cancel) { }
            Button("settings.data.export_alert.confirm".localized) {
                Task {
                    await exportAllData()
                }
            }
        } message: {
            Text("settings.data.export_alert.message".localized)
        }
        .alert("settings.data.delete_alert.title".localized, isPresented: $showDeleteAlert) {
            Button("settings.data.cancel".localized, role: .cancel) { }
            Button("settings.data.continue".localized, role: .destructive) {
                showDeleteConfirmation = true
            }
        } message: {
            Text("settings.data.delete_alert.message".localized)
        }
        .alert("settings.data.delete_confirmation.title".localized, isPresented: $showDeleteConfirmation) {
            TextField("settings.data.type_delete".localized, text: $deleteConfirmationText)
            Button("settings.data.cancel".localized, role: .cancel) {
                deleteConfirmationText = ""
            }
            Button("settings.data.delete".localized, role: .destructive) {
                if deleteConfirmationText.uppercased() == deleteConfirmationPhrase {
                    Task {
                        await deleteAccount()
                    }
                }
                deleteConfirmationText = ""
            }
            .disabled(deleteConfirmationText.uppercased() != deleteConfirmationPhrase)
        } message: {
            Text("settings.data.delete_confirmation.message".localized(with: deleteConfirmationPhrase))
        }
    }

    // MARK: - Export All Data

    private func exportAllData() async {
        isExporting = true
        defer { isExporting = false }

        // TODO: Implement actual export functionality
        // This should:
        // 1. Fetch all user documents
        // 2. Create a ZIP file
        // 3. Share via system share sheet

        try? await Task.sleep(nanoseconds: 2_000_000_000) // Simulate export

        exportMessage = "settings.data.export_success".localized
        showExportSuccess = true

        // Hide success message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showExportSuccess = false
        }
    }

    // MARK: - Delete Account

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            guard let userId = authService.user?.id else { return }

            // TODO: Implement complete account deletion
            // This should:
            // 1. Delete all documents from Storage
            // 2. Delete all Firestore data
            // 3. Delete user account from Firebase Auth
            // 4. Sign out

            print("🗑️ Deleting account: \(userId)")

            // For now, just sign out
            try authService.signOut()

        } catch {
            print("❌ Account deletion failed: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        DataManagementView()
            .environmentObject(AuthenticationService())
    }
}
