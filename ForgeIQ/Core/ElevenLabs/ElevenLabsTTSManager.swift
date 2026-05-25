//
//  ElevenLabsTTSManager.swift
//  ForgeIQ
//
//  ElevenLabs TTS streaming manager
//  Calls backend /api/v1/voice/tts, streams audio, plays via AVPlayer
//

import Foundation
import AVFoundation
import Combine

@MainActor
class ElevenLabsTTSManager: NSObject, ObservableObject {
    // MARK: - Published State
    @Published var isPlaying = false
    @Published var isSynthesising = false
    @Published var currentVoiceId: String {
        didSet {
            UserDefaults.standard.set(currentVoiceId, forKey: "selectedVoiceId")
        }
    }

    // MARK: - Private Properties
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?

    // MARK: - Initialization
    override init() {
        // Load saved voice or default to Rachel (English)
        self.currentVoiceId = UserDefaults.standard.string(forKey: "selectedVoiceId") ?? "21m00Tcm4TlvDq8ikWAM"
        super.init()
    }

    // MARK: - Public Methods

    /// Synthesise text to speech and play
    func synthesise(text: String, voiceId: String? = nil) async throws {
        guard !text.isEmpty else { return }

        let voiceToUse = voiceId ?? currentVoiceId

        isSynthesising = true
        defer { isSynthesising = false }

        // Get auth token
        guard let token = AuthTokenManager.shared.getAccessToken() else {
            throw TTSError.noAuthToken
        }

        // Build request
        guard let url = URL(string: "\(Constants.API_BASE_URL)/api/v1/voice/tts") else {
            throw TTSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "text": text,
            "voice_id": voiceToUse
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Call backend
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TTSError.serverError(httpResponse.statusCode)
        }

        // Save audio to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")

        try data.write(to: tempURL)

        // Play audio
        await play(from: tempURL)
    }

    /// Stop playback
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false

        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        player = nil
        playerItem = nil
    }

    /// Pause playback
    func pause() {
        guard isPlaying else { return }
        player?.pause()
        isPlaying = false
    }

    /// Resume playback
    func resume() {
        guard !isPlaying, player != nil else { return }
        player?.play()
        isPlaying = true
    }

    // MARK: - Private Methods

    private func play(from url: URL) async {
        // Stop any existing playback
        stop()

        // Create player
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Observe playback end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackEnded),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // Start playback
        isPlaying = true
        player?.play()
    }

    @objc private func playbackEnded() {
        isPlaying = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}

// MARK: - Error Types
enum TTSError: LocalizedError {
    case noAuthToken
    case invalidURL
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .noAuthToken:
            return "No authentication token available"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}
