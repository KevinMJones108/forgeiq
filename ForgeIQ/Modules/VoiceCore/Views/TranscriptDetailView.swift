//
//  TranscriptDetailView.swift
//  ForgeIQ
//
//  Session 7 — Files Module: Read, share, ElevenLabs read-back
//

import SwiftUI
import AVFoundation

struct TranscriptDetailView: View {
    let recording: Recording

    @Environment(\.dismiss) private var dismiss
    @State private var isPlayingTTS = false
    @State private var showingLanguageSelection = false
    @State private var showingShareSheet = false
    @State private var itemsToShare: [Any] = []
    @State private var errorMessage: String?
    @State private var audioPlayer: AVPlayer?

    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var body: some View {
        ZStack {
            Constants.FORGEIQ_FORGE.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Transcript Section
                    transcriptSection

                    // Translation Section (if exists)
                    if recording.transcript?.hasTranslation == true {
                        translationSection
                    }

                    // Action Buttons
                    actionButtons

                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    shareRecording()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Constants.FORGEIQ_GREEN)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityViewController(activityItems: itemsToShare)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recording.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            HStack {
                Label(recording.formattedDate, systemImage: "calendar")
                Spacer()
                Label(recording.formattedDuration, systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(Constants.FORGEIQ_MID_GREY)

            if let transcript = recording.transcript {
                Label("Language: \(transcript.originalLanguage.uppercased())", systemImage: "globe")
                    .font(.caption)
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)

                if transcript.confidence < 1.0 {
                    Label("Confidence: \(transcript.formattedConfidence)", systemImage: "checkmark.seal")
                        .font(.caption)
                        .foregroundColor(Constants.FORGEIQ_MID_GREY)
                }
            }
        }
    }

    // MARK: - Transcript Section

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transcript")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    copyToClipboard(recording.transcript?.originalText ?? "")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(Constants.FORGEIQ_GREEN)
                }
            }

            Text(recording.transcript?.originalText ?? "No transcript available")
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
        }
    }

    // MARK: - Translation Section

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Translation (\(recording.transcript?.targetLanguage?.uppercased() ?? ""))")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    copyToClipboard(recording.transcript?.translatedText ?? "")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(Constants.FORGEIQ_GREEN)
                }
            }

            Text(recording.transcript?.translatedText ?? "")
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Play Original Audio
            Button {
                playAudioRecording()
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Play Original Recording")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Constants.FORGEIQ_NAVY)
                .cornerRadius(12)
            }

            // ElevenLabs Read-Back
            Button {
                readTranscriptWithElevenLabs()
            } label: {
                HStack {
                    if isPlayingTTS {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Generating audio...")
                    } else {
                        Image(systemName: "speaker.wave.3.fill")
                        Text("Read Transcript (ElevenLabs)")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Constants.FORGEIQ_GREEN)
                .cornerRadius(12)
            }
            .disabled(isPlayingTTS || recording.transcript == nil)
        }
    }

    // MARK: - Private Methods

    private func playAudioRecording() {
        audioPlayer = AVPlayer(url: recording.audioURL)
        audioPlayer?.play()
    }

    private func readTranscriptWithElevenLabs() {
        guard let transcript = recording.transcript else {
            errorMessage = "No transcript available"
            return
        }

        isPlayingTTS = true
        errorMessage = nil

        Task {
            do {
                // Call backend TTS endpoint
                let url = URL(string: "\(Constants.API_BASE_URL)/api/v1/voice/tts")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                // TODO: Add JWT token header in Session 10 (Auth0)

                let body: [String: Any] = [
                    "text": transcript.displayText,
                    "voice_id": "default" // TODO: Allow user to select voice
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NSError(domain: "ElevenLabs", code: -1, userInfo: [NSLocalizedDescriptionKey: "TTS request failed"])
                }

                // Save audio to temp file and play
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tts_\(UUID().uuidString).mp3")
                try data.write(to: tempURL)

                await MainActor.run {
                    audioPlayer = AVPlayer(url: tempURL)
                    audioPlayer?.play()
                    isPlayingTTS = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "ElevenLabs TTS failed: \(error.localizedDescription)"
                    isPlayingTTS = false
                }
            }
        }
    }

    private func shareRecording() {
        var items: [Any] = [recording.audioURL]

        let transcriptURL = documentsDirectory.appendingPathComponent(recording.transcriptFileName)
        if fileManager.fileExists(atPath: transcriptURL.path) {
            items.append(transcriptURL)
        }

        itemsToShare = items
        showingShareSheet = true
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        // TODO: Show toast notification in future session
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TranscriptDetailView(
            recording: Recording(
                id: UUID(),
                title: "Sample Recording",
                audioURL: URL(fileURLWithPath: "/tmp/sample.m4a"),
                duration: 125,
                createdAt: Date(),
                language: "en",
                transcript: Transcript(
                    originalText: "This is a sample transcript for preview purposes.",
                    originalLanguage: "en",
                    translatedText: "Este es un ejemplo de transcripción para fines de vista previa.",
                    targetLanguage: "es",
                    confidence: 0.95
                )
            )
        )
    }
}
