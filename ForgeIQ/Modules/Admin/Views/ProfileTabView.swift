//
//  ProfileTabView.swift
//  ForgeIQ
//
//  Session 6 — Profile tab (stub for Phase 1)
//

import SwiftUI

struct ProfileTabView: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.FORGEIQ_FORGE.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Constants.FORGEIQ_GREEN)

                    Text("ForgeIQ")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Record any conversation and get an instant, on-device transcript you can save and share.")
                        .font(.subheadline)
                        .foregroundColor(Constants.FORGEIQ_MID_GREY)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    VStack(spacing: 8) {
                        infoRow(label: "Version", value: appVersion)
                        infoRow(label: "Transcription", value: "On-device (Apple Speech)")
                        infoRow(label: "Privacy", value: "Transcripts stay on your iPhone")
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
            Spacer()
            Text(value)
                .font(.footnote)
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Constants.FORGEIQ_GREEN.opacity(0.15)),
            alignment: .bottom
        )
    }
}

// MARK: - Preview

#Preview {
    ProfileTabView()
}
