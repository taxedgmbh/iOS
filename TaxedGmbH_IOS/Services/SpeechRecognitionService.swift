//
//  SpeechRecognitionService.swift
//  TaxedGmbH_IOS
//
//  Speech-to-text service using iOS Speech Recognition and Whisper AI
//

import SwiftUI
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    static let shared = SpeechRecognitionService()

    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var transcribedText = ""
    @Published var partialResults = ""
    @Published var errorMessage: String?
    @Published var hasPermission = false
    @Published var audioLevel: Float = 0.0

    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioSession: AVAudioSession?
    private var levelTimer: Timer?

    // Language support
    private let supportedLanguages = ["en-US", "de-DE", "fr-FR", "it-IT"]
    @Published var currentLanguage = "en-US" {
        didSet {
            setupSpeechRecognizer()
        }
    }

    override init() {
        super.init()
        setupSpeechRecognizer()
        requestPermissions()
    }

    // MARK: - Setup
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
        speechRecognizer?.delegate = self
    }

    // MARK: - Permissions
    func requestPermissions() {
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.hasPermission = true
                    self?.requestMicrophonePermission()
                case .denied, .restricted:
                    self?.hasPermission = false
                    self?.errorMessage = "speech.permission.denied".localized
                case .notDetermined:
                    self?.hasPermission = false
                @unknown default:
                    self?.hasPermission = false
                }
            }
        }
    }

    private func requestMicrophonePermission() {
        // Use iOS 17.0+ API for requesting record permission
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.hasPermission = false
                    self?.errorMessage = "speech.microphone.denied".localized
                }
            }
        }
    }

    // MARK: - Recording Control
    func startRecording() {
        guard hasPermission else {
            requestPermissions()
            return
        }

        // Stop any ongoing recording
        if isRecording {
            stopRecording()
            return
        }

        do {
            // Configure audio session
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)

            // Create and configure the speech recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                throw RecognitionError.requestCreationFailed
            }

            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = false

            // Configure audio input
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            // Remove tap if it exists
            inputNode.removeTap(onBus: 0)

            // Install tap on audio input
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                self?.updateAudioLevel(buffer: buffer)
            }

            // Start recognition task
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }

                if let result = result {
                    self.partialResults = result.bestTranscription.formattedString

                    if result.isFinal {
                        self.transcribedText = result.bestTranscription.formattedString
                        self.stopRecording()
                    }
                }

                if let error = error {
                    self.handleError(error)
                    self.stopRecording()
                }
            }

            // Start audio engine
            audioEngine.prepare()
            try audioEngine.start()

            isRecording = true
            errorMessage = nil

            // Start audio level monitoring
            startAudioLevelMonitoring()

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

        } catch {
            handleError(error)
        }
    }

    func stopRecording() {
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Deactivate audio session
        try? audioSession?.setActive(false)

        // Update state
        isRecording = false

        // Stop audio level monitoring
        stopAudioLevelMonitoring()

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    // MARK: - Audio Level Monitoring
    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataArray = Array(UnsafeBufferPointer(start: channelDataValue, count: Int(buffer.frameLength)))

        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)

        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = max(0, min(1, (avgPower + 50) / 50))
        }
    }

    private func startAudioLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                // Audio level decay for smoother animation
                guard let self = self else { return }
                if self.audioLevel > 0 {
                    self.audioLevel *= 0.9
                }
            }
        }
    }

    private func stopAudioLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
    }

    // MARK: - Whisper AI Integration
    func transcribeWithWhisper(audioData: Data) async {
        isProcessing = true
        errorMessage = nil

        // This is where you would integrate with OpenAI's Whisper API
        // For now, using local speech recognition
        // In production, you would send audioData to Whisper API endpoint

        // Example Whisper API call (requires API key):
        /*
        do {
            let whisperResponse = try await WhisperAPI.transcribe(
                audio: audioData,
                model: "whisper-1",
                language: currentLanguage.prefix(2).lowercased()
            )
            transcribedText = whisperResponse.text
        } catch {
            handleError(error)
        }
        */

        // Fallback to iOS speech recognition
        isProcessing = false
    }

    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            if let recognitionError = error as? RecognitionError {
                self?.errorMessage = recognitionError.localizedDescription
            } else {
                self?.errorMessage = "speech.error.generic".localized
            }
            print("Speech recognition error: \(error)")
        }
    }

    // MARK: - Utility
    func clearTranscription() {
        transcribedText = ""
        partialResults = ""
        errorMessage = nil
    }

    func saveTranscription(as type: NoteType) {
        guard !transcribedText.isEmpty else { return }

        // Save to appropriate location based on type
        Task {
            do {
                let note = VoiceNote(
                    text: transcribedText,
                    type: type,
                    timestamp: Date(),
                    language: currentLanguage
                )

                try await saveNote(note)
                clearTranscription()
            } catch {
                errorMessage = "speech.save.failed".localized
            }
        }
    }

    private func saveNote(_ note: VoiceNote) async throws {
        // Save to Firebase or local storage
        // Implementation depends on your backend
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            errorMessage = "speech.unavailable".localized
            stopRecording()
        }
    }
}

// MARK: - Supporting Types
enum RecognitionError: LocalizedError {
    case requestCreationFailed
    case audioSessionFailed
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .requestCreationFailed:
            return "speech.error.request".localized
        case .audioSessionFailed:
            return "speech.error.audio".localized
        case .notAvailable:
            return "speech.error.unavailable".localized
        }
    }
}

enum NoteType: Codable {
    case document(documentId: String)
    case chat(conversationId: String)
    case general
    case reminder

    enum CodingKeys: String, CodingKey {
        case type, documentId, conversationId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "document":
            let documentId = try container.decode(String.self, forKey: .documentId)
            self = .document(documentId: documentId)
        case "chat":
            let conversationId = try container.decode(String.self, forKey: .conversationId)
            self = .chat(conversationId: conversationId)
        case "general":
            self = .general
        case "reminder":
            self = .reminder
        default:
            self = .general
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .document(let documentId):
            try container.encode("document", forKey: .type)
            try container.encode(documentId, forKey: .documentId)
        case .chat(let conversationId):
            try container.encode("chat", forKey: .type)
            try container.encode(conversationId, forKey: .conversationId)
        case .general:
            try container.encode("general", forKey: .type)
        case .reminder:
            try container.encode("reminder", forKey: .type)
        }
    }
}

struct VoiceNote: Identifiable, Codable {
    let id = UUID()
    let text: String
    let type: NoteType
    let timestamp: Date
    let language: String
}

// MARK: - Whisper API Mock (Replace with actual implementation)
struct WhisperAPI {
    static func transcribe(audio: Data, model: String, language: String) async throws -> WhisperResponse {
        // Mock implementation - replace with actual Whisper API call
        throw RecognitionError.notAvailable
    }
}

struct WhisperResponse {
    let text: String
    let language: String
    let duration: Double
}