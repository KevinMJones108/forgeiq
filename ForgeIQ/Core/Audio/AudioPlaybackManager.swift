//
//  AudioPlaybackManager.swift
//  ForgeIQ
//
//  Phase 1 — local audio playback for saved .m4a recordings
//

import Foundation
import AVFoundation

@MainActor
class AudioPlaybackManager: NSObject, ObservableObject {
    // MARK: - Published State

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var errorMessage: String?

    // MARK: - Private State

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    // MARK: - Playback Controls

    func play(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.play()

            player = audioPlayer
            duration = audioPlayer.duration
            isPlaying = true
            errorMessage = nil
            startProgressTimer()
        } catch {
            errorMessage = "Playback failed: \(error.localizedDescription)"
            isPlaying = false
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    func resume() {
        player?.play()
        isPlaying = true
        startProgressTimer()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        stopProgressTimer()
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.player else { return }
                self.currentTime = player.currentTime
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.stopProgressTimer()
        }
    }
}
