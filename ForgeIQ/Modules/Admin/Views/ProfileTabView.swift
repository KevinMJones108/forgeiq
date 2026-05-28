//
//  ProfileTabView.swift
//  ForgeIQ
//
//  Session 6 — Profile tab (stub for Phase 1)
//

import SwiftUI

struct ProfileTabView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.FORGEIQ_FORGE.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Constants.FORGEIQ_GREEN)

                    Text("Profile")
                        .font(.title)
                        .foregroundColor(.white)

                    Text("User settings and account management")
                        .foregroundColor(Constants.FORGEIQ_MID_GREY)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Text("Coming in Phase 2")
                        .font(.caption)
                        .foregroundColor(Constants.FORGEIQ_GREEN)
                        .padding(.top, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileTabView()
}
