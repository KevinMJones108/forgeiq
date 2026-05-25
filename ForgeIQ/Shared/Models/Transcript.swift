//
//  Transcript.swift
//  ForgeIQ
//
//  Session 7 — Files Module: Transcript Model
//

import Foundation

struct Transcript: Codable, Hashable {
    let originalText: String
    let originalLanguage: String // ISO 639-1
    let translatedText: String?
    let targetLanguage: String? // ISO 639-1
    let confidence: Float // 0.0 to 1.0

    // MARK: - Computed Properties

    var hasTranslation: Bool {
        translatedText != nil && !(translatedText?.isEmpty ?? true)
    }

    var displayText: String {
        translatedText ?? originalText
    }

    var formattedConfidence: String {
        String(format: "%.1f%%", confidence * 100)
    }

    // MARK: - Initializer

    init(
        originalText: String,
        originalLanguage: String,
        translatedText: String? = nil,
        targetLanguage: String? = nil,
        confidence: Float = 1.0
    ) {
        self.originalText = originalText
        self.originalLanguage = originalLanguage
        self.translatedText = translatedText
        self.targetLanguage = targetLanguage
        self.confidence = confidence
    }

    // MARK: - File Output Format

    func toFileString(duration: String, createdAt: Date) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: createdAt)

        var output = """
        ForgeIQ Transcript
        Date: \(dateString)
        Duration: \(duration)
        Language: \(originalLanguage)

        \(originalText)
        """

        if hasTranslation, let translated = translatedText, let targetLang = targetLanguage {
            output += """


            ---
            Translation (\(targetLang)):
            \(translated)
            """
        }

        return output
    }
}
