//
//  MessageBubbleView_HIGCompliant.swift
//  TaxedGmbH_IOS
//
//  Apple HIG compliant WhatsApp-style message bubble component
//  Follows https://developer.apple.com/design/ guidelines
//

import SwiftUI

/// Message bubble component displaying chat messages
/// Complies with Apple Human Interface Guidelines for messaging bubbles
struct MessageBubbleView_HIGCompliant: View {
    let message: ChatMessage
    let isCurrentUser: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer()
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message content
                messageContent

                // Time and read status
                HStack(spacing: 4) {
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if isCurrentUser {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption2)
                            .foregroundStyle(message.isRead ? .blue : .secondary)
                            .accessibilityLabel(message.isRead ? "expert_chat.read".localized : "expert_chat.sent".localized)
                    }
                }
            }

            if !isCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var messageContent: some View {
        switch message.type {
        case .text:
            textBubble
        case .image:
            imageBubble
        case .document:
            documentBubble
        case .system:
            systemMessage
        }
    }

    // MARK: - Text Bubble

    /// Text message bubble with semantic colors
    private var textBubble: some View {
        Text(message.content)
            .font(.body)
            .foregroundStyle(isCurrentUser ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(bubbleBackground)
            .cornerRadius(18)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(message.senderName): \(message.content)")
    }

    // MARK: - Image Bubble

    /// Image message bubble with optional caption
    private var imageBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = message.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 200, height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 250)
                            .cornerRadius(12)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .frame(width: 200, height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
                .accessibilityLabel("expert_chat.image_message".localized)
            }

            if !message.content.isEmpty {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .background(bubbleBackground)
        .cornerRadius(18)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Document Bubble

    /// Document attachment bubble
    private var documentBubble: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundStyle(isCurrentUser ? .white.opacity(0.8) : .blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(message.documentName ?? "Document")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "arrow.down.circle")
                .font(.title3)
                .foregroundStyle(isCurrentUser ? .white.opacity(0.8) : .blue)
        }
        .foregroundStyle(isCurrentUser ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(bubbleBackground)
        .cornerRadius(18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("expert_chat.document_message".localized + ": \(message.documentName ?? "Document")")
        .accessibilityHint("expert_chat.document_hint".localized)
    }

    // MARK: - System Message

    /// System notification message
    private var systemMessage: some View {
        Text(message.content)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemGray5))
            .cornerRadius(12)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("expert_chat.system_message".localized + ": \(message.content)")
    }

    // MARK: - Bubble Background

    /// Semantic background colors based on message type and sender
    private var bubbleBackground: some View {
        Group {
            if message.type == .system {
                Color.clear
            } else if isCurrentUser {
                // Use accent color for current user messages
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                // Use system background for received messages
                Color(uiColor: .secondarySystemBackground)
            }
        }
    }
}

// MARK: - Preview

#Preview("Message Bubbles") {
    VStack(spacing: 16) {
        MessageBubbleView_HIGCompliant(
            message: ChatMessage(
                conversationId: "1",
                senderId: "customer1",
                senderName: "John Doe",
                senderRole: .customer,
                content: "Hello! I have a question about my tax deductions."
            ),
            isCurrentUser: true
        )

        MessageBubbleView_HIGCompliant(
            message: ChatMessage(
                conversationId: "1",
                senderId: "expert1",
                senderName: "Maria Schmidt",
                senderRole: .expert,
                content: "Hello! I'd be happy to help you. What would you like to know?"
            ),
            isCurrentUser: false
        )

        MessageBubbleView_HIGCompliant(
            message: ChatMessage(
                conversationId: "1",
                senderId: "system",
                senderName: "System",
                senderRole: .system,
                type: .system,
                content: "Maria Schmidt was assigned as your tax expert"
            ),
            isCurrentUser: false
        )
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        MessageBubbleView_HIGCompliant(
            message: ChatMessage(
                conversationId: "1",
                senderId: "customer1",
                senderName: "John Doe",
                senderRole: .customer,
                content: "Hello! I have a question about my tax deductions."
            ),
            isCurrentUser: true
        )

        MessageBubbleView_HIGCompliant(
            message: ChatMessage(
                conversationId: "1",
                senderId: "expert1",
                senderName: "Maria Schmidt",
                senderRole: .expert,
                content: "Hello! I'd be happy to help you. What would you like to know?"
            ),
            isCurrentUser: false
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
