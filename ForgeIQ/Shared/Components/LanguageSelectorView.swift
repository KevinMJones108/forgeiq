//
//  LanguageSelectorView.swift
//  ForgeIQ
//
//  Session 5 — Language pair selector with auto-detect + swap
//  Compact 60pt height, sits below main button
//

import SwiftUI

struct LanguageSelectorView: View {
    @Binding var sourceLanguage: LanguageOption
    @Binding var targetLanguage: LanguageOption

    let onSwap: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Source language picker
            languagePicker(
                selection: $sourceLanguage,
                includeAutoDetect: true
            )

            // Swap button
            swapButton

            // Target language picker
            languagePicker(
                selection: $targetLanguage,
                includeAutoDetect: false
            )
        }
        .padding(.horizontal, 20)
        .frame(height: 60)
    }

    // MARK: - Subviews

    private func languagePicker(
        selection: Binding<LanguageOption>,
        includeAutoDetect: Bool
    ) -> some View {
        Picker("", selection: selection) {
            if includeAutoDetect {
                Text("Auto-detect")
                    .tag(LanguageOption.autoDetect)
            }

            ForEach(LanguageOption.supportedLanguages, id: \.self) { lang in
                Text(lang.displayName)
                    .tag(lang)
            }
        }
        .pickerStyle(.menu)
        .tint(Constants.FORGEIQ_GREEN)
        .font(.system(size: 15, weight: .medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }

    private var swapButton: some View {
        Button {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            onSwap()
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Constants.FORGEIQ_GREEN)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
        }
        .disabled(sourceLanguage == .autoDetect)
        .opacity(sourceLanguage == .autoDetect ? 0.4 : 1.0)
    }
}

// MARK: - Language Option Model

enum LanguageOption: Hashable, Identifiable {
    case autoDetect
    case english
    case spanish
    case french
    case german
    case chineseSimplified
    case arabic
    case portuguese

    var id: String {
        switch self {
        case .autoDetect: return "auto"
        case .english: return "en"
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .chineseSimplified: return "zh"
        case .arabic: return "ar"
        case .portuguese: return "pt"
        }
    }

    var displayName: String {
        switch self {
        case .autoDetect: return "Auto-detect"
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .chineseSimplified: return "Chinese"
        case .arabic: return "Arabic"
        case .portuguese: return "Portuguese"
        }
    }

    var locale: Locale? {
        switch self {
        case .autoDetect:
            return nil
        case .english:
            return Locale(languageCode: .init("en"))
        case .spanish:
            return Locale(languageCode: .init("es"))
        case .french:
            return Locale(languageCode: .init("fr"))
        case .german:
            return Locale(languageCode: .init("de"))
        case .chineseSimplified:
            return Locale(languageCode: .init("zh"))
        case .arabic:
            return Locale(languageCode: .init("ar"))
        case .portuguese:
            return Locale(languageCode: .init("pt"))
        }
    }

    static var supportedLanguages: [LanguageOption] {
        [
            .english,
            .spanish,
            .french,
            .german,
            .chineseSimplified,
            .arabic,
            .portuguese
        ]
    }

    static func from(locale: Locale) -> LanguageOption? {
        guard let langCode = locale.language.languageCode?.identifier else {
            return nil
        }

        switch langCode {
        case "en": return .english
        case "es": return .spanish
        case "fr": return .french
        case "de": return .german
        case "zh": return .chineseSimplified
        case "ar": return .arabic
        case "pt": return .portuguese
        default: return nil
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Language Selector")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)

        LanguageSelectorView(
            sourceLanguage: .constant(.autoDetect),
            targetLanguage: .constant(.spanish),
            onSwap: {
                print("Swap tapped")
            }
        )

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Constants.FORGEIQ_FORGE)
}
