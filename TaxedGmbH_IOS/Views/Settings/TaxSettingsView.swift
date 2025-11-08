//
//  TaxSettingsView.swift
//  TaxedGmbH_IOS
//
//  Tax-specific settings: tax year selection, workspace management
//

import SwiftUI

struct TaxSettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var workspaceManager = WorkspaceManager.shared
    @State private var selectedYear: Int
    @State private var showYearPicker = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isLoadingWorkspace = true
    @State private var showCreateWorkspace = false

    init() {
        let currentYear = Calendar.current.component(.year, from: Date())
        _selectedYear = State(initialValue: currentYear)
    }

    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...(currentYear + 1)).reversed()
    }

    var body: some View {
        Group {
            if isLoadingWorkspace {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("settings.tax.loading_workspace".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                mainContent
            }
        }
        .navigationTitle("settings.tax.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showYearPicker) {
            yearPickerSheet
        }
        .sheet(isPresented: $showCreateWorkspace) {
            CreateWorkspaceView()
                .environmentObject(authService)
        }
        .onChange(of: showCreateWorkspace) { newValue in
            // Reload workspace when create sheet is dismissed
            if !newValue {
                Task {
                    await loadWorkspace()
                }
            }
        }
        .task {
            await loadWorkspace()
        }
    }

    private var mainContent: some View {
        List {
            // Tax Year Selection
            Section {
                if let workspace = workspaceManager.currentWorkspace {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.tax.tax_year".localized)
                                .font(.body)
                            Text("settings.tax.tax_year.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("\(workspace.taxYear)") {
                            selectedYear = workspace.taxYear
                            showYearPicker = true
                        }
                        .foregroundColor(.taxedPrimary)
                        .font(.body.weight(.semibold))
                    }
                } else {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("settings.tax.no_workspace".localized)
                                .foregroundColor(.secondary)
                        }

                        Button(action: {
                            showCreateWorkspace = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("settings.tax.create_workspace".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.taxedPrimary)
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("settings.tax.year_section".localized)
            } footer: {
                Text("settings.tax.year_section.footer".localized)
            }

            // Workspace Info
            if let workspace = workspaceManager.currentWorkspace {
                Section {
                    HStack {
                        Image(systemName: "folder")
                            .font(.title3)
                            .foregroundColor(.purple)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.tax.workspace_name".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(workspace.name)
                                .font(.body)
                        }
                    }

                    HStack {
                        Image(systemName: "person.2")
                            .font(.title3)
                            .foregroundColor(.green)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.tax.workspace_type".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(workspace.type.rawValue.capitalized)
                                .font(.body)
                        }
                    }

                    HStack {
                        Image(systemName: "person.3")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 32)

                        Text("settings.tax.workspace_members".localized)
                        Spacer()
                        Text("\(workspace.members.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("settings.tax.workspace_section".localized)
                } footer: {
                    Text("settings.tax.workspace_section.footer".localized)
                }
            }

            // Tax Filing Status
            Section {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 32)

                    Text("settings.tax.filing_status".localized)
                    Spacer()
                    Text("settings.tax.filing_status.in_progress".localized)
                        .foregroundColor(.orange)
                        .font(.caption)
                }

                if let canton = authService.user?.canton {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 32)

                        Text("settings.tax.filing_canton".localized)
                        Spacer()
                        Text(SwissCantonHelper.shared.getCantonDisplayName(forId: canton))
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("settings.tax.status_section".localized)
            }

            // Messages
            if !errorMessage.isEmpty {
                Section {
                    Label {
                        Text(errorMessage)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            }

            if !successMessage.isEmpty {
                Section {
                    Label {
                        Text(successMessage)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    private var yearPickerSheet: some View {
        NavigationView {
            List {
                ForEach(availableYears, id: \.self) { year in
                    Button(action: {
                        Task {
                            await changeTaxYear(to: year)
                        }
                    }) {
                        HStack {
                            Text(String(year))
                                .foregroundColor(.primary)
                            Spacer()
                            if year == workspaceManager.currentWorkspace?.taxYear {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.taxedPrimary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("settings.tax.select_year".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("settings.tax.cancel".localized) {
                        showYearPicker = false
                    }
                }
            }
        }
    }

    private func loadWorkspace() async {
        guard let userId = authService.user?.id else {
            await MainActor.run {
                isLoadingWorkspace = false
                errorMessage = "settings.tax.error.no_user".localized
            }
            return
        }

        do {
            await workspaceManager.loadCurrentWorkspace(userId: userId)
            await MainActor.run {
                isLoadingWorkspace = false

                // If no workspace found, show error
                if workspaceManager.currentWorkspace == nil {
                    errorMessage = "settings.tax.error.no_workspace_found".localized
                }
            }
        } catch {
            await MainActor.run {
                isLoadingWorkspace = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func changeTaxYear(to year: Int) async {
        guard let workspace = workspaceManager.currentWorkspace else {
            errorMessage = "settings.tax.error.no_workspace".localized
            return
        }

        var updatedWorkspace = workspace
        updatedWorkspace.taxYear = year
        updatedWorkspace.updatedAt = Date()

        do {
            try await workspaceManager.updateWorkspace(updatedWorkspace)
            successMessage = "settings.tax.year_changed".localized(with: String(year))
            showYearPicker = false

            // Clear message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = ""
            }
        } catch {
            errorMessage = error.localizedDescription
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                errorMessage = ""
            }
        }
    }
}

#Preview {
    NavigationView {
        TaxSettingsView()
            .environmentObject(AuthenticationService())
    }
}
