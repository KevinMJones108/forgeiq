//
//  VoicePickerView.swift
//  ForgeIQ
//
//  Voice selection with sample playback for ElevenLabs TTS
//

import SwiftUI

struct VoicePickerView: View {
    @StateObject private var ttsManager = ElevenLabsTTSManager()
    @State private var selectedVoiceId: String

    init() {
        let savedVoiceId = UserDefaults.standard.string(forKey: "selectedVoiceId") ?? "21m00Tcm4TlvDq8ikWAM"
        _selectedVoiceId = State(initialValue: savedVoiceId)
    }

    var body: some View {
        List {
            ForEach(voices) { voice in
                VoiceRow(
                    voice: voice,
                    isSelected: selectedVoiceId == voice.id,
                    isPlaying: ttsManager.isPlaying && ttsManager.currentVoiceId == voice.id,
                    onSelect: {
                        selectedVoiceId = voice.id
                        ttsManager.currentVoiceId = voice.id
                    },
                    onPlaySample: {
                        Task {
                            do {
                                try await ttsManager.synthesise(
                                    text: "Hello, I am ForgeIQ.",
                                    voiceId: voice.id
                                )
                            } catch {
                                print("TTS error: \(error)")
                            }
                        }
                    }
                )
            }
        }
        .navigationTitle("Select Voice")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Voice Data
    private let voices: [Voice] = [
        Voice(id: "21m00Tcm4TlvDq8ikWAM", name: "Rachel", language: "English (US)"),
        Voice(id: "EXAVITQu4vr4xnSDxMaL", name: "Bella", language: "English (US)"),
        Voice(id: "pNInz6obpgDQGcFmaJgB", name: "Adam", language: "English (US)"),
        Voice(id: "onwK4e9ZLuTAKqWW03F9", name: "Daniel", language: "English (UK)"),
        Voice(id: "ThT5KcBeYPX3keUQqHPh", name: "Dorothy", language: "English (UK)"),
        Voice(id: "iP95p4xoKVk53GoZ742B", name: "Charlotte", language: "English (UK)")
    ]
}

// MARK: - Voice Model
struct Voice: Identifiable {
    let id: String
    let name: String
    let language: String
}

// MARK: - Voice Row Component
struct VoiceRow: View {
    let voice: Voice
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPlaySample: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Voice info
            VStack(alignment: .leading, spacing: 4) {
                Text(voice.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(voice.language)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#555555"))
            }

            Spacer()

            // Play sample button
            Button(action: onPlaySample) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(Constants.FORGEIQ_GREEN)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Constants.FORGEIQ_GREEN : Color.clear, lineWidth: 2)
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        VoicePickerView()
            .background(Constants.FORGEIQ_FORGE)
    }
}
