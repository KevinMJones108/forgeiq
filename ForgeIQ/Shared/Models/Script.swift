//
//  Script.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 11 — Sales script library
//

import Foundation

struct Script: Codable, Identifiable {
    let id: UUID
    let userId: String
    let title: String
    let productName: String?
    let talkingPoints: [String]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case productName = "product_name"
        case talkingPoints = "talking_points"
        case createdAt = "created_at"
    }
}
