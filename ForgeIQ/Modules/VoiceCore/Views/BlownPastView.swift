//
//  BlownPastView.swift
//  ForgeIQ
//
//  Session 10 — Blown Past Detector: signals the rep talked past
//

import SwiftUI

struct BlownPastView: View {
    // MARK: - Properties

    let signals: [BlownPastSignal]

    // MARK: - Body

    var body: some View {
        ZStack {
            Constants.FORGEIQ_FORGE
                .ignoresSafeArea()

            if signals.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(signals) { signal in
                            BlownPastSignalCard(signal: signal)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Blown Past Signals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundColor(Constants.FORGEIQ_GREEN)

            Text("Nothing blown past")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("The AI found no buying signals you talked past on this call.")
                .font(.system(size: 14))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Signal Card

struct BlownPastSignalCard: View {
    let signal: BlownPastSignal

    private var severityColor: Color {
        switch signal.severity {
        case .high: return .red
        case .med: return .orange
        case .low: return .yellow
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(signal.signalType.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(severityColor)
                    .cornerRadius(6)

                Spacer()

                Label(signal.timestamp, systemImage: "clock")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
            }

            Text("“\(signal.prospectSaid)”")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .italic()

            labelledRow(title: "Signal", text: signal.signalDescription)
            labelledRow(title: "What happened", text: signal.whatHappened)

            VStack(alignment: .leading, spacing: 4) {
                Text("Say next time")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Constants.FORGEIQ_GREEN)
                Text(signal.suggestedResponse)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Constants.FORGEIQ_GREEN.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Constants.FORGEIQ_FORGE.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func labelledRow(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}
