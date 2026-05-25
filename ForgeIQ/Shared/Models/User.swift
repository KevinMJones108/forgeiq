//
//  User.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 1 — Xcode project creation
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let auth0Sub: String
    let email: String
    let name: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case auth0Sub = "auth0_sub"
        case email
        case name
        case createdAt = "created_at"
    }
}
