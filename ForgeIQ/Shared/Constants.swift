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
    static let API_BASE_URL = "https://forgeiq-api.onrender.com"
    #endif

    // MARK: - Auth0 Configuration

    static let AUTH0_DOMAIN = "dev-yjrvxlswm4yk3zz7.auth0.com"
    static let AUTH0_CLIENT_ID = "xa9bJJdtJqWGIXRFbf9S0hzvHHUhzEBu"
    static let AUTH0_AUDIENCE = "https://forgeiq-api.onrender.com"

    // MARK: - Brand Colors

    static let FORGEIQ_GREEN = Color(hex: "#00C853")
    static let FORGEIQ_NAVY = Color(hex: "#1F4E79")
    static let FORGEIQ_BLUE = Color(hex: "#2E75B6")
    static let FORGEIQ_FORGE = Color(hex: "#1C2B2B")
    static let FORGEIQ_MID_GREY = Color(hex: "#555555")
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double
        if hexString.count == 6 {
            red = Double((value >> 16) & 0xFF) / 255.0
            green = Double((value >> 8) & 0xFF) / 255.0
            blue = Double(value & 0xFF) / 255.0
        } else {
            red = 0
            green = 0
            blue = 0
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}
