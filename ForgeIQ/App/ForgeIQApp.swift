//
//  ForgeIQApp.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 6 — Main app entry with tab navigation
//

import SwiftUI

@main
struct ForgeIQApp: App {
    @StateObject private var appEnvironment: AppEnvironment

    // MARK: - Init

    init() {
        let environment = AppEnvironment()
        // Existing session check — a stored Auth0 access token in the Keychain skips login.
        environment.isAuthenticated = AuthTokenManager.shared.getAccessToken() != nil
        #if DEBUG
        // DEBUG-ONLY (2026-06-25, Kevin): skip the Auth0 login wall so the app can be tested on-device
        // without a login code. RELEASE builds keep the real auth gate — production login is unchanged.
        // Note: backend calls that need a JWT will 401 until signed in, but on-device record→transcribe
        // (Apple Speech, no backend) works without it — enough to validate VoiceCore on the phone.
        // To test the real login flow instead, comment out the next line.
        environment.isAuthenticated = true
        #endif
        _appEnvironment = StateObject(wrappedValue: environment)
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            Group {
                if appEnvironment.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(appEnvironment)
            .animation(.spring(), value: appEnvironment.isAuthenticated)
        }
    }
}
