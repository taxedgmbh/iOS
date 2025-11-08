//
//  CreateWorkspaceView.swift
//  TaxedGmbH_IOS
//
//  Simple view to create a new workspace manually
//

import SwiftUI

struct CreateWorkspaceView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var workspaceManager = WorkspaceManager.shared

    @State private var workspaceName = ""
    @State private var workspaceType: WorkspaceType = .personal
    @State private var workspaceDescription = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workspace Details")) {
                    TextField("Workspace Name", text: $workspaceName)
                        .autocapitalization(.words)

                    Picker("Type", selection: $workspaceType) {
                        Text("Personal").tag(WorkspaceType.personal)
                        Text("Joint (Married/Partner)").tag(WorkspaceType.joint)
                        Text("Family").tag(WorkspaceType.family)
                        Text("Business").tag(WorkspaceType.business)
                    }

                    TextField("Description (Optional)", text: $workspaceDescription)
                }

                Section(header: Text("Tax Year")) {
                    HStack {
                        Text("Tax Year")
                        Spacer()
                        Text(String(format: "%d", currentYear))
                            .foregroundColor(.secondary)
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: createWorkspace) {
                        HStack {
                            Spacer()
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Creating...")
                                    .padding(.leading, 8)
                            } else {
                                Text("Create Workspace")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(workspaceName.isEmpty || isCreating)
                }
            }
            .navigationTitle("Create Workspace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }
            }
        }
        .onAppear {
            // Set default workspace name based on type
            if workspaceName.isEmpty {
                workspaceName = "Personal Taxes"
            }
        }
    }

    private func createWorkspace() {
        guard let user = authService.user else {
            errorMessage = "No user found. Please sign in again."
            return
        }

        guard !workspaceName.isEmpty else {
            errorMessage = "Please enter a workspace name"
            return
        }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                let description = workspaceDescription.isEmpty ? "Your tax documents and filings" : workspaceDescription

                let workspace = try await workspaceManager.createWorkspace(
                    name: workspaceName,
                    type: workspaceType,
                    taxYear: currentYear,
                    owner: user,
                    description: description
                )

                print("✅ Successfully created workspace: \(workspace.name)")

                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("❌ Error creating workspace: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to create workspace: \(error.localizedDescription)"
                    isCreating = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CreateWorkspaceView()
            .environmentObject(AuthenticationService())
    }
}
