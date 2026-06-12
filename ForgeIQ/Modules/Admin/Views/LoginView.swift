//
//  LoginView.swift
//  ForgeIQ
//
//  Auth0 Universal Login entry screen.
//  Shown by ForgeIQApp when appEnvironment.isAuthenticated == false.
//

import SwiftUI
import Auth0

struct LoginView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment

    // MARK: - State

    @State private var isSigningIn = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        ZStack {
            Constants.FORGEIQ_FORGE.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                branding
                Spacer()
                errorBanner
                signInButton
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Branding

    private var branding: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 96))
                .foregroundColor(Constants.FORGEIQ_GREEN)

            Text("ForgeIQ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Sales intelligence, forged from every call.")
                .font(.subheadline)
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Error Banner

    @ViewBuilder
    private var errorBanner: some View {
        if let errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.red.opacity(0.35))
                .cornerRadius(10)
                .transition(.opacity)
        }
    }

    // MARK: - Sign In Button

    private var signInButton: some View {
        Button {
            signIn()
        } label: {
            HStack {
                if isSigningIn {
                    ProgressView()
                        .tint(Constants.FORGEIQ_FORGE)
                } else {
                    Image(systemName: "person.badge.key.fill")
                }
                Text(isSigningIn ? "Signing In…" : "Sign In")
                    .fontWeight(.semibold)
            }
            .foregroundColor(Constants.FORGEIQ_FORGE)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Constants.FORGEIQ_GREEN)
            .cornerRadius(12)
        }
        .disabled(isSigningIn)
    }

    // MARK: - Auth0 Sign In

    private func signIn() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring()) {
            isSigningIn = true
            errorMessage = nil
        }

        Auth0
            .webAuth(clientId: Constants.AUTH0_CLIENT_ID, domain: Constants.AUTH0_DOMAIN)
            .audience(Constants.AUTH0_AUDIENCE)
            .scope("openid profile email offline_access")
            .start { result in
                Task { @MainActor in
                    handle(result)
                }
            }
    }

    // MARK: - Result Handling

    @MainActor
    private func handle(_ result: WebAuthResult<Credentials>) {
        switch result {
        case .success(let credentials):
            // Reuse the existing AuthTokenManager Keychain pattern — JWTs never touch UserDefaults.
            AuthTokenManager.shared.saveAccessToken(credentials.accessToken)
            if let refreshToken = credentials.refreshToken {
                AuthTokenManager.shared.saveRefreshToken(refreshToken)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring()) {
                isSigningIn = false
                appEnvironment.isAuthenticated = true
            }
        case .failure(let error):
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.spring()) {
                isSigningIn = false
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AppEnvironment())
}
