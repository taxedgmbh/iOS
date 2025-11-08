//
//  ExpatOnboardingView.swift
//  TaxedGmbH_IOS
//
//  Expat-specific onboarding flow with integrated checklist
//  Guides users through Swiss tax system and preparation checklist
//

import SwiftUI

struct ExpatOnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localizationService = LocalizationService.shared
    @State private var currentPage = 0
    @State private var showChecklist = false

    let totalPages = 4

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentPage ? Color.taxedPrimary : Color.gray.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Content Pages
                TabView(selection: $currentPage) {
                    WelcomePageView()
                        .tag(0)

                    SwissTaxSystemPageView()
                        .tag(1)

                    RequiredDocumentsPageView()
                        .tag(2)

                    TimelinePageView()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation Buttons
                HStack {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            Text("onboarding.button.back".localized)
                                .foregroundColor(.taxedPrimary)
                        }
                    }

                    Spacer()

                    if currentPage < totalPages - 1 {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("onboarding.button.next".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.taxedPrimary)
                                .cornerRadius(25)
                        }
                    } else {
                        Button {
                            showChecklist = true
                        } label: {
                            Text("onboarding.button.get_started".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.taxedPrimary)
                                .cornerRadius(25)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("onboarding.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showChecklist) {
                ExpatChecklistView()
            }
        }
    }
}

// MARK: - Welcome Page

struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 80))
                .foregroundColor(.taxedPrimary)

            Text("onboarding.welcome.title".localized)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("onboarding.welcome.subtitle".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Swiss Tax System Page

struct SwissTaxSystemPageView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.taxedPrimary)
                    .frame(maxWidth: .infinity)

                Text("onboarding.tax_system.title".localized)
                    .font(.title2)
                    .fontWeight(.bold)

                InfoCardView(
                    icon: "1.circle.fill",
                    title: "onboarding.tax_system.federal.title".localized,
                    description: "onboarding.tax_system.federal.description".localized
                )

                InfoCardView(
                    icon: "2.circle.fill",
                    title: "onboarding.tax_system.cantonal.title".localized,
                    description: "onboarding.tax_system.cantonal.description".localized
                )

                InfoCardView(
                    icon: "3.circle.fill",
                    title: "onboarding.tax_system.municipal.title".localized,
                    description: "onboarding.tax_system.municipal.description".localized
                )

                InfoCardView(
                    icon: "globe.europe.africa",
                    title: "onboarding.tax_system.treaties.title".localized,
                    description: "onboarding.tax_system.treaties.description".localized,
                    color: .orange
                )
            }
            .padding()
        }
    }
}

// MARK: - Required Documents Page

struct RequiredDocumentsPageView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.taxedPrimary)
                    .frame(maxWidth: .infinity)

                Text("onboarding.documents.title".localized)
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 16) {
                    DocumentCategoryRow(
                        icon: "dollarsign.circle.fill",
                        title: "onboarding.documents.swiss_income".localized,
                        items: "onboarding.documents.swiss_income_items".localized
                    )

                    DocumentCategoryRow(
                        icon: "globe.europe.africa.fill",
                        title: "onboarding.documents.foreign_income".localized,
                        items: "onboarding.documents.foreign_income_items".localized,
                        color: .orange
                    )

                    DocumentCategoryRow(
                        icon: "building.columns.fill",
                        title: "onboarding.documents.pension".localized,
                        items: "onboarding.documents.pension_items".localized
                    )

                    DocumentCategoryRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "onboarding.documents.wealth".localized,
                        items: "onboarding.documents.wealth_items".localized
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Timeline Page

struct TimelinePageView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 60))
                    .foregroundColor(.taxedPrimary)
                    .frame(maxWidth: .infinity)

                Text("onboarding.timeline.title".localized)
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 20) {
                    TimelineItem(
                        month: "onboarding.timeline.jan_feb".localized,
                        task: "onboarding.timeline.jan_feb_task".localized
                    )

                    TimelineItem(
                        month: "onboarding.timeline.mar".localized,
                        task: "onboarding.timeline.mar_task".localized,
                        highlighted: true
                    )

                    TimelineItem(
                        month: "onboarding.timeline.apr_jun".localized,
                        task: "onboarding.timeline.apr_jun_task".localized
                    )

                    TimelineItem(
                        month: "onboarding.timeline.jul_sep".localized,
                        task: "onboarding.timeline.jul_sep_task".localized
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("onboarding.timeline.tip.title".localized)
                        .font(.headline)
                        .foregroundColor(.orange)

                    Text("onboarding.timeline.tip.description".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views for Onboarding

struct InfoCardView: View {
    let icon: String
    let title: String
    let description: String
    var color: Color = .blue

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DocumentCategoryRow: View {
    let icon: String
    let title: String
    let items: String
    var color: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            Text(items)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 28)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TimelineItem: View {
    let month: String
    let task: String
    var highlighted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(highlighted ? Color.taxedPrimary : Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(month)
                    .font(.headline)
                    .fontWeight(highlighted ? .bold : .regular)
                    .foregroundColor(highlighted ? .taxedPrimary : .primary)

                Text(task)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Checklist View (Integrated)

struct ExpatChecklistView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localizationService = LocalizationService.shared
    @ObservedObject private var checklistService = ChecklistService.shared
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
    ExpatOnboardingView()
}
