//
//  CallSummaryView.swift
//  ForgeIQ
//
//  Session 10 — AI Call Summary screen (score, talk time, blown past, CRM log)
//

import SwiftUI

struct CallSummaryView: View {
    // MARK: - Properties

    let recordingId: UUID?
    let transcript: String
    let contactName: String
    let duration: String?

    @StateObject private var viewModel = CallSummaryViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            Constants.FORGEIQ_FORGE
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isGenerating {
                        generatingState
                    } else if let summary = viewModel.callSummary {
                        summaryContent(summary)
                    } else if let errorMessage = viewModel.errorMessage {
                        errorState(errorMessage)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("AI Call Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            if viewModel.callSummary == nil {
                await viewModel.generateSummary(recordingId: recordingId, transcript: transcript)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isGenerating)
    }

    // MARK: - States

    private var generatingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Constants.FORGEIQ_GREEN)
                .scaleEffect(1.4)
            Text("Analysing call with AI…")
                .font(.system(size: 15))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
        }
        .padding(.top, 80)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            ForgeButton(title: "Retry", systemImage: "arrow.clockwise") {
                Task {
                    await viewModel.generateSummary(recordingId: recordingId, transcript: transcript)
                }
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Summary Content

    @ViewBuilder
    private func summaryContent(_ summary: CallSummary) -> some View {
        CallScoreHeader(summary: summary)

        sectionCard(title: "Summary", icon: "doc.text.fill") {
            Text(summary.summary)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }

        if !summary.wentWell.isEmpty {
            bulletSection(title: "What Went Well", icon: "hand.thumbsup.fill", items: summary.wentWell)
        }

        if !summary.learningPoints.isEmpty {
            bulletSection(title: "Learning Points", icon: "lightbulb.fill", items: summary.learningPoints)
        }

        NavigationLink {
            BlownPastView(signals: summary.blownPast)
        } label: {
            blownPastLink(summary)
        }

        if !summary.commitments.isEmpty {
            sectionCard(title: "Commitments", icon: "checklist") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(summary.commitments) { commitment in
                        HStack(alignment: .top, spacing: 8) {
                            Text(commitment.owner)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Constants.FORGEIQ_GREEN)
                                .frame(width: 70, alignment: .leading)
                            Text("\(commitment.text) — \(commitment.due)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }
        }

        if let nextStep = summary.nextStep, !nextStep.isEmpty {
            sectionCard(title: "Next Step", icon: "arrow.right.circle.fill") {
                Text(nextStep)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Constants.FORGEIQ_GREEN)
            }
        }

        if let crmMessage = viewModel.crmLogMessage {
            Text(crmMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Constants.FORGEIQ_GREEN)
                .multilineTextAlignment(.center)
        } else {
            ForgeButton(title: "Log to Pipedrive", systemImage: "tray.and.arrow.up.fill", isLoading: viewModel.isLoggingToCRM) {
                Task {
                    await viewModel.logToPipedrive(contactName: contactName, duration: duration)
                }
            }
        }

        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 13))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Section Builders

    private func sectionCard(title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Constants.FORGEIQ_GREEN)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Constants.FORGEIQ_FORGE.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Constants.FORGEIQ_GREEN.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func bulletSection(title: String, icon: String, items: [String]) -> some View {
        sectionCard(title: title, icon: icon) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Constants.FORGEIQ_GREEN)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
    }

    private func blownPastLink(_ summary: CallSummary) -> some View {
        HStack {
            Image(systemName: "exclamationmark.bubble.fill")
                .foregroundColor(summary.blownPast.isEmpty ? Constants.FORGEIQ_GREEN : .orange)
            Text("Blown Past Signals")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Text("\(summary.blownPast.count)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(summary.blownPast.isEmpty ? Constants.FORGEIQ_GREEN : .orange)
            Image(systemName: "chevron.right")
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

// MARK: - Call Score Header

struct CallScoreHeader: View {
    let summary: CallSummary

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Constants.FORGEIQ_MID_GREY.opacity(0.3), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(summary.callScore ?? 0) / 10.0)
                    .stroke(Constants.FORGEIQ_GREEN, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(summary.callScore.map { "\($0)" } ?? "—")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 100, height: 100)

            Text("Call Score")
                .font(.system(size: 13))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)

            if let rep = summary.talkTimeRepPct, let prospect = summary.talkTimeProspectPct {
                talkTimeBar(rep: rep, prospect: prospect)
            }

            if summary.reEngagementCandidate {
                Label("Re-Engagement Candidate", systemImage: "arrow.uturn.left.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.orange)
            }
        }
    }

    private func talkTimeBar(rep: Int, prospect: Int) -> some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Constants.FORGEIQ_BLUE)
                        .frame(width: geometry.size.width * CGFloat(rep) / 100.0)
                    Rectangle()
                        .fill(Constants.FORGEIQ_GREEN)
                }
                .cornerRadius(4)
            }
            .frame(height: 10)

            HStack {
                Text("You \(rep)%")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.FORGEIQ_BLUE)
                Spacer()
                Text("Prospect \(prospect)%")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.FORGEIQ_GREEN)
            }
        }
        .padding(.horizontal, 24)
    }
}
