//
//  ScriptLibraryViewModel.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 11 — Sales script library
//

import Foundation

@MainActor
class ScriptLibraryViewModel: ObservableObject {
    @Published var scripts: [Script] = []
    @Published var selectedScript: Script?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "https://forgeiq-api.onrender.com/api/v1"

    // Fetch all scripts
    func fetchScripts() async {
        isLoading = true
        errorMessage = nil

        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }

        guard let url = URL(string: "\(baseURL)/scripts") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ScriptsResponse.self, from: data)
            scripts = response.data.scripts
        } catch {
            errorMessage = "Failed to load scripts: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // Create script
    func createScript(title: String, productName: String?, talkingPoints: [String]) async {
        isLoading = true
        errorMessage = nil

        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }

        guard let url = URL(string: "\(baseURL)/scripts") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "title": title,
            "product_name": productName ?? "",
            "talking_points": talkingPoints
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ScriptCreateResponse.self, from: data)
            scripts.insert(response.data.script, at: 0)
        } catch {
            errorMessage = "Failed to create script: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // Delete script
    func deleteScript(id: UUID) async {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else { return }
        guard let url = URL(string: "\(baseURL)/scripts/\(id.uuidString)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, _) = try await URLSession.shared.data(for: request)
            scripts.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete script: \(error.localizedDescription)"
        }
    }
}

// Response models
struct ScriptsResponse: Codable {
    let success: Bool
    let data: ScriptsData
}

struct ScriptsData: Codable {
    let scripts: [Script]
}

struct ScriptCreateResponse: Codable {
    let success: Bool
    let data: ScriptData
}

struct ScriptData: Codable {
    let script: Script
}
