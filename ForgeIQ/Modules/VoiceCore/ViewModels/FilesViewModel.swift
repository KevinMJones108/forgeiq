//
//  FilesViewModel.swift
//  ForgeIQ
//
//  Session 7 — Files Module: ViewModel for FilesTabView (reads .txt transcripts)
//

import Foundation
import SwiftUI

@MainActor
class FilesViewModel: ObservableObject {
    @Published var recordings: [Recording] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Computed Properties

    var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            return recordings.sorted { $0.createdAt > $1.createdAt }
        } else {
            return recordings.filter { recording in
                recording.title.localizedCaseInsensitiveContains(searchText) ||
                recording.transcript?.originalText.localizedCaseInsensitiveContains(searchText) == true ||
                recording.transcript?.translatedText?.localizedCaseInsensitiveContains(searchText) == true
            }.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // MARK: - Lifecycle

    init() {
        loadRecordings()
    }

    // MARK: - Public Methods

    func loadRecordings() {
        isLoading = true
        errorMessage = nil

        do {
            // Find all .txt files in Documents directory
            let txtFiles = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "txt" }

            recordings = txtFiles.compactMap { txtURL -> Recording? in
                guard let attributes = try? fileManager.attributesOfItem(atPath: txtURL.path),
                      let creationDate = attributes[.creationDate] as? Date else {
                    return nil
                }

                // Parse transcript file
                guard let content = try? String(contentsOf: txtURL, encoding: .utf8) else {
                    return nil
                }

                let transcript = parseTranscript(from: content)
                let metadata = parseMetadata(from: content)

                // Derive title from filename (e.g., "2026-05-20_1432_We-keep-losing.txt")
                let title = txtURL.deletingPathExtension().lastPathComponent

                return Recording(
                    id: UUID(),
                    title: title,
                    audioURL: txtURL, // Reusing audioURL field for .txt path
                    duration: metadata.duration,
                    createdAt: creationDate,
                    language: metadata.language,
                    transcript: transcript
                )
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load recordings: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func deleteRecording(_ recording: Recording) {
        do {
            // Delete .txt file
            try fileManager.removeItem(at: recording.audioURL)

            // Remove from array
            recordings.removeAll { $0.id == recording.id }
        } catch {
            errorMessage = "Failed to delete recording: \(error.localizedDescription)"
        }
    }

    func shareRecording(_ recording: Recording) -> [Any] {
        return [recording.audioURL]
    }

    // MARK: - Private Methods

    private func parseTranscript(from content: String) -> Transcript? {
        let lines = content.components(separatedBy: .newlines)

        // Find TRANSCRIPT section
        guard let transcriptStart = lines.firstIndex(where: { $0 == "TRANSCRIPT" }) else {
            return nil
        }

        // Find next separator or TRANSLATION section
        let transcriptEnd = lines[(transcriptStart + 1)...].firstIndex { line in
            line.hasPrefix("──────") || line == "TRANSLATION"
        } ?? lines.count

        let originalText = lines[(transcriptStart + 2)..<transcriptEnd]
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse translation if exists
        var translatedText: String?
        if let translationStart = lines.firstIndex(where: { $0 == "TRANSLATION" }) {
            let translationContent = lines[(translationStart + 2)...]
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            translatedText = translationContent.isEmpty ? nil : translationContent
        }

        // Extract language from header
        let languageLine = lines.first { $0.hasPrefix("Language:") } ?? ""
        let languageParts = languageLine.replacingOccurrences(of: "Language:", with: "")
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " → ")

        return Transcript(
            originalText: originalText,
            originalLanguage: languageParts.first ?? "Unknown",
            translatedText: translatedText,
            targetLanguage: languageParts.last,
            confidence: 1.0
        )
    }

    private func parseMetadata(from content: String) -> (duration: TimeInterval, language: String, wordCount: Int) {
        let lines = content.components(separatedBy: .newlines)

        // Extract duration (MM:SS format)
        let durationLine = lines.first { $0.hasPrefix("Duration:") } ?? ""
        let durationString = durationLine.replacingOccurrences(of: "Duration:", with: "")
            .trimmingCharacters(in: .whitespaces)
        let durationParts = durationString.components(separatedBy: ":")
        let minutes = Double(durationParts.first ?? "0") ?? 0
        let seconds = Double(durationParts.last ?? "0") ?? 0
        let duration = (minutes * 60) + seconds

        // Extract language
        let languageLine = lines.first { $0.hasPrefix("Language:") } ?? ""
        let language = languageLine.replacingOccurrences(of: "Language:", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Extract word count
        let wordCountLine = lines.first { $0.hasPrefix("Word Count:") } ?? ""
        let wordCountString = wordCountLine.replacingOccurrences(of: "Word Count:", with: "")
            .replacingOccurrences(of: "words", with: "")
            .trimmingCharacters(in: .whitespaces)
        let wordCount = Int(wordCountString) ?? 0

        return (duration, language, wordCount)
    }
}
