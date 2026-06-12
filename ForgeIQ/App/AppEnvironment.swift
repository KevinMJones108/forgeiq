//
//  AppEnvironment.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 1 — Xcode project creation
//  Session 9 — Auth0 login flow + backend user sync
//

import SwiftUI

@MainActor
class AppEnvironment: ObservableObject {
    // MARK: - Published State

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authErrorMessage: String?

    // MARK: - Init

    init() {
        // Restore session if a JWT is already in the Keychain
        isAuthenticated = AuthTokenManager.shared.hasValidToken
    }

    // MARK: - Auth Actions

    func login() async {
        authErrorMessage = nil
        do {
            _ = try await AuthTokenManager.shared.login()

            // First-login sync: creates the user + subscription row if new
            do {
                currentUser = try await APIClient.shared.syncUser(email: "", name: nil)
            } catch {
                // Sync failure is non-fatal at login; /auth/me retries later
                print("User sync failed: \(error.localizedDescription)")
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAuthenticated = true
            }
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func logout() async {
        await AuthTokenManager.shared.logout()
        currentUser = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isAuthenticated = false
        }
    }
}
