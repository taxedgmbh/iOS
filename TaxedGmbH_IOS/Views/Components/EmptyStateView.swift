//
//  EmptyStateView.swift
//  TaxedGmbH_IOS
//
//  Reusable empty state component for better UX
//  Shows friendly messages when no data is available
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(.taxedPrimary.opacity(0.6))
                .padding(.bottom, 8)

            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Action Button (if provided)
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.taxedPrimary)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Specific Empty States

struct NoDocumentsEmptyState: View {
    let onUpload: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "doc.text.magnifyingglass",
            title: "empty_state.no_documents.title".localized,
            message: "empty_state.no_documents.message".localized,
            actionTitle: "empty_state.no_documents.action".localized,
            action: onUpload
        )
    }
}

struct NoMessagesEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: "empty_state.no_messages.title".localized,
            message: "empty_state.no_messages.message".localized
        )
    }
}

struct WelcomeEmptyState: View {
    let userName: String
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image("taxed-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)
                .cornerRadius(20)

            // Welcome Text
            VStack(spacing: 12) {
                Text("empty_state.welcome.title".localized(with: userName))
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("empty_state.welcome.subtitle".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Quick Start Steps
            VStack(alignment: .leading, spacing: 16) {
                QuickStartStep(
                    number: 1,
                    title: "empty_state.welcome.step1.title".localized,
                    description: "empty_state.welcome.step1.description".localized
                )

                QuickStartStep(
                    number: 2,
                    title: "empty_state.welcome.step2.title".localized,
                    description: "empty_state.welcome.step2.description".localized
                )

                QuickStartStep(
                    number: 3,
                    title: "empty_state.welcome.step3.title".localized,
                    description: "empty_state.welcome.step3.description".localized
                )

                QuickStartStep(
                    number: 4,
                    title: "empty_state.welcome.step4.title".localized,
                    description: "empty_state.welcome.step4.description".localized
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)

            // Get Started Button
            Button(action: onGetStarted) {
                HStack {
                    Text("empty_state.welcome.action".localized)
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.taxedPrimary)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
    }
}

struct QuickStartStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Number Badge
            ZStack {
                Circle()
                    .fill(Color.taxedPrimary)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Empty Documents") {
    NoDocumentsEmptyState(onUpload: {})
}

#Preview("Welcome State") {
    ScrollView {
        WelcomeEmptyState(userName: "Max Mustermann", onGetStarted: {})
    }
}

#Preview("No Messages") {
    NoMessagesEmptyState()
}
