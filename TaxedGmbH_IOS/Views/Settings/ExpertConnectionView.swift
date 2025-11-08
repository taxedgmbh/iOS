//
//  ExpertConnectionView.swift
//  TaxedGmbH_IOS
//
//  Tax expert consultation booking and connection management
//

import SwiftUI

struct ExpertConnectionView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var hasExpert = false
    @State private var showBookingSheet = false
    @State private var selectedConsultationType: ConsultationType = .general
    @State private var preferredDate = Date()
    @State private var additionalNotes = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""

    enum ConsultationType: String, CaseIterable, Identifiable {
        case general = "general"
        case document = "document"
        case filing = "filing"
        case optimization = "optimization"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .general:
                return "settings.expert.consultation.general".localized
            case .document:
                return "settings.expert.consultation.document".localized
            case .filing:
                return "settings.expert.consultation.filing".localized
            case .optimization:
                return "settings.expert.consultation.optimization".localized
            }
        }

        var icon: String {
            switch self {
            case .general:
                return "bubble.left.and.bubble.right"
            case .document:
                return "doc.text"
            case .filing:
                return "checkmark.circle"
            case .optimization:
                return "chart.line.uptrend.xyaxis"
            }
        }
    }

    var body: some View {
        List {
            // Expert Status
            Section {
                if hasExpert {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.expert.assigned_expert".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("settings.expert.expert_name".localized)
                                .font(.body)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.expert.no_expert".localized)
                                .font(.body)
                            Text("settings.expert.no_expert.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("settings.expert.status".localized)
            }

            // Book Consultation
            Section {
                Button(action: {
                    showBookingSheet = true
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.expert.book_consultation".localized)
                                .foregroundColor(.primary)
                            Text("settings.expert.book_consultation.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("settings.expert.consultations".localized)
            } footer: {
                Text("settings.expert.consultations.footer".localized)
            }

            // Expert Features
            Section {
                NavigationLink(destination: Text("settings.expert.chat".localized)) {
                    HStack {
                        Image(systemName: "message")
                            .font(.title3)
                            .foregroundColor(.green)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.expert.chat_feature".localized)
                            Text("settings.expert.chat_feature.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                NavigationLink(destination: Text("settings.expert.document_review".localized)) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.purple)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.expert.document_review".localized)
                            Text("settings.expert.document_review.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                NavigationLink(destination: Text("settings.expert.tax_optimization".localized)) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.expert.tax_optimization".localized)
                            Text("settings.expert.tax_optimization.subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("settings.expert.features".localized)
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
        .navigationTitle("settings.expert.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBookingSheet) {
            NavigationView {
                Form {
                    Section {
                        Picker("settings.expert.booking.type".localized, selection: $selectedConsultationType) {
                            ForEach(ConsultationType.allCases) { type in
                                Label(type.displayName, systemImage: type.icon)
                                    .tag(type)
                            }
                        }

                        DatePicker("settings.expert.booking.date".localized,
                                 selection: $preferredDate,
                                 in: Date()...,
                                 displayedComponents: [.date, .hourAndMinute])
                    } header: {
                        Text("settings.expert.booking.details".localized)
                    }

                    Section {
                        TextEditor(text: $additionalNotes)
                            .frame(minHeight: 100)
                    } header: {
                        Text("settings.expert.booking.notes".localized)
                    } footer: {
                        Text("settings.expert.booking.notes.footer".localized)
                    }
                }
                .navigationTitle("settings.expert.booking.title".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("settings.expert.cancel".localized) {
                            showBookingSheet = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("settings.expert.booking.submit".localized) {
                            bookConsultation()
                        }
                    }
                }
            }
        }
        .onAppear {
            checkExpertStatus()
        }
    }

    private func checkExpertStatus() {
        hasExpert = authService.user?.assignedExpertId != nil
    }

    private func bookConsultation() {
        // TODO: Implement booking logic
        successMessage = "settings.expert.booking.success".localized
        showBookingSheet = false

        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            successMessage = ""
        }
    }
}

#Preview {
    NavigationView {
        ExpertConnectionView()
            .environmentObject(AuthenticationService())
    }
}
