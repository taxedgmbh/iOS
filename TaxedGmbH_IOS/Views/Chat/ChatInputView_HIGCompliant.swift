//
//  ChatInputView_HIGCompliant.swift
//  TaxedGmbH_IOS
//
//  Apple HIG compliant message input component with photo/document attachment
//  Follows https://developer.apple.com/design/ guidelines
//

import SwiftUI
import PhotosUI

/// Message input bar with photo picker and voice input
/// Complies with Apple Human Interface Guidelines for input controls
struct ChatInputView_HIGCompliant: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let onImageSelected: (Data) -> Void

    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingVoiceInput = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                // Image picker button with semantic colors
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(.accentColor)
                        .frame(width: 36, height: 36)
                        .background(Color(uiColor: .systemGray6))
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
                .accessibilityLabel("expert_chat.attach_photo".localized)
                .accessibilityHint("expert_chat.photo_hint".localized)

                // Voice input button with semantic colors
                Button(action: { showingVoiceInput = true }) {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                        .foregroundStyle(.accentColor)
                        .frame(width: 36, height: 36)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(18)
                }
                .sheet(isPresented: $showingVoiceInput) {
                    VoiceInputSheet(text: $messageText, isPresented: $showingVoiceInput)
                }
                .accessibilityLabel("expert_chat.voice_input".localized)
                .accessibilityHint("expert_chat.voice_hint".localized)

                // Text input with proper accessibility
                TextField("expert_chat.message_placeholder".localized, text: $messageText, axis: .vertical)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                    .accessibilityLabel("expert_chat.message_field".localized)

                // Send button with semantic colors
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.isEmpty ? .secondary : .accentColor)
                }
                .disabled(messageText.isEmpty)
                .accessibilityLabel("expert_chat.send_message".localized)
                .accessibilityHint(messageText.isEmpty ? "expert_chat.send_disabled".localized : "expert_chat.send_enabled".localized)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

// MARK: - Preview

#Preview("Chat Input") {
    ChatInputView_HIGCompliant(
        messageText: .constant(""),
        onSend: {},
        onImageSelected: { _ in }
    )
}

#Preview("Chat Input with Text") {
    ChatInputView_HIGCompliant(
        messageText: .constant("Hello, I have a question about taxes"),
        onSend: {},
        onImageSelected: { _ in }
    )
}

#Preview("Dark Mode") {
    ChatInputView_HIGCompliant(
        messageText: .constant(""),
        onSend: {},
        onImageSelected: { _ in }
    )
    .preferredColorScheme(.dark)
}
