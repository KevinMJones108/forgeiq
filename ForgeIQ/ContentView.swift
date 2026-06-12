//
//  ContentView.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 1 — Xcode project creation
//  Session 9 — auth gate + main tab navigation
//

import SwiftUI

struct ContentView: View {
    // MARK: - State

    @EnvironmentObject var appEnvironment: AppEnvironment

    // MARK: - Body

    var body: some View {
        Group {
            if appEnvironment.isAuthenticated {
                mainTabs
            } else {
                LoginView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appEnvironment.isAuthenticated)
    }

    // MARK: - Main Tabs

    private var mainTabs: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Record", systemImage: "mic.fill")
            }

            FilesTabView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }

            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Constants.FORGEIQ_GREEN)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppEnvironment())
        .environmentObject(AudioRecordingManager())
        .environmentObject(SpeechTranscriptionManager())
        .environmentObject(TranslationManager())
        .environmentObject(ElevenLabsTTSManager())
}
