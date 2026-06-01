import AVFoundation
import Combine

class AudioRecordingManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var isPaused = false
    @Published var currentDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0.0

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var audioSession = AVAudioSession.sharedInstance()
    private var levelTimer: Timer?
    private var durationTimer: Timer?
    private var recordingStartTime: Date?
    private var currentFileURL: URL?

    // MARK: - Permission

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording Controls

    func startRecording() {
        do {
            // Configure audio session
            try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try audioSession.setActive(true)

            // Create unique filename in Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "\(UUID().uuidString).m4a"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            currentFileURL = fileURL

            // Configure recording settings
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            // Create and prepare recorder
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()

            // Start recording
            guard audioRecorder?.record() == true else {
                print("Failed to start recording")
                return
            }

            isRecording = true
            isPaused = false
            recordingStartTime = Date()
            currentDuration = 0

            // Start timers
            startTimers()

        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }

        audioRecorder?.stop()
        stopTimers()

        isRecording = false
        isPaused = false
        currentDuration = 0
        audioLevel = 0.0

        // Deactivate audio session
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }

        return currentFileURL
    }

    func pauseRecording() {
        guard isRecording, !isPaused else { return }

        audioRecorder?.pause()
        stopTimers()
        isPaused = true
    }

    func resumeRecording() {
        guard isRecording, isPaused else { return }

        audioRecorder?.record()
        startTimers()
        isPaused = false
    }

    func deleteRecording(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to delete recording: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private func startTimers() {
        // Update duration every second
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.currentDuration = Date().timeIntervalSince(startTime)
        }

        // Update audio level at 60fps (0.0166s) for smooth waveform
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.0166, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }

    private func stopTimers() {
        durationTimer?.invalidate()
        durationTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0.0
            return
        }

        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)

        // Convert dB (-160 to 0) to normalized 0.0-1.0 range
        // dB range: -160 (silent) to 0 (max)
        // Map to 0.0-1.0 with some compression for better visualization
        let normalizedLevel = pow(10, averagePower / 20)
        audioLevel = max(0.0, min(1.0, normalizedLevel))
    }
}
