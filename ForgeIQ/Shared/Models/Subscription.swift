//
//  Subscription.swift
//  ForgeIQ
//
//  Session 9 — User profile + feature flags from GET /api/v1/auth/me
//

import Foundation

// Profile returned by the backend: user fields + module feature flags.
// Every module beyond VoiceCore is gated by its flag (Principle 5).
struct UserProfile: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String?
    let createdAt: Date
    let voiceCoreEnabled: Bool?
    let ideaVaultEnabled: Bool?
    let sigmaVaultEnabled: Bool?
    let salesForgeEnabled: Bool?
    let doeEnabled: Bool?
    let apexScriptEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case createdAt = "created_at"
        case voiceCoreEnabled = "voice_core_enabled"
        case ideaVaultEnabled = "idea_vault_enabled"
        case sigmaVaultEnabled = "sigma_vault_enabled"
        case salesForgeEnabled = "sales_forge_enabled"
        case doeEnabled = "doe_enabled"
        case apexScriptEnabled = "apex_script_enabled"
    }

    // MARK: - Feature Flags

    var isVoiceCoreEnabled: Bool { voiceCoreEnabled ?? false }
    var isIdeaVaultEnabled: Bool { ideaVaultEnabled ?? false }
    var isSigmaVaultEnabled: Bool { sigmaVaultEnabled ?? false }
    var isSalesForgeEnabled: Bool { salesForgeEnabled ?? false }
    var isDOEEnabled: Bool { doeEnabled ?? false }
    var isApexScriptEnabled: Bool { apexScriptEnabled ?? false }
}
