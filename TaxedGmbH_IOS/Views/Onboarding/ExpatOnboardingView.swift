//
//  ExpatOnboardingView.swift
//  TaxedGmbH_IOS
//
//  Expat-specific onboarding flow explaining Swiss tax system
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

// MARK: - Supporting Views

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

#Preview {
    ExpatOnboardingView()
}
