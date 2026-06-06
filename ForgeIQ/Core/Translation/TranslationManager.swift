//
//  TranslationManager.swift
//  ForgeIQ
//
//  Session 5 — Apple Translation Framework (iOS 18.0+)
//  On-device translation using TranslationSession
//

import Foundation
import Translation

@available(iOS 18.0, *)
@MainActor
class TranslationManager: ObservableObject {
    @Published var isTranslating = false
    @Published var detectedLanguage: String?
    @Published var errorMessage: String?

    private var translationSession: TranslationSession?

    // MARK: - Supported Language Pairs

    private let supportedLanguagePairs: [(source: Locale.Language, target: Locale.Language)] = [
        (.init(identifier: "en"), .init(identifier: "es")), // EN <-> ES
        (.init(identifier: "es"), .init(identifier: "en")),
        (.init(identifier: "en"), .init(identifier: "fr")), // EN <-> FR
        (.init(identifier: "fr"), .init(identifier: "en")),
        (.init(identifier: "en"), .init(identifier: "de")), // EN <-> DE
        (.init(identifier: "de"), .init(identifier: "en")),
        (.init(identifier: "en"), .init(identifier: "zh")), // EN <-> ZH
        (.init(identifier: "zh"), .init(identifier: "en")),
        (.init(identifier: "en"), .init(identifier: "ar")), // EN <-> AR
        (.init(identifier: "ar"), .init(identifier: "en")),
        (.init(identifier: "en"), .init(identifier: "pt")), // EN <-> PT
        (.init(identifier: "pt"), .init(identifier: "en"))
    ]

    // MARK: - Translation

    /// Translate text from source to target language using Apple Translation Framework
    /// - Parameters:
    ///   - text: Text to translate
    ///   - from: Source locale
    ///   - to: Target locale
    /// - Returns: Translated text
    /// - Throws: Translation errors (unsupported language pair, network issues)
    /// Translate text (Phase 2 — use .translationTask SwiftUI modifier).
    /// Phase 1: on-device translation is not yet wired. Instead of throwing (which would
    /// surface an error / risk a crash at any future call site), fail gracefully by
    /// returning the original text unchanged and recording a non-fatal message. This keeps
    /// the shipping flow intact until the iOS 18 Translation API is integrated.
    func translate(text: String, from: Locale, to: Locale) async -> String {
        await MainActor.run {
            self.errorMessage = "Translation is not available yet — returning original text."
        }
        return text
    }
    // MARK: - Language Detection

    /// Detect language of text using Apple's NaturalLanguage framework
    /// - Parameter text: Text to analyze
    /// - Returns: Detected locale or nil if unable to determine
    func detectLanguage(text: String) async throws -> Locale? {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return nil
        }

        return await Task {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)

            guard let languageCode = recognizer.dominantLanguage?.rawValue else {
                return nil
            }

            // Set detected language for UI display
            await MainActor.run {
                self.detectedLanguage = self.languageDisplayName(languageCode)
            }

            // Return locale with detected language
            return Locale(languageCode: .init(languageCode))

        }.value
    }

    // MARK: - Helpers

    /// Get display name for language code
    private func languageDisplayName(_ code: String) -> String {
        let locale = Locale(languageCode: .init(code))
        return locale.localizedString(forLanguageCode: code)?.capitalized ?? code.uppercased()
    }

    /// Check if a language pair is supported
    func isLanguagePairSupported(from: Locale, to: Locale) -> Bool {
        let sourceLang = from.language
        let targetLang = to.language

        return supportedLanguagePairs.contains { pair in
            pair.source == sourceLang && pair.target == targetLang
        }
    }
}

// MARK: - Translation Errors

enum TranslationError: LocalizedError {
    case emptyText
    case unsupportedLanguagePair(from: String, to: String)
    case sessionCreationFailed
    case translationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "No text to translate"
        case .unsupportedLanguagePair(let from, let to):
            return "Translation from \(from.uppercased()) to \(to.uppercased()) is not supported"
        case .sessionCreationFailed:
            return "Failed to create translation session"
        case .translationFailed(let error):
            return "Translation failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - NaturalLanguage Import

import NaturalLanguage
