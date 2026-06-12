//
//  TranscriptCard.swift
//  ForgeIQ
//
//  Shared component — compact transcript preview card
//

import SwiftUI

struct TranscriptCard: View {
    // MARK: - Properties

    let recording: Recording

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(Constants.FORGEIQ_GREEN)

                Text(recording.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Text(recording.formattedDuration)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
            }

            if let transcript = recording.transcript {
                Text(transcript.originalText)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)

                if transcript.hasTranslation {
                    Label("Translated", systemImage: "globe")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Constants.FORGEIQ_BLUE)
                }
            } else {
                Text("No transcript")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
            }

            Text(recording.formattedDate)
                .font(.system(size: 12))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
        }
        .padding()
        .background(Constants.FORGEIQ_FORGE.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Constants.FORGEIQ_GREEN.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}
