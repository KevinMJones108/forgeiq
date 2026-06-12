import Speech
import AVFoundation
import Combine

enum SpeechError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied. Enable it in Settings."
        case .recognizerUnavailable:
            return "Speech recognition is not available on this device."
        }
    }
}

class SpeechTranscriptionManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var transcriptText: String = ""
    @Published var isTranscribing = false
    @Published var confidence: Float = 0.0
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioEngine = AVAudioEngine()

    // MARK: - Permission

    func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Transcription Controls

    func startTranscribing(locale: Locale = Locale.current) {
        // Reset state
        transcriptText = ""
        confidence = 0.0
        errorMessage = nil

        // Check recognizer availability
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition not available for \(locale.identifier)"
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            return
        }

        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false // Use server for better accuracy

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session setup failed: \(error.localizedDescription)"
            return
        }

        // Configure audio engine input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // Prepare and start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Audio engine failed to start: \(error.localizedDescription)"
            return
        }

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                // Update transcript with partial or final results
                DispatchQueue.main.async {
                    self.transcriptText = result.bestTranscription.formattedString

                    // Calculate average confidence from segments
                    let segments = result.bestTranscription.segments
                    if !segments.isEmpty {
                        let totalConfidence = segments.reduce(0.0) { $0 + $1.confidence }
                        self.confidence = totalConfidence / Float(segments.count)
                    }
                }
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self.stopTranscribing()
                }
            }
        }

        isTranscribing = true
    }

    func stopTranscribing() -> String {
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel task
        recognitionTask?.cancel()
        recognitionTask = nil

        isTranscribing = false

        // Return final transcript
        return transcriptText
    }

    // MARK: - File Transcription

    /// Transcribes a saved audio file (.m4a) — used after AVAudioRecorder finishes
    func transcribe(audioURL: URL, locale: Locale = Locale.current) async throws -> String {
        guard await requestSpeechPermission() else {
            throw SpeechError.permissionDenied
        }

        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    if !didResume {
                        didResume = true
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let result, result.isFinal else { return }
                if !didResume {
                    didResume = true
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    // MARK: - Cleanup

    deinit {
        if isTranscribing {
            stopTranscribing()
        }
    }
}
