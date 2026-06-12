//
//  RepDashboardView.swift
//  ForgeIQ
//
//  Session 10 — per-rep dashboard (Owen and Kevin each see only their own data)
//

import SwiftUI

struct RepDashboardView: View {
    // MARK: - Properties

    let stats: RepStats?
    let repName: String

    // MARK: - Body

    var body: some View {
        ZStack {
            Constants.FORGEIQ_FORGE
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("\(repName)'s Performance")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let stats {
                        statGrid(stats)
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Rep Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Stat Grid

    private func statGrid(_ stats: RepStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(
                title: "Calls Analysed",
                value: "\(stats.totalCalls)",
                icon: "phone.fill"
            )
            statCard(
                title: "Avg Call Score",
                value: stats.avgCallScore.map { String(format: "%.1f/10", $0) } ?? "—",
                icon: "star.fill"
            )
            statCard(
                title: "Avg Talk Time",
                value: stats.avgTalkTimeRepPct.map { "\($0)%" } ?? "—",
                icon: "person.wave.2.fill"
            )
            statCard(
                title: "Re-Engagements",
                value: "\(stats.reEngagementCount)",
                icon: "arrow.uturn.left.circle.fill"
            )
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Constants.FORGEIQ_GREEN)

            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Constants.FORGEIQ_FORGE.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Constants.FORGEIQ_GREEN.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)

            Text("No call data yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text("Record a call and generate an AI summary to see your stats here.")
                .font(.system(size: 14))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RepDashboardView(
            stats: RepStats(totalCalls: 12, avgCallScore: 7.2, avgTalkTimeRepPct: 41, reEngagementCount: 3),
            repName: "Owen"
        )
    }
}
