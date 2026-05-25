//
//  FilesViewModel.swift
//  ForgeIQ
//
//  Session 7 — Files Module: ViewModel for FilesTabView
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
            let audioFiles = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "m4a" }

            recordings = audioFiles.compactMap { audioURL -> Recording? in
                guard let attributes = try? fileManager.attributesOfItem(atPath: audioURL.path),
                      let creationDate = attributes[.creationDate] as? Date else {
                    return nil
                }

                // Load transcript if exists
                let transcriptFileName = audioURL.deletingPathExtension().lastPathComponent + ".txt"
                let transcriptURL = documentsDirectory.appendingPathComponent(transcriptFileName)
                let transcript = loadTranscript(from: transcriptURL)

                // Derive duration from audio file metadata (placeholder — real impl in Session 8+)
                let duration: TimeInterval = 0 // TODO: Extract from AVAsset in future session

                return Recording(
                    id: UUID(uuidString: audioURL.deletingPathExtension().lastPathComponent) ?? UUID(),
                    title: audioURL.deletingPathExtension().lastPathComponent,
                    audioURL: audioURL,
                    duration: duration,
                    createdAt: creationDate,
                    language: "en", // TODO: Extract from transcript metadata
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
            // Delete audio file
            try fileManager.removeItem(at: recording.audioURL)

            // Delete transcript file if exists
            let transcriptURL = documentsDirectory.appendingPathComponent(recording.transcriptFileName)
            if fileManager.fileExists(atPath: transcriptURL.path) {
                try fileManager.removeItem(at: transcriptURL)
            }

            // Remove from array
            recordings.removeAll { $0.id == recording.id }
        } catch {
            errorMessage = "Failed to delete recording: \(error.localizedDescription)"
        }
    }

    func shareRecording(_ recording: Recording) -> [Any] {
        var itemsToShare: [Any] = [recording.audioURL]

        let transcriptURL = documentsDirectory.appendingPathComponent(recording.transcriptFileName)
        if fileManager.fileExists(atPath: transcriptURL.path) {
            itemsToShare.append(transcriptURL)
        }

        return itemsToShare
    }

    // MARK: - Private Methods

    private func loadTranscript(from url: URL) -> Transcript? {
        guard fileManager.fileExists(atPath: url.path),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        // Parse transcript file format
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 5 else { return nil }

        // Extract language
        let languageLine = lines.first { $0.hasPrefix("Language:") } ?? ""
        let language = languageLine.replacingOccurrences(of: "Language:", with: "").trimmingCharacters(in: .whitespaces)

        // Extract original text (everything between Language line and --- separator)
        let separatorIndex = lines.firstIndex { $0.hasPrefix("---") }
        let textStartIndex = lines.firstIndex { $0.hasPrefix("Language:") }.map { $0 + 2 } ?? 5
        let textEndIndex = separatorIndex ?? lines.count
        let originalText = lines[textStartIndex..<textEndIndex]
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract translation if exists
        var translatedText: String?
        var targetLanguage: String?
        if let separatorIdx = separatorIndex, separatorIdx + 2 < lines.count {
            let translationHeaderLine = lines[separatorIdx + 1]
            if translationHeaderLine.hasPrefix("Translation") {
                // Extract target language from "Translation (es):"
                let pattern = #"Translation \(([a-z]{2})\):"#
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: translationHeaderLine, range: NSRange(translationHeaderLine.startIndex..., in: translationHeaderLine)),
                   let range = Range(match.range(at: 1), in: translationHeaderLine) {
                    targetLanguage = String(translationHeaderLine[range])
                }

                translatedText = lines[(separatorIdx + 2)...]
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return Transcript(
            originalText: originalText,
            originalLanguage: language,
            translatedText: translatedText,
            targetLanguage: targetLanguage,
            confidence: 1.0
        )
    }
}
