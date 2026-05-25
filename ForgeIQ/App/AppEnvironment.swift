//
//  AppEnvironment.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 1 — Xcode project creation
//

import SwiftUI

@MainActor
class AppEnvironment: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    init() {
        // Auth state check will be added in Auth0 session
    }
}
