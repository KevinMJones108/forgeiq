//
//  ProfileViewModel.swift
//  ForgeIQ
//
//  Session 9/10 — profile info + rep stats for the dashboard
//

import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published State

    @Published var profile: UserProfile?
    @Published var repStats: RepStats?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Loading

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await APIClient.shared.getMe()
        } catch {
            errorMessage = error.localizedDescription
        }

        // Rep stats are non-fatal — dashboard simply shows zeros until calls exist
        do {
            repStats = try await APIClient.shared.getRepStats()
        } catch {
            if errorMessage == nil {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}
