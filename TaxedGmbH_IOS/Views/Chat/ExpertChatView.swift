//
//  ExpertChatView.swift
//  TaxedGmbH_IOS
//
//  WhatsApp-style chat interface with tax expert
//

import SwiftUI

struct ExpertChatView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var chatService = ChatService.shared

    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var conversation: Conversation?
    @State private var isLoading = true

    private let taxYear = 2024

    var body: some View {
        VStack(spacing: 0) {
            // Expert header
            if let conversation = conversation {
                expertHeader(conversation)
            }

            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubbleView(
                                message: message,
                                isCurrentUser: message.senderId == authService.user?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: messages.count) {
                    scrollToBottom(proxy: proxy)
                }
            }

            // Input bar
            ChatInputView(
                messageText: $messageText,
                onSend: sendMessage,
                onImageSelected: sendImage
            )
        }
        .navigationTitle("expert_chat.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadChat()
        }
        .onDisappear {
            chatService.stopObserving()
        }
    }

    // MARK: - Expert Header

    private func expertHeader(_ conversation: Conversation) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Expert avatar
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.taxedPrimary, Color.taxedPrimary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(conversation.expertName.prefix(1))
                            .font(.headline)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.expertName)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Text("expert_chat.tax_expert".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !conversation.languageFlags.isEmpty {
                            Text(conversation.languageFlags)
                                .font(.caption)
                        }
                    }
                }

                Spacer()

                // Online indicator (placeholder)
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
            }
            .padding()
            .background(Color.secondaryBackground)

            Divider()
        }
    }

    // MARK: - Actions

    private func loadChat() async {
        guard let userId = authService.user?.id,
              let userName = authService.user?.name else {
            return
        }

        isLoading = true

        do {
            // Get or create conversation
            let conv = try await chatService.getOrCreateConversation(
                customerId: userId,
                customerName: userName,
                taxYear: taxYear
            )
            conversation = conv

            // Load messages
            messages = try await chatService.getMessages(conversationId: conv.id)

            // Observe real-time updates
            chatService.observeMessages(conversationId: conv.id) { updatedMessages in
                messages = updatedMessages
            }

            // Mark messages as read
            try await chatService.markAllMessagesAsRead(
                conversationId: conv.id,
                forUserId: userId
            )

            isLoading = false
        } catch {
            print("❌ Error loading chat: \(error)")
            isLoading = false
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let userId = authService.user?.id,
              let userName = authService.user?.name,
              let conversationId = conversation?.id else {
            return
        }

        let text = messageText
        messageText = "" // Clear input immediately

        Task {
            do {
                try await chatService.sendTextMessage(
                    conversationId: conversationId,
                    senderId: userId,
                    senderName: userName,
                    senderRole: .customer,
                    text: text
                )
            } catch {
                print("❌ Error sending message: \(error)")
                // Optionally show error to user
            }
        }
    }

    private func sendImage(_ imageData: Data) {
        guard let userId = authService.user?.id,
              let userName = authService.user?.name,
              let conversationId = conversation?.id else {
            return
        }

        Task {
            do {
                try await chatService.sendImageMessage(
                    conversationId: conversationId,
                    senderId: userId,
                    senderName: userName,
                    senderRole: .customer,
                    image: imageData,
                    caption: ""
                )
            } catch {
                print("❌ Error sending image: \(error)")
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = messages.last else { return }
        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

#Preview {
    NavigationView {
        ExpertChatView()
            .environmentObject(AuthenticationService())
    }
}
