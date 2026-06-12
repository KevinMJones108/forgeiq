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
    @Published var syncedRecordingId: UUID?
    @Published var saveStatusMessage: String?

    // MARK: - Managers (injected from environment)

    private var audioManager: AudioRecordingManager?
    private var speechManager: SpeechTranscriptionManager?
    private var translationManager: TranslationManager?

    // MARK: - Private State

    private var durationTimer: Timer?
    private let haptics = UIImpactFeedbackGenerator(style: .medium)

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
        guard let audioManager else { return }

        Task {
            let hasPermission = await audioManager.requestMicrophonePermission()
            guard hasPermission else {
                print("Microphone permission denied")
                return
            }

            audioManager.startRecording()

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
                let transcript = try await speechManager.transcribe(audioURL: audioURL)

                await MainActor.run {
                    self.transcriptText = transcript
                    self.recordingState = .complete
                    self.haptics.impactOccurred()
                }

                // Handle translation if mode is recordAndTranslate
                if selectedMode == .recordAndTranslate, let translationManager {
                    // Translation logic will be added when TranslationManager is integrated
                }

                await saveAndSync(audioURL: audioURL, transcriptText: transcript)
            } catch {
                print("Transcription failed: \(error.localizedDescription)")
                await MainActor.run {
                    reset()
                }
            }
        }
    }

    // MARK: - Auto-Save + Backend Sync

    private func saveAndSync(audioURL: URL, transcriptText: String) async {
        // 1. Auto-save .txt next to the .m4a (same UUID filename — Files tab pairs them)
        let transcript = Transcript(
            originalText: transcriptText,
            originalLanguage: "en",
            translatedText: translatedText,
            targetLanguage: translatedText != nil ? "es" : nil
        )
        let fileContents = transcript.toFileString(duration: durationString, createdAt: Date())
        let txtURL = audioURL.deletingPathExtension().appendingPathExtension("txt")

        do {
            try fileContents.write(to: txtURL, atomically: true, encoding: .utf8)
            saveStatusMessage = "Saved to Files"
        } catch {
            saveStatusMessage = "Local save failed: \(error.localizedDescription)"
            return
        }

        // 2. Sync to backend (requires login — skipped silently when signed out)
        guard AuthTokenManager.shared.hasValidToken else { return }

        do {
            let title = "Call \(Date().formatted(date: .abbreviated, time: .shortened))"
            let remote = try await APIClient.shared.createRecording(
                title: title,
                durationSec: max(Int(duration), 1)
            )
            try await APIClient.shared.saveTranscript(
                recordingId: remote.id,
                text: transcriptText,
                sourceLanguage: "en",
                translatedText: translatedText,
                targetLanguage: translatedText != nil ? "es" : nil
            )
            syncedRecordingId = remote.id
            saveStatusMessage = "Saved + synced to ForgeIQ"
        } catch {
            saveStatusMessage = "Saved locally — sync failed: \(error.localizedDescription)"
        }
    }

    private func reset() {
        recordingState = .idle
        duration = 0
        transcriptText = ""
        translatedText = nil
        syncedRecordingId = nil
        saveStatusMessage = nil
        haptics.impactOccurred()
        stopDurationTimer()
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
