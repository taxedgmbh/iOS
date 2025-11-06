//
//  QuickVoiceNoteWidget.swift
//  TaxedGmbH_IOS
//
//  Quick voice note widget for dashboard
//

import SwiftUI

struct QuickVoiceNoteWidget: View {
    @StateObject private var speechService = SpeechRecognitionService.shared
    @State private var showingFullInput = false
    @State private var savedNotes: [VoiceNoteItem] = []
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "mic.fill")
                    .font(.title3)
                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Voice Note")
                        .font(.headline)

                    Text("Tap to record a tax reminder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                // Recording Interface
                VStack(spacing: 12) {
                    // Compact recording button
                    Button(action: toggleRecording) {
                        HStack {
                            Image(systemName: speechService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                                .foregroundColor(speechService.isRecording ? .red : Color(red: 227/255, green: 30/255, blue: 36/255))

                            Text(speechService.isRecording ? "Recording..." : "Tap to Record")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            if speechService.isRecording {
                                // Recording indicator
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .opacity(speechService.audioLevel > 0 ? 1 : 0.3)
                                    .animation(.easeInOut(duration: 0.2), value: speechService.audioLevel)
                            }
                        }
                        .padding()
                        .background(
                            speechService.isRecording ?
                            Color.red.opacity(0.1) :
                            Color(UIColor.secondarySystemBackground)
                        )
                        .cornerRadius(12)
                    }

                    // Live transcription
                    if !speechService.partialResults.isEmpty {
                        Text(speechService.partialResults)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                    }

                    // Recent notes
                    if !savedNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Notes")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            ForEach(savedNotes.prefix(3)) { note in
                                HStack {
                                    Image(systemName: "note.text")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text(note.text)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text(note.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }

            // Show full input sheet
            Button(action: { showingFullInput = true }) {
                Text("Open Full Voice Recorder")
                    .font(.caption)
                    .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showingFullInput) {
            VoiceNoteFullView(savedNotes: $savedNotes)
        }
        .onAppear {
            loadSavedNotes()
        }
        .onChange(of: speechService.transcribedText) { _, newText in
            if !newText.isEmpty && !speechService.isRecording {
                saveNote(newText)
                speechService.clearTranscription()
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

    private func saveNote(_ text: String) {
        let note = VoiceNoteItem(
            text: text,
            timestamp: Date(),
            category: .general
        )
        savedNotes.insert(note, at: 0)

        // Save to persistent storage
        if let encoded = try? JSONEncoder().encode(savedNotes) {
            UserDefaults.standard.set(encoded, forKey: "quickVoiceNotes")
        }
    }

    private func loadSavedNotes() {
        if let data = UserDefaults.standard.data(forKey: "quickVoiceNotes"),
           let decoded = try? JSONDecoder().decode([VoiceNoteItem].self, from: data) {
            savedNotes = decoded
        }
    }
}

// MARK: - Full Voice Note View
struct VoiceNoteFullView: View {
    @Binding var savedNotes: [VoiceNoteItem]
    @Environment(\.dismiss) private var dismiss
    @State private var noteText = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Voice input
                    VoiceInputView(text: $noteText) { text in
                        saveNote(text)
                    }

                    // Manual text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or type your note")
                            .font(.headline)

                        TextField("Enter your tax note...", text: $noteText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)

                        if !noteText.isEmpty {
                            Button(action: {
                                saveNote(noteText)
                                noteText = ""
                            }) {
                                Label("Save Note", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .cornerRadius(20)
                            }
                        }
                    }

                    // Saved notes list
                    if !savedNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Notes")
                                .font(.headline)

                            ForEach(savedNotes) { note in
                                VoiceNoteRow(note: note) {
                                    deleteNote(note)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Voice Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveNote(_ text: String) {
        let note = VoiceNoteItem(
            text: text,
            timestamp: Date(),
            category: .general
        )
        savedNotes.insert(note, at: 0)
        saveToStorage()
    }

    private func deleteNote(_ note: VoiceNoteItem) {
        savedNotes.removeAll { $0.id == note.id }
        saveToStorage()
    }

    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(savedNotes) {
            UserDefaults.standard.set(encoded, forKey: "quickVoiceNotes")
        }
    }
}

// MARK: - Voice Note Row
struct VoiceNoteRow: View {
    let note: VoiceNoteItem
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.text)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(note.timestamp, style: .relative)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Voice Note Item Model
struct VoiceNoteItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    let category: NoteCategory

    init(id: UUID = UUID(), text: String, timestamp: Date, category: NoteCategory) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.category = category
    }

    enum NoteCategory: String, Codable {
        case general
        case document
        case reminder
        case expense
    }
}

// MARK: - Preview
#Preview("Widget") {
    QuickVoiceNoteWidget()
        .padding()
        .background(Color(UIColor.systemBackground))
}

#Preview("Full View") {
    VoiceNoteFullView(savedNotes: .constant([
        VoiceNoteItem(text: "Remember to submit Q3 receipts", timestamp: Date(), category: .reminder),
        VoiceNoteItem(text: "Business expense from Zurich trip", timestamp: Date().addingTimeInterval(-3600), category: .expense)
    ]))
}