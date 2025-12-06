//
//  DocumentListView.swift
//  TaxedGmbH_IOS
//
//  Tinder-style swipe interface for document review
//

import SwiftUI

struct DocumentListView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var firestoreService = FirestoreService.shared
    @ObservedObject private var workspaceManager = WorkspaceManager.shared

    @State private var documents: [TaxDocument] = []
    @State private var isLoading = false
    @State private var showUploadSheet = false
    @State private var currentIndex = 0
    @State private var cardOffsets: [Int: CGSize] = [:]
    @State private var isProcessingSwipe = false

    // Undo functionality
    @State private var showUndoToast = false
    @State private var lastSwipedDocument: TaxDocument?
    @State private var lastSwipedIndex: Int?
    @State private var lastSwipedStatus: DocumentStatus?

    // Swipe threshold
    private let swipeThreshold: CGFloat = 120

    var body: some View {
        ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("documents.swipe.loading".localized)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if documents.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 16) {
                        // Enhanced header with branding and progress
                        VStack(spacing: 12) {
                            // Taxed branding with progress
                            HStack(spacing: 12) {
                                // Taxed logo for branding
                                Image("taxed-logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 28)

                                Spacer()

                                // Clean progress indicator
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(currentIndex + 1) / \(documents.count)")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    Text("documents.swipe.remaining".localized)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Color(.systemBackground)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )

                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 3)

                                    // Progress fill
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.taxedPrimary)
                                        .frame(width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(documents.count), height: 3)
                                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                                }
                            }
                            .frame(height: 3)
                            .padding(.horizontal, 20)
                        }

                        // Card stack
                        ZStack {
                            ForEach(Array(documents.enumerated()), id: \.element.id) { index, document in
                                if index >= currentIndex && index < currentIndex + 3 {
                                    SwipeableDocumentCard(
                                        document: document,
                                        offset: cardOffsets[index] ?? .zero,
                                        rotation: rotationAngle(for: index)
                                    )
                                    .offset(cardOffsets[index] ?? .zero)
                                    .rotationEffect(.degrees(rotationAngle(for: index)))
                                    .scaleEffect(scaleForCard(at: index))
                                    .offset(y: offsetYForCard(at: index))
                                    .zIndex(Double(documents.count - index))
                                    .gesture(
                                        index == currentIndex ?
                                        DragGesture()
                                            .onChanged { gesture in
                                                handleDragChanged(gesture, for: index)
                                            }
                                            .onEnded { gesture in
                                                handleDragEnded(gesture, for: index, document: document)
                                            }
                                        : nil
                                    )
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: cardOffsets[index])
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(maxHeight: .infinity)
                        .padding(.bottom, 90) // Space for tab bar
                    }
                }

                // Undo Toast
                if showUndoToast {
                    VStack {
                        Spacer()
                        undoToast
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("tab.documents".localized)
            .navigationBarTitleDisplayMode(.large)
            .trackScreen("Documents")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showUploadSheet = true }) {
                        Label("documents.upload".localized, systemImage: "plus")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showUploadSheet) {
                DocumentUploadView()
            }
            .task {
                // Load workspace first, then documents
                guard let userId = authService.user?.id else { return }
                await workspaceManager.loadCurrentWorkspace(userId: userId)
                await loadDocuments()
                observeDocuments()
            }
            .refreshable {
                await loadDocuments()
            }
    }

    // MARK: - Undo Toast

    private var undoToast: some View {
        HStack(spacing: 12) {
            Image(systemName: lastSwipedStatus == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(lastSwipedStatus == .approved ? .green : .red)
                .font(.system(size: 20))

            Text(lastSwipedStatus == .approved ? "Document approved" : "Document rejected")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()

            Button(action: handleUndo) {
                Text("Undo")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.taxedPrimary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("documents.swipe.empty.title".localized)
                .font(.headline)
                .foregroundColor(.gray)

            Text("documents.swipe.empty.message".localized)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button(action: { showUploadSheet = true }) {
                Label("documents.upload".localized, systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.taxedPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 8)

            // Compliance Footer in empty state
            BrandedFooterView(style: .compliance)
                .padding(.top, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Gesture Handlers

    private func handleDragChanged(_ gesture: DragGesture.Value, for index: Int) {
        guard !isProcessingSwipe else { return }
        cardOffsets[index] = gesture.translation
    }

    private func handleDragEnded(_ gesture: DragGesture.Value, for index: Int, document: TaxDocument) {
        guard !isProcessingSwipe else { return }

        let offset = gesture.translation.width

        // Check if swipe threshold is met
        if abs(offset) > swipeThreshold {
            isProcessingSwipe = true

            // Determine swipe direction
            let status: DocumentStatus = offset > 0 ? .approved : .rejected

            // Animate card off screen
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                cardOffsets[index] = CGSize(
                    width: offset > 0 ? 1000 : -1000,
                    height: gesture.translation.height
                )
            }

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            // Store for undo
            lastSwipedDocument = document
            lastSwipedIndex = currentIndex
            lastSwipedStatus = status

            // Update status in Firestore
            Task {
                do {
                    try await firestoreService.updateDocumentStatus(
                        documentId: document.id,
                        status: status
                    )

                    // Move to next card after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        currentIndex += 1
                        cardOffsets.removeValue(forKey: index)
                        isProcessingSwipe = false

                        // Show undo toast
                        withAnimation(.spring(response: 0.4)) {
                            showUndoToast = true
                        }

                        // Hide undo toast after 4 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            withAnimation(.spring(response: 0.4)) {
                                showUndoToast = false
                            }
                            // Clear undo data after toast disappears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                lastSwipedDocument = nil
                                lastSwipedIndex = nil
                                lastSwipedStatus = nil
                            }
                        }

                        // Check if all cards reviewed
                        if currentIndex >= documents.count {
                            showCompletionMessage()
                        }
                    }
                } catch {
                    print("❌ Error updating document status: \(error)")
                    // Reset card position on error
                    withAnimation {
                        cardOffsets[index] = .zero
                    }
                    isProcessingSwipe = false
                }
            }
        } else {
            // Reset card position
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                cardOffsets[index] = .zero
            }
        }
    }

    // MARK: - Card Layout Calculations

    private func rotationAngle(for index: Int) -> Double {
        guard let offset = cardOffsets[index] else { return 0 }
        // Maximum rotation of 15 degrees
        return Double(offset.width / 20)
    }

    private func scaleForCard(at index: Int) -> CGFloat {
        let position = index - currentIndex
        switch position {
        case 0:
            return 1.0
        case 1:
            return 0.95
        case 2:
            return 0.90
        default:
            return 0.85
        }
    }

    private func offsetYForCard(at index: Int) -> CGFloat {
        let position = index - currentIndex
        switch position {
        case 0:
            return 0
        case 1:
            return 10
        case 2:
            return 20
        default:
            return 30
        }
    }

    // MARK: - Data Loading

    private func loadDocuments() async {
        guard let workspace = workspaceManager.activeWorkspace,
              let workspaceId = workspace.id else {
            print("⚠️ No active workspace found")
            isLoading = false
            return
        }

        isLoading = true
        do {
            documents = try await firestoreService.getDocumentsForWorkspace(
                workspaceId: workspaceId,
                taxYear: workspace.taxYear
            )
            currentIndex = 0
            cardOffsets.removeAll()
            print("✅ Loaded \(documents.count) documents for workspace: \(workspace.name)")
        } catch {
            print("❌ Error loading documents: \(error)")
        }
        isLoading = false
    }

    private func observeDocuments() {
        guard let workspace = workspaceManager.activeWorkspace,
              let workspaceId = workspace.id else {
            print("⚠️ No active workspace for observation")
            return
        }

        firestoreService.observeWorkspaceDocuments(
            workspaceId: workspaceId,
            taxYear: workspace.taxYear
        ) { updatedDocs in
            // Only update if we're at the end or haven't started
            if currentIndex >= documents.count || documents.isEmpty {
                documents = updatedDocs
                currentIndex = 0
                cardOffsets.removeAll()
            }
        }
    }

    private func showCompletionMessage() {
        // All documents reviewed
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }

    private func handleUndo() {
        guard let document = lastSwipedDocument,
              let index = lastSwipedIndex else { return }

        // Hide toast immediately
        withAnimation(.spring(response: 0.3)) {
            showUndoToast = false
        }

        // Revert status to pending
        Task {
            do {
                try await firestoreService.updateDocumentStatus(
                    documentId: document.id,
                    status: .pending
                )

                // Move back to previous card
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.4)) {
                        currentIndex = index
                        cardOffsets.removeValue(forKey: index)
                    }

                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()

                    // Clear undo data
                    lastSwipedDocument = nil
                    lastSwipedIndex = nil
                    lastSwipedStatus = nil
                }
            } catch {
                print("❌ Error undoing document status: \(error)")
            }
        }
    }
}

#Preview {
    DocumentListView()
        .environmentObject(AuthenticationService())
}
