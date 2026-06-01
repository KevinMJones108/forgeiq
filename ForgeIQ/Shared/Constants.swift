//
//  Constants.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 1 — Xcode project creation
//

import SwiftUI

enum Constants {
    // MARK: - API Configuration

    #if DEBUG
    static let API_BASE_URL = "http://localhost:3001"
    #else
    static let API_BASE_URL = "https://forgeiq-974q.onrender.com"
    #endif

    // MARK: - Auth0 Configuration

    static let AUTH0_DOMAIN = "dev-yjrvxlswm4yk3zz7.auth0.com"
    static let AUTH0_CLIENT_ID = "xa9bJJdtJqWGIXRFbf9S0hzvHHUhzEBu"
    static let AUTH0_AUDIENCE = "https://forgeiq-974q.onrender.com"

    // MARK: - Brand Colors

    static let FORGEIQ_GREEN = Color(hex: "#00C853")
    static let FORGEIQ_NAVY = Color(hex: "#1F4E79")
    static let FORGEIQ_BLUE = Color(hex: "#2E75B6")
    static let FORGEIQ_FORGE = Color(hex: "#1C2B2B")
    static let FORGEIQ_MID_GREY = Color(hex: "#555555")
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
