//
//  HomeViewModel.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 6 — Hero home screen UI
//

import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published State

    @Published var recordingState: RecordingState = .idle
    @Published var transcriptText: String = ""
    @Published var translatedText: String?
    @Published var duration: TimeInterval = 0
    @Published var showModeSheet: Bool = false
    @Published var selectedMode: RecordingMode = .recordOnly
    @Published var sourceLanguage: LanguageOption = .autoDetect
    @Published var targetLanguage: LanguageOption = .spanish

    @Published var selectedScript: Script?
    @Published var adherencePct: Int?


    // MARK: - Managers (injected from environment)

    private var audioManager: AudioRecordingManager?
    private var speechManager: SpeechTranscriptionManager?
    private var translationManager: TranslationManager?

    // MARK: - Private State

    private var durationTimer: Timer?
    private let haptics = UIImpactFeedbackGenerator(style: .medium)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Enums

    enum RecordingState {
        case idle
        case recording
        case processing
        case complete
    }

    enum RecordingMode: String, CaseIterable {
        case recordOnly = "Record Only"
        case recordAndTranslate = "Record + Translate"
        case readBack = "Read-Back"
    }

    // MARK: - Initialization

    init() {
        haptics.prepare()
    }

    func setup(
        audioManager: AudioRecordingManager,
        speechManager: SpeechTranscriptionManager,
        translationManager: TranslationManager
    ) {
        self.audioManager = audioManager
        self.speechManager = speechManager
        self.translationManager = translationManager

        // Subscribe to live transcript updates
        speechManager.$transcriptText
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcriptText)
    }

    // MARK: - Button Actions

    func handleButtonTap() {
        switch recordingState {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .processing, .complete:
            reset()
        }
    }

    func handleLongPress() {
        guard recordingState == .idle else { return }
        haptics.impactOccurred()
        showModeSheet = true
    }

    // MARK: - Recording Flow

    private func startRecording() {
        guard let audioManager, let speechManager else { return }

        Task {
            // Request microphone permission
            let hasMicPermission = await audioManager.requestMicrophonePermission()
            guard hasMicPermission else {
                print("Microphone permission denied")
                return
            }

            // Request speech recognition permission
            let hasSpeechPermission = await speechManager.requestSpeechPermission()
            guard hasSpeechPermission else {
                print("Speech recognition permission denied")
                return
            }

            // Start both managers in parallel (Session 3 requirement)
            audioManager.startRecording()
            speechManager.startTranscribing()

            await MainActor.run {
                recordingState = .recording
                duration = 0
                transcriptText = ""
                translatedText = nil
                haptics.impactOccurred()
                startDurationTimer()
            }
        }
    }

    private func stopRecording() {
        guard let audioManager, let speechManager else { return }

        recordingState = .processing
        haptics.impactOccurred()
        stopDurationTimer()

        guard let audioURL = audioManager.stopRecording() else {
            print("Failed to get audio URL")
            reset()
            return
        }

        Task {
            do {
                let transcript = speechManager.stopTranscribing()

                await MainActor.run {
                    self.transcriptText = transcript
                    self.recordingState = .complete
                    self.haptics.impactOccurred()
                }

                // Handle translation if mode is recordAndTranslate
                if selectedMode == .recordAndTranslate, let translationManager {
                    do {
                        // Detect source language (auto-detect)
                        let sourceLocale = try await translationManager.detectLanguage(text: transcript) ?? Locale(identifier: "en")

                        // Get target language from selected targetLanguage
                        let targetLocale = targetLanguage.locale ?? Locale(identifier: "en")

                        // Translate
                        let translated = try await translationManager.translate(
                            text: transcript,
                            from: sourceLocale,
                            to: targetLocale
                        )

                        await MainActor.run {
                            self.translatedText = translated
                        }
                    } catch {
                        print("Translation failed: \(error.localizedDescription)")
                        // Continue without translation — transcript still shown
                    }
                }

                // Auto-save to .txt file
                await saveTranscript(
                    original: transcript,
                    translated: translatedText,
                    duration: duration
                )
            } catch {
                print("Transcription failed: \(error.localizedDescription)")
                await MainActor.run {
                    reset()
                }
            }
        }
    }

    private func reset() {
        recordingState = .idle
        duration = 0
        transcriptText = ""
        translatedText = nil
        haptics.impactOccurred()
        stopDurationTimer()
    }

    func swapLanguages() {
        guard sourceLanguage != .autoDetect else { return }
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
    }

    // MARK: - Duration Timer

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.duration += 1
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    // MARK: - Helpers

    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }


    // MARK: - File Management

    private func saveTranscript(original: String, translated: String?, duration: TimeInterval) async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let dateString = dateFormatter.string(from: Date())

        // Extract first 3 words for filename
        let words = original.split(separator: " ").prefix(3).map(String.init)
        let titleFragment = words.joined(separator: "-")
        let filename = "\(dateString)_\(titleFragment).txt"

        // Format duration as MM:SS
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationString = String(format: "%d:%02d", minutes, seconds)

        // Word count
        let wordCount = original.split(separator: " ").count

        // Build file content
        let fullDate = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .medium)
        var fileContent = """
ForgeIQ Transcript
──────────────────────────────────────────
Date:       \(fullDate)
Duration:   \(durationString)
Language:   Auto-detected → \(translated != nil ? "Spanish" : "No translation")
Word Count: \(wordCount) words
Rep:        Kevin
──────────────────────────────────────────
TRANSCRIPT

\(original)

"""

        if let translated {
            fileContent += """

──────────────────────────────────────────
TRANSLATION

\(translated)
"""
        }

        // Save to Documents directory
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to get Documents directory")
            return
        }

        let fileURL = documentsURL.appendingPathComponent(filename)

        do {
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✓ Saved transcript: \(filename)")
            
            // Show success toast (haptic + visual feedback)
            await MainActor.run {
                haptics.impactOccurred()
            }
        } catch {
            print("Failed to save transcript: \(error.localizedDescription)")
        }
    }

    var buttonLabel: String {
        switch recordingState {
        case .idle:
            return "Tap to Begin"
        case .recording:
            return "Tap to Stop"
        case .processing:
            return "Transcribing..."
        case .complete:
            return "Done"
        }
    }
}
