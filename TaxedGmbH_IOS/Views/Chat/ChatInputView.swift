//
//  ChatInputView.swift
//  TaxedGmbH_IOS
//
//  Message input component with photo/document attachment
//

import SwiftUI
import PhotosUI

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

#Preview {
    ChatInputView(
        messageText: .constant(""),
        onSend: {},
        onImageSelected: { _ in }
    )
}
