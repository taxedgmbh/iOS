//
//  CantonSettingsView.swift
//  TaxedGmbH_IOS
//
//  Swiss canton selection and canton-specific settings
//

import SwiftUI
import FirebaseFirestore

struct CantonSettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var firestoreService = FirestoreService.shared
    @State private var selectedCanton: String?
    @State private var showCantonPicker = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    private let cantonHelper = SwissCantonHelper.shared

    var body: some View {
        List {
            // Canton Selection
            Section {
                Button(action: {
                    showCantonPicker = true
                }) {
                    HStack {
                        Image(systemName: "mappin.circle")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.canton.current_canton".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let canton = authService.user?.canton {
                                Text(cantonHelper.getCantonDisplayName(forId: canton))
                                    .font(.body)
                                    .foregroundColor(.primary)
                            } else {
                                Text("settings.canton.not_set".localized)
                                    .font(.body)
                                    .foregroundColor(.orange)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("settings.canton.selection".localized)
            } footer: {
                Text("settings.canton.selection.footer".localized)
            }

            // Canton-Specific Information
            if let cantonId = authService.user?.canton,
               let canton = cantonHelper.getCanton(byId: cantonId) {

                Section {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 32)

                        Text("settings.canton.tax_deadline".localized)
                        Spacer()
                        Text(canton.taxDeadline)
                            .foregroundColor(.secondary)
                    }

                    if canton.hasOnlinePortal {
                        Button(action: {
                            if let url = canton.portalUrl.flatMap(URL.init) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 32)

                                Text("settings.canton.online_portal".localized)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Text("settings.canton.info_section".localized)
                } footer: {
                    Text("settings.canton.info_section.footer".localized)
                }

                // Municipality Info
                Section {
                    if let municipality = authService.user?.municipality {
                        HStack {
                            Image(systemName: "building.2")
                                .font(.title3)
                                .foregroundColor(.purple)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("settings.canton.municipality".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(municipality)
                                    .font(.body)
                            }
                        }

                        if let municipalityId = authService.user?.municipalityId {
                            HStack {
                                Image(systemName: "number")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                    .frame(width: 32)

                                Text("settings.canton.municipality_id".localized)
                                Spacer()
                                Text(municipalityId)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text("settings.canton.municipality.not_set".localized)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                } header: {
                    Text("settings.canton.municipality_section".localized)
                } footer: {
                    Text("settings.canton.municipality_section.footer".localized)
                }
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
        .navigationTitle("settings.canton.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCantonPicker) {
            NavigationView {
                List {
                    ForEach(cantonHelper.allCantons) { canton in
                        Button(action: {
                            Task {
                                await changeCanton(to: canton.id)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(canton.displayName)
                                        .foregroundColor(.primary)
                                    Text(canton.id)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if canton.id == authService.user?.canton {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.taxedPrimary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("settings.canton.select_canton".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("settings.canton.cancel".localized) {
                            showCantonPicker = false
                        }
                    }
                }
            }
        }
    }

    private func changeCanton(to cantonId: String) async {
        guard let userId = authService.user?.id else {
            errorMessage = "settings.canton.error.no_user".localized
            return
        }

        do {
            let data: [String: Any] = [
                "canton": cantonId,
                "updatedAt": Timestamp(date: Date())
            ]
            try await authService.updateUser(userId: userId, data: data)
            successMessage = "settings.canton.changed".localized(with: cantonHelper.getCantonDisplayName(forId: cantonId))
            showCantonPicker = false

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
        CantonSettingsView()
            .environmentObject(AuthenticationService())
    }
}
