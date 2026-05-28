//
//  AuthTokenManager.swift
//  ForgeIQ
//
//  Manages Auth0 JWT tokens in Keychain
//

import Foundation
import Security

class AuthTokenManager {
    static let shared = AuthTokenManager()

    private let accessTokenKey = "forgeiq.accessToken"
    private let refreshTokenKey = "forgeiq.refreshToken"

    private init() {}

    // MARK: - Public Methods

    func saveAccessToken(_ token: String) {
        save(token, forKey: accessTokenKey)
    }

    func saveRefreshToken(_ token: String) {
        save(token, forKey: refreshTokenKey)
    }

    func getAccessToken() -> String? {
        return get(forKey: accessTokenKey)
    }

    func getRefreshToken() -> String? {
        return get(forKey: refreshTokenKey)
    }

    func clearTokens() {
        delete(forKey: accessTokenKey)
        delete(forKey: refreshTokenKey)
    }

    // MARK: - Keychain Helpers

    private func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete any existing item first
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Keychain save failed: \(status)")
        }
    }

    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
