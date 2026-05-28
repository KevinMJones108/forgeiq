//
//  MainTabView.swift
//  ForgeIQ
//
//  Session 6 — Tab bar navigation (Home, Files, Profile)
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment

    var body: some View {
        TabView {
            // Home Tab — Recording
            HomeView()
                .environmentObject(appEnvironment.audioManager)
                .environmentObject(appEnvironment.speechManager)
                .environmentObject(appEnvironment.translationManager)
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }

            // Files Tab — Saved transcripts
            FilesTabView()
                .tabItem {
                    Label("Files", systemImage: "doc.text.fill")
                }

            // Profile Tab — User settings
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Constants.FORGEIQ_GREEN)
        .background(Constants.FORGEIQ_FORGE)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AppEnvironment())
}
