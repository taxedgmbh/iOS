//
//  ExpertChatView.swift
//  TaxedGmbH_IOS
//
//  Complete chat interface with tax expert
//  Includes: Main chat view, message bubbles, and input bar
//

import SwiftUI
import PhotosUI

// MARK: - Main Chat View

struct ExpertChatView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var chatService = ChatService.shared

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

                // Online indicator
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

// MARK: - Message Bubble Component

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

// MARK: - Chat Input Component

struct ChatInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let onImageSelected: (Data) -> Void

    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingVoiceInput = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                // Image picker button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundColor(.taxedPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray6))
                        .cornerRadius(18)
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            onImageSelected(data)
                            selectedItem = nil
                        }
                    }
                }

                // Voice input button
                Button(action: { showingVoiceInput = true }) {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                        .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                        .frame(width: 36, height: 36)
                        .background(Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.1))
                        .cornerRadius(18)
                }
                .sheet(isPresented: $showingVoiceInput) {
                    VoiceInputSheet(text: $messageText, isPresented: $showingVoiceInput)
                }

                // Text input
                TextField("expert_chat.message_placeholder".localized, text: $messageText, axis: .vertical)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...5)

                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? .gray : .taxedPrimary)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ExpertChatView()
            .environmentObject(AuthenticationService())
    }
}
