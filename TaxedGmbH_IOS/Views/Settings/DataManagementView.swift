//
//  DataManagementView.swift
//  TaxedGmbH_IOS
//
//  GDPR-compliant data management, export, and account deletion
//

import SwiftUI
import Firebase
import FirebaseStorage

struct DataManagementView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var dataService = DataManagementService.shared

    @State private var showExportAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showWorkspaceWarning = false
    @State private var deleteConfirmationText = ""
    @State private var exportMessage = ""
    @State private var showExportSuccess = false
    @State private var workspaceConflicts: [Workspace] = []
    @State private var deleteErrorMessage = ""
    @State private var showShareSheet = false
    @State private var exportURL: URL?

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

                        if dataService.isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(dataService.isExporting)

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

                    if dataService.isCalculating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if dataService.storageUsed > 0 {
                        Text(dataService.formatBytes(dataService.storageUsed))
                            .foregroundColor(.secondary)
                    } else {
                        Text("settings.data.calculating".localized)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(width: 32)

                    Text("settings.data.documents_count".localized)
                    Spacer()
                    Text("\(dataService.documentCount)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("settings.data.usage".localized)
            } footer: {
                if !dataService.isCalculating && dataService.storageUsed == 0 {
                    Button(action: {
                        Task {
                            guard let userId = authService.user?.id else { return }
                            await dataService.calculateStorageUsage(for: userId)
                        }
                    }) {
                        Label("Refresh Storage Usage", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                }
            }

            // Data Portability (GDPR)
            Section {
                NavigationLink(destination: GDPRInfoView()) {
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
                    Task {
                        await checkWorkspaceConflicts()
                    }
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

                        if dataService.isDeleting {
                            ProgressView()
                        }
                    }
                }
                .disabled(dataService.isDeleting)

                if !deleteErrorMessage.isEmpty {
                    Label {
                        Text(deleteErrorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            } header: {
                Text("settings.data.danger_zone".localized)
            } footer: {
                Text("settings.data.danger_zone.footer".localized)
            }
        }
        .navigationTitle("settings.data.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Data Management")
        .onAppear {
            // Calculate storage usage when view appears
            Task {
                guard let userId = authService.user?.id else { return }
                if dataService.storageUsed == 0 {
                    await dataService.calculateStorageUsage(for: userId)
                }
            }
        }
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
        .alert("Workspace Conflicts", isPresented: $showWorkspaceWarning) {
            Button("Cancel", role: .cancel) {
                workspaceConflicts = []
            }
            Button("Proceed Anyway", role: .destructive) {
                showDeleteAlert = true
            }
        } message: {
            if let first = workspaceConflicts.first {
                if workspaceConflicts.count == 1 {
                    Text("You are part of the shared workspace '\(first.name)'. Other members will lose access to documents if you delete your account. Are you sure you want to proceed?")
                } else {
                    Text("You are part of \(workspaceConflicts.count) shared workspaces. Other members will lose access to documents if you delete your account. Are you sure you want to proceed?")
                }
            }
        }
        .alert("settings.data.delete_alert.title".localized, isPresented: $showDeleteAlert) {
            Button("settings.data.cancel".localized, role: .cancel) {
                workspaceConflicts = []
            }
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
                workspaceConflicts = []
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
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Export All Data

    private func exportAllData() async {
        guard let userId = authService.user?.id,
              let userName = authService.user?.name else { return }

        do {
            let zipURL = try await dataService.exportAllData(for: userId, userName: userName)

            await MainActor.run {
                exportURL = zipURL
                showShareSheet = true
                exportMessage = "settings.data.export_success".localized
                showExportSuccess = true

                // Hide success message after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showExportSuccess = false
                }
            }
        } catch {
            print("❌ Export failed: \(error)")
            await MainActor.run {
                exportMessage = "Export failed: \(error.localizedDescription)"
                showExportSuccess = false
            }
        }
    }

    // MARK: - Workspace Conflict Check

    private func checkWorkspaceConflicts() async {
        guard let userId = authService.user?.id else { return }

        do {
            let (canDelete, reason, conflicts) = try await dataService.canDeleteAccount(userId: userId)

            await MainActor.run {
                if !canDelete {
                    workspaceConflicts = conflicts
                    showWorkspaceWarning = true
                    deleteErrorMessage = reason ?? ""
                } else {
                    // No conflicts - proceed to delete alert
                    showDeleteAlert = true
                    deleteErrorMessage = ""
                }
            }
        } catch {
            await MainActor.run {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Delete Account

    private func deleteAccount() async {
        guard let userId = authService.user?.id else { return }

        do {
            // Force delete if user confirmed despite workspace conflicts
            let forceDelete = !workspaceConflicts.isEmpty

            try await dataService.deleteAccount(userId: userId, forceDelete: forceDelete)

            // Account deleted successfully - auth service will handle sign out
            print("✅ Account deleted successfully")

        } catch {
            print("❌ Account deletion failed: \(error)")
            await MainActor.run {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - GDPR Info View

struct GDPRInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Rights Under GDPR")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 12) {
                    InfoSection(
                        title: "Right to Access",
                        description: "You have the right to access all personal data we store about you. Use the 'Export Data' feature to download a copy."
                    )

                    InfoSection(
                        title: "Right to Portability",
                        description: "Your exported data is provided in machine-readable JSON format, making it easy to transfer to other services."
                    )

                    InfoSection(
                        title: "Right to Erasure",
                        description: "You have the right to have your personal data deleted. Use the 'Delete Account' feature to permanently remove all your data."
                    )

                    InfoSection(
                        title: "Data Processing",
                        description: "We process your tax documents solely for the purpose of helping you file your Swiss tax returns. Your data is stored securely on Firebase servers in Europe."
                    )

                    InfoSection(
                        title: "Data Retention",
                        description: "Your documents are retained until you delete them or close your account. We recommend keeping tax documents for 10 years as required by Swiss law."
                    )
                }
                .padding(.vertical)

                Text("For questions about data privacy, contact: privacy@taxed.ch")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("GDPR Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoSection: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        DataManagementView()
            .environmentObject(AuthenticationService())
    }
}
