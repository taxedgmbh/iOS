//
//  ProcessStageView.swift
//  TaxedGmbH_IOS
//
//  Enhanced tax process flow with liquid glass design
//  Apple HIG compliant with premium glass aesthetic
//

import SwiftUI

// MARK: - Tax Process Stages

enum TaxProcessStage: Int, CaseIterable, Identifiable {
    case collecting = 0
    case uploading = 1
    case review = 2
    case approval = 3
    case payment = 4
    case submission = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .collecting: return "process.stage.collecting.title".localized
        case .uploading: return "process.stage.uploading.title".localized
        case .review: return "process.stage.review.title".localized
        case .approval: return "process.stage.approval.title".localized
        case .payment: return "process.stage.payment.title".localized
        case .submission: return "process.stage.submission.title".localized
        }
    }

    var icon: String {
        switch self {
        case .collecting: return "doc.text.magnifyingglass"
        case .uploading: return "icloud.and.arrow.up"
        case .review: return "person.text.rectangle"
        case .approval: return "checkmark.seal.fill"
        case .payment: return "creditcard.fill"
        case .submission: return "paperplane.fill"
        }
    }

    var description: String {
        switch self {
        case .collecting:
            return "process.stage.collecting.description".localized
        case .uploading:
            return "process.stage.uploading.description".localized
        case .review:
            return "process.stage.review.description".localized
        case .approval:
            return "process.stage.approval.description".localized
        case .payment:
            return "process.stage.payment.description".localized
        case .submission:
            return "process.stage.submission.description".localized
        }
    }

    var color: Color {
        switch self {
        case .collecting: return .blue
        case .uploading: return .cyan
        case .review: return .purple
        case .approval: return .green
        case .payment: return .orange
        case .submission: return .taxedPrimary
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Process Stage View

struct ProcessStageView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var firestoreService = FirestoreService.shared

    // Accessibility Environment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentStage: TaxProcessStage = .collecting
    @State private var documents: [TaxDocument] = []
    @State private var completionPercentage: Double = 0.0
    @State private var showUploadSheet = false
    @State private var showExpertChat = false

    // Animation States
    @State private var headerScale: CGFloat = 0.9
    @State private var contentOpacity: Double = 0
    @State private var progressAnimation: CGFloat = 0

    var body: some View {
        ZStack {
            // Animated Glass Background
            if !reduceTransparency {
                AnimatedGlassBackground()
            } else {
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
            }

            ScrollView {
                VStack(spacing: 24) {
                    // Logo Header with Progress Ring
                    headerSection
                        .padding(.top, 20)

                    // Current Stage Hero Card
                    currentStageHeroCard

                    // Progress Timeline
                    timelineSection

                    // Quick Actions Card
                    quickActionsCard

                    // Help Section
                    helpCard
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Process")
        .sheet(isPresented: $showUploadSheet) {
            DocumentUploadView()
        }
        .sheet(isPresented: $showExpertChat) {
            NavigationView {
                ExpertChatView()
            }
        }
        .task {
            await loadProcessData()
            animateEntrance()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            progressRingView
            headerTitleSection
        }
        .opacity(contentOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var headerAccessibilityLabel: String {
        let headerText = "process.header.accessibility".localized
        let stageTitle = currentStage.title
        let progressText = "process.progress.accessibility".localized
        return "\(headerText) \(stageTitle). \(progressText)"
    }

    private var progressRingView: some View {
        ZStack {
            progressRingBackground
            progressRingAnimated
            progressGlowBackground
            logoGlassCircle
            logoImage
        }
        .glow(color: currentStage.color, radius: 20)
        .scaleEffect(headerScale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("process.header.logo".localized)
    }

    private var progressRingBackground: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        currentStage.color.opacity(0.3),
                        currentStage.color.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 4
            )
            .frame(width: 140, height: 140)
    }

    private var progressRingAnimated: some View {
        Circle()
            .trim(from: 0, to: progressAnimation)
            .stroke(
                currentStage.gradient,
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .frame(width: 140, height: 140)
            .rotationEffect(.degrees(-90))
            .animation(
                reduceMotion ? .none : .spring(response: 1.2, dampingFraction: 0.8),
                value: progressAnimation
            )
    }

    @ViewBuilder
    private var progressGlowBackground: some View {
        if !reduceTransparency {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            currentStage.color.opacity(0.3),
                            currentStage.color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)
                .blur(radius: 20)
        }
    }

    private var logoGlassCircle: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 110, height: 110)
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                currentStage.color.opacity(0.6),
                                currentStage.color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
    }

    private var logoImage: some View {
        Image("taxed-logo")
            .resizable()
            .scaledToFit()
            .frame(width: 70, height: 70)
            .cornerRadius(14)
    }

    private var headerTitleSection: some View {
        VStack(spacing: 8) {
            Text("process.header.title".localized)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            HStack(spacing: 8) {
                Text("process.progress.step".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(currentStage.rawValue + 1)/\(TaxProcessStage.allCases.count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(currentStage.color)

                Text("•")
                    .foregroundColor(.secondary)

                Text("\(Int(progressPercentage))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(currentStage.color)
            }
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Current Stage Hero Card

    private var currentStageHeroCard: some View {
        VStack(spacing: 20) {
            // Stage Icon with Glow
            ZStack {
                if !reduceTransparency {
                    Circle()
                        .fill(currentStage.gradient)
                        .frame(width: 80, height: 80)
                        .blur(radius: 30)
                }

                Circle()
                    .fill(currentStage.gradient)
                    .frame(width: 80, height: 80)

                Image(systemName: currentStage.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .glow(color: currentStage.color, radius: 30)

            // Stage Title
            Text(currentStage.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Stage Description
            Text(currentStage.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Primary Action Button
            Button(action: { handleStageAction(currentStage) }) {
                HStack(spacing: 10) {
                    Image(systemName: currentStage.icon)
                        .font(.headline)

                    Text(actionButtonTitle(for: currentStage))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(currentStage.gradient)
                .cornerRadius(16)
                .shadow(color: currentStage.color.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(actionButtonTitle(for: currentStage))
            .accessibilityHint("process.action.hint".localized)
        }
        .padding(28)
        .glassCard(
            cornerRadius: 28,
            borderColor: currentStage.color.opacity(0.3),
            glowColor: currentStage.color.opacity(0.2)
        )
        .opacity(contentOpacity)
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                SectionHeaderView(
                    title: "process.timeline.title".localized,
                    systemImage: "list.bullet.clipboard.fill"
                )
                .foregroundColor(.primary)

                Spacer()

                Text("\(completedStagesCount)/\(TaxProcessStage.allCases.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }

            // Timeline Items
            VStack(spacing: 0) {
                ForEach(Array(TaxProcessStage.allCases.enumerated()), id: \.element.id) { index, stage in
                    ProcessStageRow(
                        stage: stage,
                        isActive: currentStage.rawValue == index,
                        isCompleted: currentStage.rawValue > index,
                        isLast: index == TaxProcessStage.allCases.count - 1,
                        onAction: {
                            handleStageAction(stage)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 24, borderColor: .white.opacity(0.3))
        .opacity(contentOpacity)
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        VStack(spacing: 16) {
            SectionHeaderView(
                title: "process.quick_actions.title".localized,
                systemImage: "bolt.fill"
            )
            .foregroundColor(.orange)

            VStack(spacing: 12) {
                // Upload Document
                ProcessQuickActionButton(
                    icon: "doc.badge.plus",
                    title: "process.quick_action.upload".localized,
                    color: .blue,
                    action: { showUploadSheet = true }
                )

                // Contact Expert
                ProcessQuickActionButton(
                    icon: "message.fill",
                    title: "process.quick_action.contact_expert".localized,
                    color: .purple,
                    action: { showExpertChat = true }
                )

                // View Documents
                ProcessQuickActionButton(
                    icon: "folder.fill",
                    title: "process.quick_action.view_documents".localized,
                    color: .green,
                    action: { /* Navigate to documents */ }
                )
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 24, borderColor: .orange.opacity(0.2))
        .opacity(contentOpacity)
    }

    // MARK: - Help Card

    private var helpCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.indigo)

                VStack(alignment: .leading, spacing: 4) {
                    Text("process.help.title".localized)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("process.help.description".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button {
                showExpertChat = true
            } label: {
                HStack {
                    Image(systemName: "message.fill")
                        .font(.headline)

                    Text("process.help.button".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [.indigo, .indigo.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: .indigo.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("process.help.button".localized)
            .accessibilityHint("process.help.accessibility_hint".localized)
        }
        .padding(20)
        .glassCard(
            cornerRadius: 20,
            borderColor: .indigo.opacity(0.3),
            glowColor: .indigo.opacity(0.1)
        )
        .opacity(contentOpacity)
    }

    // MARK: - Helper Properties

    private var progressPercentage: Double {
        let totalStages = Double(TaxProcessStage.allCases.count)
        let currentProgress = Double(currentStage.rawValue + 1)
        return (currentProgress / totalStages) * 100
    }

    private var completedStagesCount: Int {
        currentStage.rawValue
    }

    // MARK: - Actions

    private func handleStageAction(_ stage: TaxProcessStage) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        switch stage {
        case .collecting, .uploading:
            showUploadSheet = true
        case .review:
            showExpertChat = true
        case .approval:
            // TODO: Show approval details
            break
        case .payment:
            // TODO: Show payment details
            break
        case .submission:
            // TODO: Show submission status
            break
        }
    }

    private func actionButtonTitle(for stage: TaxProcessStage) -> String {
        switch stage {
        case .collecting, .uploading:
            return "process.action.upload_document".localized
        case .review:
            return "process.action.contact_expert".localized
        case .approval:
            return "process.action.show_details".localized
        case .payment:
            return "process.action.make_payment".localized
        case .submission:
            return "process.action.check_status".localized
        }
    }

    private func loadProcessData() async {
        guard let userId = authService.user?.id else { return }

        do {
            documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)

            // Determine current stage based on document status
            let totalDocs = documents.count
            let reviewedDocs = documents.filter { $0.status == .reviewed || $0.status == .approved }.count

            if totalDocs == 0 {
                currentStage = .collecting
            } else if reviewedDocs == 0 {
                currentStage = .uploading
            } else if reviewedDocs < totalDocs {
                currentStage = .review
            } else {
                currentStage = .approval
            }

            completionPercentage = totalDocs > 0 ? Double(reviewedDocs) / Double(totalDocs) * 100 : 0

            // Animate progress ring
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.5)) {
                progressAnimation = CGFloat(currentStage.rawValue + 1) / CGFloat(TaxProcessStage.allCases.count)
            }
        } catch {
            print("Error loading process data: \(error)")
        }
    }

    private func animateEntrance() {
        if !reduceMotion {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                headerScale = 1.0
            }

            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                contentOpacity = 1.0
            }
        } else {
            headerScale = 1.0
            contentOpacity = 1.0
        }
    }
}

// MARK: - Process Stage Row

struct ProcessStageRow: View {
    let stage: TaxProcessStage
    let isActive: Bool
    let isCompleted: Bool
    let isLast: Bool
    let onAction: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                // Circle
                ZStack {
                    Circle()
                        .fill(circleFillStyle)
                        .frame(width: 44, height: 44)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else if isActive {
                        Circle()
                            .fill(.white)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(stage.color, lineWidth: 3)
                            )
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.5))
                            .frame(width: 12, height: 12)
                    }
                }

                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? stage.color.opacity(0.3) : Color.secondary.opacity(0.2))
                        .frame(width: 3, height: 70)
                        .cornerRadius(1.5)
                }
            }
            .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: stage.icon)
                            .font(.system(size: 16))
                            .foregroundColor(isActive ? stage.color : .secondary)
                            .symbolRenderingMode(.hierarchical)

                        Text(stage.title)
                            .font(isActive ? .headline : .subheadline)
                            .fontWeight(isActive ? .bold : .semibold)
                            .foregroundColor(isActive ? stage.color : .primary)
                    }

                    Text(stage.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(isActive ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if isActive {
                    Button(action: onAction) {
                        HStack(spacing: 8) {
                            Image(systemName: stage.icon)
                                .font(.subheadline)

                            Text(actionButtonTitle)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(stage.gradient)
                        .cornerRadius(12)
                        .shadow(color: stage.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel(actionButtonTitle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stage.title). \(stage.description)")
        .accessibilityValue(isCompleted ? "process.accessibility.completed".localized : (isActive ? "process.accessibility.active".localized : "process.accessibility.pending".localized))
    }

    private var circleFillStyle: AnyShapeStyle {
        if isCompleted {
            return AnyShapeStyle(stage.gradient)
        } else {
            return AnyShapeStyle(Color.secondary.opacity(0.2))
        }
    }

    private var actionButtonTitle: String {
        switch stage {
        case .collecting, .uploading:
            return "process.action.upload_document".localized
        case .review:
            return "process.action.contact_expert".localized
        case .approval:
            return "process.action.show_details".localized
        case .payment:
            return "process.action.make_payment".localized
        case .submission:
            return "process.action.check_status".localized
        }
    }
}

// MARK: - Process Quick Action Button

struct ProcessQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ProcessStageView()
            .environmentObject(AuthenticationService())
    }
}
