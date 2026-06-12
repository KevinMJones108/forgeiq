//
//  AuthTokenManager.swift
//  ForgeIQ
//
//  Session 9 — Auth0 login flow + Keychain token storage
//  JWT is stored in the Keychain only — never UserDefaults.
//

import Foundation
import Security
#if canImport(Auth0)
import Auth0
#endif

enum AuthError: LocalizedError {
    case sdkMissing
    case loginFailed(String)

    var errorDescription: String? {
        switch self {
        case .sdkMissing:
            return "Auth0 SDK not installed. Add the Auth0.swift package in Xcode (File > Add Package Dependencies > https://github.com/auth0/Auth0.swift)."
        case .loginFailed(let message):
            return "Login failed: \(message)"
        }
    }
}

final class AuthTokenManager {
    // MARK: - Singleton

    static let shared = AuthTokenManager()
    private init() {}

    // MARK: - Keychain Configuration

    private let service = "ai.alviz.forgeiq"
    private let account = "auth0_access_token"

    // MARK: - Token Access

    var accessToken: String? {
        readToken()
    }

    var hasValidToken: Bool {
        accessToken != nil
    }

    func getAccessToken() -> String? {
        accessToken
    }

    // MARK: - Auth0 Login / Logout

    func login() async throws -> String {
        #if canImport(Auth0)
        do {
            let credentials = try await Auth0
                .webAuth(clientId: Constants.AUTH0_CLIENT_ID, domain: Constants.AUTH0_DOMAIN)
                .audience(Constants.AUTH0_AUDIENCE)
                .scope("openid profile email")
                .start()
            storeToken(credentials.accessToken)
            return credentials.accessToken
        } catch {
            throw AuthError.loginFailed(error.localizedDescription)
        }
        #else
        throw AuthError.sdkMissing
        #endif
    }

    func logout() async {
        #if canImport(Auth0)
        try? await Auth0
            .webAuth(clientId: Constants.AUTH0_CLIENT_ID, domain: Constants.AUTH0_DOMAIN)
            .clearSession()
        #endif
        clearToken()
    }

    // MARK: - Keychain Operations

    func storeToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func clearToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func readToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }
}
