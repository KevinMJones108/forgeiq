//
//  TranscriptDetailView.swift
//  ForgeIQ
//
//  Session 7 — Files Module: Read, share, ElevenLabs read-back
//

import SwiftUI

struct TranscriptDetailView: View {
    let recording: Recording

    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var itemsToShare: [Any] = []
    @State private var errorMessage: String?

    private let fileManager = FileManager.default

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
            // Sales Intel — objection / blew-past analysis
            if let transcriptText = recording.transcript?.originalText,
               !transcriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                NavigationLink {
                    CallAnalysisView(transcript: transcriptText)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Analyze Call (Sales Intel)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.FORGEIQ_GREEN)
                    .cornerRadius(12)
                }
            }

            // Share transcript (.txt)
            Button {
                shareRecording()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Transcript")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Private Methods

    private func shareRecording() {
        // recording.audioURL holds the saved .txt transcript path (set by FilesViewModel).
        var items: [Any] = []
        if fileManager.fileExists(atPath: recording.audioURL.path) {
            items.append(recording.audioURL)
        } else if let text = recording.transcript?.displayText {
            items.append(text)
        }
        guard !items.isEmpty else {
            errorMessage = "Nothing to share"
            return
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
