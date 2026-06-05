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
    @Published var duration: TimeInterval = 0

    /// URL of the most recently saved .txt transcript (for Share). nil until a recording is saved.
    @Published var savedTranscriptURL: URL?

    // MARK: - Managers (injected from environment)

    private var audioManager: AudioRecordingManager?
    private var speechManager: SpeechTranscriptionManager?

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

    // MARK: - Initialization

    init() {
        haptics.prepare()
    }

    func setup(
        audioManager: AudioRecordingManager,
        speechManager: SpeechTranscriptionManager
    ) {
        self.audioManager = audioManager
        self.speechManager = speechManager

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
                savedTranscriptURL = nil
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

        // Stop the audio recorder. The .txt transcript is the shipping artifact in Phase 1.
        _ = audioManager.stopRecording()

        let transcript = speechManager.stopTranscribing()

        self.transcriptText = transcript
        self.recordingState = .complete
        self.haptics.impactOccurred()

        // Auto-save to .txt file
        Task {
            await saveTranscript(
                original: transcript,
                duration: duration
            )
        }
    }

    private func reset() {
        recordingState = .idle
        duration = 0
        transcriptText = ""
        savedTranscriptURL = nil
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


    // MARK: - File Management

    private func saveTranscript(original: String, duration: TimeInterval) async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let dateString = dateFormatter.string(from: Date())

        // Extract first 3 words for filename (fallback if transcript empty)
        let words = original.split(separator: " ").prefix(3).map(String.init)
        let titleFragment = words.isEmpty ? "Recording" : words.joined(separator: "-")
        let filename = "\(dateString)_\(titleFragment).txt"

        // Format duration as MM:SS
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationString = String(format: "%d:%02d", minutes, seconds)

        // Word count
        let wordCount = original.split(separator: " ").count

        // Build file content
        let fullDate = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .medium)
        let transcriptBody = original.isEmpty ? "(No speech detected)" : original
        let fileContent = """
ForgeIQ Transcript
──────────────────────────────────────────
Date:       \(fullDate)
Duration:   \(durationString)
Word Count: \(wordCount) words
──────────────────────────────────────────
TRANSCRIPT

\(transcriptBody)

"""

        // Save to Documents directory
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to get Documents directory")
            return
        }

        let fileURL = documentsURL.appendingPathComponent(filename)

        do {
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✓ Saved transcript: \(filename)")

            // Expose saved file for sharing + success haptic
            await MainActor.run {
                self.savedTranscriptURL = fileURL
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
