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
    func translate(text: String, from: Locale, to: Locale) async throws -> String {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw TranslationError.emptyText
        }

        let sourceLang = from.language
        let targetLang = to.language

        // Validate language pair is supported
        let pairSupported = supportedLanguagePairs.contains { pair in
            pair.source == sourceLang && pair.target == targetLang
        }

        guard pairSupported else {
            throw TranslationError.unsupportedLanguagePair(
                from: sourceLang.minimalIdentifier,
                to: targetLang.minimalIdentifier
            )
        }

        isTranslating = true
        errorMessage = nil

        defer {
            isTranslating = false
        }

        do {
            let configuration = TranslationSession.Configuration(
                source: sourceLang,
                target: targetLang
            )

            // Create or reuse translation session
            if translationSession == nil {
                translationSession = TranslationSession(configuration: configuration)

                // Prepare translation (downloads models if needed — first use only)
                await translationSession?.prepareTranslation()
            } else {
                // Update configuration if language pair changed
                translationSession = TranslationSession(configuration: configuration)
                await translationSession?.prepareTranslation()
            }

            guard let session = translationSession else {
                throw TranslationError.sessionCreationFailed
            }

            // Perform translation
            let request = TranslationSession.Request(sourceText: text)
            let response = try await session.translate(request)

            return response.targetText

        } catch {
            errorMessage = "Translation failed: \(error.localizedDescription)"
            throw TranslationError.translationFailed(error)
        }
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
