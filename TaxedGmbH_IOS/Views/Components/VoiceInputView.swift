//
//  VoiceInputView.swift
//  TaxedGmbH_IOS
//
//  Reusable voice input component for speech-to-text
//

import SwiftUI
import AVFoundation

struct VoiceInputView: View {
    @StateObject private var speechService = SpeechRecognitionService.shared
    @Binding var text: String
    @State private var showingTranscription = false
    @State private var animationScale: CGFloat = 1.0

    var placeholder: String = "Tap to record voice note"
    var onComplete: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            // Recording Button
            Button(action: toggleRecording) {
                ZStack {
                    // Animated background circle
                    if speechService.isRecording {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(animationScale)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: animationScale
                            )

                        // Audio level indicator
                        Circle()
                            .stroke(Color.red, lineWidth: 3)
                            .frame(width: 80 + CGFloat(speechService.audioLevel * 40),
                                   height: 80 + CGFloat(speechService.audioLevel * 40))
                            .animation(.easeOut(duration: 0.1), value: speechService.audioLevel)
                    }

                    // Main button
                    Circle()
                        .fill(speechService.isRecording ? Color.red : Color(red: 227/255, green: 30/255, blue: 36/255))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        )
                        .shadow(radius: speechService.isRecording ? 10 : 5)
                }
            }
            .disabled(!speechService.hasPermission)
            .onChange(of: speechService.isRecording) { isRecording in
                if isRecording {
                    animationScale = 1.3
                } else {
                    animationScale = 1.0
                }
            }

            // Status Text
            if speechService.isRecording {
                Text("speech.recording".localized)
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(20)
            } else if !speechService.hasPermission {
                Text("speech.permission.required".localized)
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text(placeholder)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Partial Results
            if !speechService.partialResults.isEmpty {
                ScrollView {
                    Text(speechService.partialResults)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .frame(maxHeight: 150)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Error Message
            if let error = speechService.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Action Buttons
            if !speechService.transcribedText.isEmpty && !speechService.isRecording {
                HStack(spacing: 16) {
                    Button(action: {
                        text = speechService.transcribedText
                        onComplete?(speechService.transcribedText)
                        speechService.clearTranscription()
                    }) {
                        Label("Use Text", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .cornerRadius(20)
                    }

                    Button(action: {
                        speechService.clearTranscription()
                    }) {
                        Label("Clear", systemImage: "xmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(20)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: speechService.isRecording)
        .animation(.easeInOut, value: speechService.transcribedText)
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
            speechService.startRecording()
        }
    }
}

// MARK: - Compact Voice Input Button
struct CompactVoiceInputButton: View {
    @StateObject private var speechService = SpeechRecognitionService.shared
    @State private var showingVoiceInput = false
    @Binding var text: String

    var body: some View {
        Button(action: {
            showingVoiceInput = true
        }) {
            Image(systemName: "mic.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
                .padding(12)
                .background(Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.1))
                .clipShape(Circle())
        }
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputSheet(text: $text, isPresented: $showingVoiceInput)
        }
    }
}

// MARK: - Voice Input Sheet
struct VoiceInputSheet: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    @StateObject private var speechService = SpeechRecognitionService.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("speech.title".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                VoiceInputView(text: $text) { transcribedText in
                    text = transcribedText
                    isPresented = false
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if !speechService.transcribedText.isEmpty {
                            text = speechService.transcribedText
                        }
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        speechService.clearTranscription()
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Voice Message Bubble (for Chat)
struct VoiceMessageBubble: View {
    let duration: TimeInterval
    let transcription: String?
    let isFromUser: Bool
    @State private var isPlaying = false

    var body: some View {
        HStack {
            if isFromUser { Spacer() }

            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 12) {
                    // Play button
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    // Waveform visualization
                    HStack(spacing: 2) {
                        ForEach(0..<20) { index in
                            Capsule()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 2, height: CGFloat.random(in: 10...25))
                        }
                    }

                    // Duration
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isFromUser ? Color(red: 227/255, green: 30/255, blue: 36/255) : Color.gray)
                )

                // Transcription (if available)
                if let transcription = transcription {
                    Text(transcription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                }
            }
            .frame(maxWidth: 280)

            if !isFromUser { Spacer() }
        }
    }

    private func togglePlayback() {
        isPlaying.toggle()
        // Implement audio playback logic here
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview
#Preview("Voice Input") {
    VStack {
        VoiceInputView(text: .constant(""))
            .padding()
    }
}

#Preview("Compact Button") {
    CompactVoiceInputButton(text: .constant(""))
        .padding()
}

#Preview("Voice Message") {
    VStack(spacing: 20) {
        VoiceMessageBubble(
            duration: 23,
            transcription: "This is a test transcription",
            isFromUser: true
        )

        VoiceMessageBubble(
            duration: 45,
            transcription: nil,
            isFromUser: false
        )
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}