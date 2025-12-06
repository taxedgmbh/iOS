//
//  InlineVoiceTextEditor.swift
//  TaxedGmbH_IOS
//
//  Inline voice-to-text enabled TextEditor for comments
//  Real-time transcription fills the text field as user speaks
//

import SwiftUI

struct InlineVoiceTextEditor: View {
    @Binding var text: String
    @ObservedObject private var speechService = SpeechRecognitionService.shared

    var placeholder: String = "Add your comment..."
    var minHeight: CGFloat = 100
    var backgroundColor: Color = .clear
    var cornerRadius: CGFloat = 12
    var borderColor: Color = Color.cyan.opacity(0.3)

    @State private var isExpanded: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main TextEditor
            ZStack(alignment: .topLeading) {
                // Background with material effect
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)

                // Border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        speechService.isRecording ? Color.red : borderColor,
                        lineWidth: speechService.isRecording ? 2.0 : 1.5
                    )
                    .animation(.easeInOut(duration: 0.2), value: speechService.isRecording)

                // TextEditor
                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .accessibilityLabel(placeholder)
                    .accessibilityHint("document_detail.notes_hint".localized)

                // Placeholder text
                if text.isEmpty && !speechService.isRecording {
                    Text(placeholder)
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }

            // Voice Recording Controls - Bottom Right Corner
            VStack(spacing: 8) {
                // Recording status indicator
                if speechService.isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .opacity(speechService.audioLevel > 0 ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.2).repeatForever(), value: speechService.audioLevel)

                        Text("speech.recording".localized)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                }

                // Voice button
                Button(action: toggleRecording) {
                    ZStack {
                        // Pulsing background when recording
                        if speechService.isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 52, height: 52)
                                .scaleEffect(speechService.audioLevel > 0 ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: speechService.audioLevel)
                        }

                        // Main button circle
                        Circle()
                            .fill(speechService.isRecording ? Color.red : Color(red: 227/255, green: 30/255, blue: 36/255))
                            .frame(width: 44, height: 44)
                            .shadow(
                                color: speechService.isRecording ? .red.opacity(0.4) : Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.3),
                                radius: speechService.isRecording ? 8 : 4,
                                x: 0,
                                y: 2
                            )

                        // Icon
                        Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel(speechService.isRecording ? "speech.stop_recording".localized : "speech.start_recording".localized)
                .accessibilityHint("speech.voice_input_hint".localized)
                .disabled(!speechService.hasPermission)
            }
            .padding(12)
        }
        .animation(.easeInOut, value: speechService.isRecording)
        .onChange(of: speechService.partialResults) { _, newPartialResults in
            // Update text with real-time transcription while recording
            if speechService.isRecording && !newPartialResults.isEmpty {
                text = newPartialResults
            }
        }
        .onChange(of: speechService.transcribedText) { _, newTranscription in
            // Update text with final transcription when recording stops
            if !speechService.isRecording && !newTranscription.isEmpty {
                text = newTranscription
                // Clear transcription after using it
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    speechService.clearTranscription()
                }
            }
        }
        .onAppear {
            if !speechService.hasPermission {
                speechService.requestPermissions()
            }
        }
    }

    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            // Clear any existing transcription before starting
            speechService.clearTranscription()
            speechService.startRecording()
            // Unfocus the text editor to show the transcription clearly
            isFocused = false
        }
    }
}

// MARK: - Preview
#Preview("Inline Voice Editor") {
    VStack(spacing: 20) {
        Text("Add Comment with Voice")
            .font(.headline)

        InlineVoiceTextEditor(
            text: .constant(""),
            placeholder: "Tap the microphone to add a voice comment...",
            minHeight: 120
        )

        Button(action: {}) {
            Text("Save Comment")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}

#Preview("With Text") {
    VStack(spacing: 20) {
        Text("Comment with existing text")
            .font(.headline)

        InlineVoiceTextEditor(
            text: .constant("This document shows my income from last year. Please verify the amount is correct."),
            placeholder: "Add your comment...",
            minHeight: 120
        )

        Button(action: {}) {
            Text("Save Comment")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}
