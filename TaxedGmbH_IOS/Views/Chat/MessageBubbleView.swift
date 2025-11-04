//
//  MessageBubbleView.swift
//  TaxedGmbH_IOS
//
//  WhatsApp-style message bubble component
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool

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
                        .foregroundColor(.secondary)

                    if isCurrentUser {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption2)
                            .foregroundColor(message.isRead ? .blue : .secondary)
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

    private var textBubble: some View {
        Text(message.content)
            .font(.body)
            .foregroundColor(isCurrentUser ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(bubbleBackground)
            .cornerRadius(18)
    }

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
                            .foregroundColor(.gray)
                            .frame(width: 200, height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            if !message.content.isEmpty {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .background(bubbleBackground)
        .cornerRadius(18)
    }

    private var documentBubble: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundColor(isCurrentUser ? .white.opacity(0.8) : .blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(message.documentName ?? "Document")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "arrow.down.circle")
                .font(.title3)
                .foregroundColor(isCurrentUser ? .white.opacity(0.8) : .blue)
        }
        .foregroundColor(isCurrentUser ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(bubbleBackground)
        .cornerRadius(18)
    }

    private var systemMessage: some View {
        Text(message.content)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .frame(maxWidth: .infinity)
    }

    private var bubbleBackground: some View {
        Group {
            if message.type == .system {
                Color.clear
            } else if isCurrentUser {
                LinearGradient(
                    colors: [Color.taxedPrimary, Color.taxedPrimary.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.secondaryBackground
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubbleView(
            message: ChatMessage(
                conversationId: "1",
                senderId: "customer1",
                senderName: "John Doe",
                senderRole: .customer,
                content: "Hello! I have a question about my tax deductions."
            ),
            isCurrentUser: true
        )

        MessageBubbleView(
            message: ChatMessage(
                conversationId: "1",
                senderId: "expert1",
                senderName: "Maria Schmidt",
                senderRole: .expert,
                content: "Hello! I'd be happy to help you. What would you like to know?"
            ),
            isCurrentUser: false
        )

        MessageBubbleView(
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
