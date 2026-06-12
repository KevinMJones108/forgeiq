//
//  LoginView.swift
//  ForgeIQ
//
//  Session 9 — Auth0 login screen
//

import SwiftUI

struct LoginView: View {
    // MARK: - State

    @EnvironmentObject var appEnvironment: AppEnvironment
    @State private var isLoggingIn = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Constants.FORGEIQ_FORGE
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Brand mark
                Circle()
                    .fill(Constants.FORGEIQ_GREEN.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: "waveform.and.mic")
                            .font(.system(size: 56))
                            .foregroundColor(Constants.FORGEIQ_GREEN)
                    )

                Text("ForgeIQ")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)

                Text("Sales intelligence, forged from every call")
                    .font(.system(size: 16))
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
                    .multilineTextAlignment(.center)

                Spacer()

                if let errorMessage = appEnvironment.authErrorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                ForgeButton(title: "Sign In", systemImage: "person.fill", isLoading: isLoggingIn) {
                    isLoggingIn = true
                    Task {
                        await appEnvironment.login()
                        isLoggingIn = false
                    }
                }
                .padding(.horizontal, 32)

                Text("Powered by alviz.ai")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
                    .padding(.bottom, 24)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appEnvironment.authErrorMessage)
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AppEnvironment())
}
