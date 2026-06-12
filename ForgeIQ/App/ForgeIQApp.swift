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
