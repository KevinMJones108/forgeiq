//
//  ProfileTabView.swift
//  ForgeIQ
//
//  Session 9/10 — user info, rep stats, sign out
//

import SwiftUI

struct ProfileTabView: View {
    // MARK: - State

    @EnvironmentObject var appEnvironment: AppEnvironment
    @StateObject private var viewModel = ProfileViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.FORGEIQ_FORGE
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        NavigationLink {
                            RepDashboardView(stats: viewModel.repStats, repName: displayName)
                        } label: {
                            dashboardLink
                        }

                        ForgeButton(title: "Sign Out", systemImage: "rectangle.portrait.and.arrow.right") {
                            Task {
                                await appEnvironment.logout()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Helpers

    private var displayName: String {
        viewModel.profile?.name ?? appEnvironment.currentUser?.name ?? "Rep"
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Constants.FORGEIQ_GREEN.opacity(0.15))
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Constants.FORGEIQ_GREEN)
                )

            Text(displayName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            if let email = viewModel.profile?.email {
                Text(email)
                    .font(.system(size: 14))
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
            }

            if viewModel.isLoading {
                ProgressView()
                    .tint(Constants.FORGEIQ_GREEN)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Dashboard Link

    private var dashboardLink: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(Constants.FORGEIQ_GREEN)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rep Dashboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text("Call scores, talk time, re-engagement")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
            }

            Spacer()

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

// MARK: - Preview

#Preview {
    ProfileTabView()
        .environmentObject(AppEnvironment())
}
