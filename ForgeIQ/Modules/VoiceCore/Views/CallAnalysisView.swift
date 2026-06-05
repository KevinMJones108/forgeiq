//
//  CallAnalysisView.swift
//  ForgeIQ
//
//  Sales-intel screen: analyzes a saved transcript for objections and
//  "blew past" moments, then renders the results with a coach summary.
//

import SwiftUI

struct CallAnalysisView: View {
    let transcript: String

    @StateObject private var viewModel = CallAnalysisViewModel()

    var body: some View {
        ZStack {
            Constants.FORGEIQ_FORGE.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch viewModel.state {
                    case .idle:
                        idleSection
                    case .loading:
                        loadingSection
                    case .loaded(let analysis):
                        resultsSection(analysis)
                    case .failed(let message, let isAuth):
                        errorSection(message: message, isAuth: isAuth)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Sales Intel")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Idle (initial)

    private var idleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Objection & Blew-Past Analysis")
                .font(.headline)
                .foregroundColor(.white)

            Text("Run an AI sales coach over this call. It finds every objection the prospect raised and flags any you blew past — with a suggested rebuttal for each.")
                .font(.subheadline)
                .foregroundColor(Constants.FORGEIQ_MID_GREY)

            analyzeButton(title: "Analyze Call")
        }
    }

    // MARK: - Loading

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Constants.FORGEIQ_GREEN))
                .scaleEffect(1.4)
            Text("Analyzing call…")
                .font(.subheadline)
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    // MARK: - Results

    private func resultsSection(_ analysis: CallAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Headline stats
            HStack(spacing: 12) {
                statTile(value: "\(analysis.objections.count)", label: "Objections")
                statTile(value: "\(analysis.blewPastCount)", label: "Blew Past",
                         highlight: analysis.blewPastCount > 0)
                statTile(value: "\(analysis.highSeverityCount)", label: "High Risk",
                         highlight: analysis.highSeverityCount > 0)
            }

            // Talk ratio (if provided)
            if let ratio = analysis.talkRatio,
               (ratio.repPct > 0 || ratio.prospectPct > 0) {
                talkRatioRow(ratio)
            }

            // Coach summary
            if !analysis.summary.isEmpty {
                sectionCard(title: "Coach Summary") {
                    Text(analysis.summary)
                        .font(.body)
                        .foregroundColor(.white)
                }
            }

            // Objections
            Text("Objections")
                .font(.headline)
                .foregroundColor(.white)

            if analysis.objections.isEmpty {
                Text("No objections detected in this call.")
                    .font(.subheadline)
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
            } else {
                ForEach(analysis.objections) { objection in
                    objectionCard(objection)
                }
            }

            // Re-run
            analyzeButton(title: "Re-Analyze")
        }
    }

    private func objectionCard(_ objection: Objection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                badge(text: objection.statusLabel,
                      color: objection.blewPast ? .red : Constants.FORGEIQ_GREEN)
                badge(text: objection.severityLabel,
                      color: severityColor(objection.severity))
                Spacer()
            }

            Text(objection.text)
                .font(.body)
                .foregroundColor(.white)

            if !objection.suggestedResponse.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested rebuttal")
                        .font(.caption)
                        .foregroundColor(Constants.FORGEIQ_GREEN)
                    Text(objection.suggestedResponse)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }

    // MARK: - Error

    private func errorSection(message: String, isAuth: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: isAuth ? "person.crop.circle.badge.exclamationmark" : "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text(isAuth ? "Sign in required" : "Couldn't analyze")
                .font(.headline)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(Constants.FORGEIQ_MID_GREY)

            if !isAuth {
                analyzeButton(title: "Try Again")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.red.opacity(0.12))
        .cornerRadius(12)
    }

    // MARK: - Reusable Pieces

    private func analyzeButton(title: String) -> some View {
        Button {
            Task { await viewModel.analyze(transcript: transcript) }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Constants.FORGEIQ_GREEN)
            .cornerRadius(12)
        }
    }

    private func statTile(value: String, label: String, highlight: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(highlight ? .red : .white)
            Text(label)
                .font(.caption)
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }

    private func talkRatioRow(_ ratio: TalkRatio) -> some View {
        sectionCard(title: "Talk Ratio") {
            HStack {
                Text("Rep \(Int(ratio.repPct))%")
                    .foregroundColor(Constants.FORGEIQ_GREEN)
                Spacer()
                Text("Prospect \(Int(ratio.prospectPct))%")
                    .foregroundColor(Constants.FORGEIQ_BLUE)
            }
            .font(.subheadline)
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "high": return .red
        case "med", "medium": return .orange
        case "low": return Constants.FORGEIQ_BLUE
        default: return Constants.FORGEIQ_MID_GREY
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CallAnalysisView(
            transcript: "Prospect: Honestly the price is higher than we budgeted. Rep: Let me tell you about our features..."
        )
    }
}
