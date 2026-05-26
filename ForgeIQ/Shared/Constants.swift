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

// Color extension removed - declared elsewhere
    }
}
