//
//  ProfileTabView.swift
//  ForgeIQ
//
//  Session 6 — Profile tab (stub for Phase 1)
//  Session 13 — Sign Out + Manage Subscription (Apple 2.1(b) groundwork)
//

import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @Environment(\.openURL) private var openURL

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Body

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

                    VStack(spacing: 12) {
                        manageSubscriptionRow
                        signOutButton
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Manage Subscription (Apple 2.1(b))

    private var manageSubscriptionRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                openURL(url)
            }
        } label: {
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(Constants.FORGEIQ_GREEN)
                Text("Manage Subscription")
                    .font(.footnote)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.up.forward.square")
                    .font(.footnote)
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Constants.FORGEIQ_GREEN.opacity(0.10))
            .cornerRadius(10)
        }
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            signOut()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.semibold)
            }
            .font(.footnote)
            .foregroundColor(Constants.FORGEIQ_FORGE)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Constants.FORGEIQ_GREEN)
            .cornerRadius(10)
        }
    }

    /// Clears the stored Auth0 JWTs from the Keychain (AuthTokenManager pattern)
    /// and resets app-wide auth state so the root view can return to login.
    private func signOut() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AuthTokenManager.shared.clearTokens()
        withAnimation(.spring()) {
            appEnvironment.isAuthenticated = false
            appEnvironment.currentUser = nil
        }
    }

    // MARK: - Info Row

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
        .environmentObject(AppEnvironment())
}
