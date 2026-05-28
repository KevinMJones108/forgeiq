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
    @StateObject private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appEnvironment)
        }
    }
}
