import SwiftUI

struct TranscriptView: View {
    // MARK: - Properties

    @ObservedObject var transcriptionManager: SpeechTranscriptionManager

    @State private var showCursor = true

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Transcript text
                    if !transcriptionManager.transcriptText.isEmpty {
                        Text(transcriptionManager.transcriptText)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .transition(.opacity)
                            .animation(.easeIn(duration: 0.3), value: transcriptionManager.transcriptText)
                            .id("transcript")
                    } else if transcriptionManager.isTranscribing {
                        Text("Listening...")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.6))
                            .italic()
                            .padding()
                    } else {
                        Text("Tap to start recording")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.4))
                            .italic()
                            .padding()
                    }

                    // Blinking cursor when transcribing
                    if transcriptionManager.isTranscribing {
                        HStack {
                            Rectangle()
                                .fill(Color(hex: "#00C853")) // ForgeGreen
                                .frame(width: 2, height: 20)
                                .opacity(showCursor ? 1.0 : 0.0)
                                .animation(
                                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                    value: showCursor
                                )
                                .onAppear {
                                    showCursor.toggle()
                                }

                            Spacer()
                        }
                        .padding(.leading)
                        .id("cursor")
                    }

                    // Confidence indicator
                    if transcriptionManager.confidence > 0 {
                        HStack {
                            Text("Confidence:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))

                            Text("\(Int(transcriptionManager.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(confidenceColor(transcriptionManager.confidence))
                        }
                        .padding(.horizontal)
                    }

                    // Error message
                    if let errorMessage = transcriptionManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(hex: "#1C2B2B")) // FORGE dark
            .onChange(of: transcriptionManager.transcriptText) { _ in
                // Auto-scroll to bottom when new text arrives
                withAnimation {
                    proxy.scrollTo("cursor", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Helpers

    private func confidenceColor(_ confidence: Float) -> Color {
        if confidence >= 0.8 {
            return Color(hex: "#00C853") // ForgeGreen - high confidence
        } else if confidence >= 0.5 {
            return Color(hex: "#2E75B6") // Blue - medium confidence
        } else {
            return .orange // Low confidence
        }
    }
}

// Color extension removed - declared in Constants.swift
