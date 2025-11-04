//
//  ExpatChecklistView.swift
//  TaxedGmbH_IOS
//
//  Interactive checklist for expat tax filing preparation
//

import SwiftUI

struct ExpatChecklistView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localizationService = LocalizationService.shared
    @StateObject private var checklistService = ChecklistService.shared
    @State private var navigateToUpload = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("checklist.title".localized)
                            .font(.title)
                            .fontWeight(.bold)

                        Text("checklist.subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("checklist.progress".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("\(checklistService.checkedCount)/\(checklistService.totalItems)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.taxedPrimary)
                        }

                        ProgressView(value: checklistService.completionPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: .taxedPrimary))
                            .scaleEffect(x: 1, y: 2)
                    }
                    .padding(.horizontal)

                    // Checklist Sections
                    ChecklistSection(
                        title: "checklist.section.personal.title".localized,
                        items: [
                            ChecklistItem(id: "residence_permit", text: "checklist.item.residence_permit".localized),
                            ChecklistItem(id: "registration_cert", text: "checklist.item.registration_cert".localized),
                            ChecklistItem(id: "passport_copy", text: "checklist.item.passport_copy".localized)
                        ],
                        checklistService: checklistService
                    )

                    ChecklistSection(
                        title: "checklist.section.swiss_income.title".localized,
                        items: [
                            ChecklistItem(id: "swiss_salary", text: "checklist.item.swiss_salary".localized),
                            ChecklistItem(id: "swiss_bank", text: "checklist.item.swiss_bank".localized),
                            ChecklistItem(id: "pillar", text: "checklist.item.pillar".localized),
                            ChecklistItem(id: "swiss_investments", text: "checklist.item.swiss_investments".localized)
                        ],
                        checklistService: checklistService
                    )

                    ChecklistSection(
                        title: "checklist.section.foreign_income.title".localized,
                        items: [
                            ChecklistItem(id: "foreign_salary", text: "checklist.item.foreign_salary".localized),
                            ChecklistItem(id: "foreign_pension", text: "checklist.item.foreign_pension".localized),
                            ChecklistItem(id: "foreign_bank", text: "checklist.item.foreign_bank".localized),
                            ChecklistItem(id: "foreign_investments", text: "checklist.item.foreign_investments".localized),
                            ChecklistItem(id: "rental_income", text: "checklist.item.rental_income".localized)
                        ],
                        checklistService: checklistService,
                        color: .orange
                    )

                    ChecklistSection(
                        title: "checklist.section.tax_documents.title".localized,
                        items: [
                            ChecklistItem(id: "tax_treaty_cert", text: "checklist.item.tax_treaty_cert".localized),
                            ChecklistItem(id: "foreign_tax_paid", text: "checklist.item.foreign_tax_paid".localized),
                            ChecklistItem(id: "double_tax", text: "checklist.item.double_tax".localized)
                        ],
                        checklistService: checklistService,
                        color: .orange
                    )

                    ChecklistSection(
                        title: "checklist.section.deductions.title".localized,
                        items: [
                            ChecklistItem(id: "health_insurance", text: "checklist.item.health_insurance".localized),
                            ChecklistItem(id: "moving_costs", text: "checklist.item.moving_costs".localized),
                            ChecklistItem(id: "professional_expenses", text: "checklist.item.professional_expenses".localized),
                            ChecklistItem(id: "donations", text: "checklist.item.donations".localized)
                        ],
                        checklistService: checklistService
                    )

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            // Close and mark checklist as viewed
                            dismiss()
                        } label: {
                            HStack {
                                Text("checklist.button.start_upload".localized)
                                    .fontWeight(.semibold)

                                if checklistService.isComplete {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.taxedPrimary)
                            .cornerRadius(12)
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("checklist.button.close".localized)
                                .foregroundColor(.taxedPrimary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        checklistService.resetChecklist()
                    } label: {
                        Text("checklist.button.reset".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Checklist Models

struct ChecklistItem: Identifiable {
    let id: String
    let text: String
}

// MARK: - Checklist Section View

struct ChecklistSection: View {
    let title: String
    let items: [ChecklistItem]
    @ObservedObject var checklistService: ChecklistService
    var color: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(items) { item in
                    ChecklistItemRow(
                        item: item,
                        isChecked: checklistService.isItemChecked(item.id),
                        color: color
                    ) {
                        checklistService.toggleItem(item.id)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Checklist Item Row

struct ChecklistItemRow: View {
    let item: ChecklistItem
    let isChecked: Bool
    let color: Color
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isChecked ? color : .gray.opacity(0.3))

                Text(item.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isChecked ? color.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isChecked ? color.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExpatChecklistView()
}
