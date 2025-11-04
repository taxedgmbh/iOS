//
//  ExpatHubView.swift
//  TaxedGmbH_IOS
//
//  Unified hub for expat features following Apple HIG
//

import SwiftUI

struct ExpatHubView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localizationService = LocalizationService.shared
    @StateObject private var checklistService = ChecklistService.shared
    @State private var showOnboarding = false
    @State private var showChecklist = false
    @State private var showDocumentPrep = false
    @State private var showTaxCalculator = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    HeroSection()

                    // Progress Overview
                    ProgressOverviewCard(checklistService: checklistService)

                    // Quick Access Cards
                    VStack(spacing: 16) {
                        Text("expat.hub.quick_access".localized)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(), GridItem()], spacing: 16) {
                            QuickAccessCard(
                                icon: "graduationcap.fill",
                                title: "expat.hub.learn".localized,
                                subtitle: "expat.hub.learn_subtitle".localized,
                                color: .blue,
                                badge: nil
                            ) {
                                showOnboarding = true
                            }

                            QuickAccessCard(
                                icon: "checklist",
                                title: "expat.hub.checklist".localized,
                                subtitle: "expat.hub.checklist_subtitle".localized,
                                color: .green,
                                badge: checklistService.checkedCount > 0 ? "\(checklistService.checkedCount)/\(checklistService.totalItems)" : nil
                            ) {
                                showChecklist = true
                            }

                            QuickAccessCard(
                                icon: "doc.badge.gearshape.fill",
                                title: "expat.hub.prepare".localized,
                                subtitle: "expat.hub.prepare_subtitle".localized,
                                color: .orange,
                                badge: nil
                            ) {
                                showDocumentPrep = true
                            }

                            QuickAccessCard(
                                icon: "calculator.fill",
                                title: "expat.hub.calculator".localized,
                                subtitle: "expat.hub.calculator_subtitle".localized,
                                color: .purple,
                                badge: "Pro"
                            ) {
                                showTaxCalculator = true
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Resources Section
                    ResourcesSection()

                    // Important Dates
                    ImportantDatesCard()
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("expat.hub.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                ExpatOnboardingView()
            }
            .sheet(isPresented: $showChecklist) {
                ExpatChecklistView()
            }
            .sheet(isPresented: $showDocumentPrep) {
                DocumentPreparationView()
            }
            .sheet(isPresented: $showTaxCalculator) {
                TaxCalculatorView()
            }
        }
    }
}

// MARK: - Hero Section
struct HeroSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Unified icon that represents expat services
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.orange.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)

                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
            }

            Text("expat.hub.welcome".localized)
                .font(.title2)
                .fontWeight(.bold)

            Text("expat.hub.description".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Progress Overview Card
struct ProgressOverviewCard: View {
    @ObservedObject var checklistService: ChecklistService

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("expat.hub.your_progress".localized)
                        .font(.headline)

                    Text(String(format: "expat.hub.items_completed".localized, checklistService.checkedCount, checklistService.totalItems))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                CircularProgressView(
                    progress: checklistService.completionPercentage,
                    size: 60,
                    lineWidth: 6
                )
            }

            if checklistService.checkedCount > 0 && !checklistService.isComplete {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)

                    Text("expat.hub.keep_going".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            } else if checklistService.isComplete {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text("expat.hub.ready_to_file".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Quick Access Card
struct QuickAccessCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundColor(color)
                            .frame(width: 50, height: 50)
                            .background(color.opacity(0.15))
                            .cornerRadius(12)

                        VStack(spacing: 4) {
                            Text(title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)

                            Text(subtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color)
                            .cornerRadius(8)
                            .offset(x: -4, y: 4)
                    }
                }
            }
            .padding()
            .frame(height: 140)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Resources Section
struct ResourcesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("expat.hub.resources".localized)
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ResourceRow(
                    icon: "book.fill",
                    title: "expat.resource.guide".localized,
                    subtitle: "expat.resource.guide_subtitle".localized,
                    isExternal: false
                )

                ResourceRow(
                    icon: "globe",
                    title: "expat.resource.official".localized,
                    subtitle: "expat.resource.official_subtitle".localized,
                    isExternal: true
                )

                ResourceRow(
                    icon: "doc.text.fill",
                    title: "expat.resource.treaties".localized,
                    subtitle: "expat.resource.treaties_subtitle".localized,
                    isExternal: false
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Resource Row
struct ResourceRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isExternal: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: isExternal ? "arrow.up.right.square" : "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Important Dates Card
struct ImportantDatesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.exclamationmark")
                    .foregroundColor(.orange)
                Text("expat.hub.important_dates".localized)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                DateRow(date: "31 Mar", description: "expat.date.filing".localized, isHighlighted: true)
                DateRow(date: "30 Jun", description: "expat.date.extension".localized)
                DateRow(date: "31 Dec", description: "expat.date.year_end".localized)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Date Row
struct DateRow: View {
    let date: String
    let description: String
    var isHighlighted: Bool = false

    var body: some View {
        HStack {
            Text(date)
                .font(.caption)
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundColor(isHighlighted ? .orange : .secondary)
                .frame(width: 60, alignment: .leading)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.primary)

            if isHighlighted {
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ExpatHubView()
}