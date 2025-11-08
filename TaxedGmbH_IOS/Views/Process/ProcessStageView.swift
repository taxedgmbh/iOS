import SwiftUI

// MARK: - Tax Process Stages

enum TaxProcessStage: Int, CaseIterable {
    case collecting = 0
    case uploading = 1
    case review = 2
    case approval = 3
    case payment = 4
    case submission = 5

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
        case .approval: return "checkmark.seal"
        case .payment: return "creditcard"
        case .submission: return "paperplane"
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
        // All stages use Taxed red branding
        return .taxedPrimary
    }
}

// MARK: - Process Stage View

struct ProcessStageView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var firestoreService = FirestoreService.shared

    @State private var currentStage: TaxProcessStage = .collecting
    @State private var documents: [TaxDocument] = []
    @State private var completionPercentage: Double = 0.0
    @State private var showUploadSheet = false
    @State private var showExpertChat = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Branded header with logo and progress
                VStack(spacing: 16) {
                    // Logo and progress indicator
                    HStack(spacing: 12) {
                        Image("taxed-logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 32)

                        Spacer()

                        // Clean progress text
                        Text("\(currentStage.rawValue + 1)/\(TaxProcessStage.allCases.count)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.taxedPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.taxedPrimary)
                                .frame(
                                    width: geometry.size.width * CGFloat(currentStage.rawValue + 1) / CGFloat(TaxProcessStage.allCases.count),
                                    height: 6
                                )
                                .animation(.easeInOut(duration: 0.3), value: currentStage)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 20)
                }
                .background(
                    Color(.systemBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )

                // Current stage card (minimalist without title)
                currentStageCard

                // Timeline - Clean, minimal steps
                VStack(spacing: 0) {
                    ForEach(Array(TaxProcessStage.allCases.enumerated()), id: \.element) { index, stage in
                        ProcessStageRow(
                            stage: stage,
                            isActive: currentStage.rawValue == index,
                            isCompleted: currentStage.rawValue > index,
                            isLast: index == TaxProcessStage.allCases.count - 1,
                            onAction: {
                                handleStageAction(stage)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Help Section
                helpCard

                // Branded Footer
                BrandedFooterView(style: .compact)
                    .padding(.top, 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
        }
    }

    // MARK: - Current Stage Card

    private var currentStageCard: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: currentStage.icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.taxedPrimary)
                .cornerRadius(16)

            // Description
            VStack(alignment: .leading, spacing: 4) {
                Text(currentStage.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.taxedPrimary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.taxedPrimary.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Help Card

    private var helpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.taxedPrimary)

                Text("process.help.title".localized)
                    .font(.headline)
            }

            Text("process.help.description".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                showExpertChat = true
            } label: {
                HStack {
                    Image(systemName: "message.fill")
                    Text("process.help.button".localized)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.taxedPrimary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private func handleStageAction(_ stage: TaxProcessStage) {
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
        } catch {
            print("❌ Error loading process data: \(error)")
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

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                // Circle
                ZStack {
                    Circle()
                        .fill(isCompleted ? stage.color : Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    } else if isActive {
                        Circle()
                            .fill(stage.color)
                            .frame(width: 16, height: 16)
                    }
                }

                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? stage.color.opacity(0.3) : Color.gray.opacity(0.2))
                        .frame(width: 2, height: 60)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stage.title)
                        .font(isActive ? .headline : .subheadline)
                        .fontWeight(isActive ? .bold : .medium)
                        .foregroundColor(isActive ? stage.color : .primary)

                    Text(stage.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(isActive ? nil : 2)
                }

                if isActive {
                    Button(action: onAction) {
                        HStack {
                            Image(systemName: stage.icon)
                            Text(actionButtonTitle)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(stage.color)
                        .cornerRadius(10)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
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

#Preview {
    NavigationView {
        ProcessStageView()
            .environmentObject(AuthenticationService())
    }
}
