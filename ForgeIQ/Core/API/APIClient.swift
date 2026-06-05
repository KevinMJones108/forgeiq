//
//  APIClient.swift
//  ForgeIQ
//
//  Thin URLSession client for the ForgeIQ Node.js backend.
//  Attaches the Auth0 JWT Bearer token from AuthTokenManager on every request
//  and decodes the standard { success, data, error } envelope.
//

import Foundation

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case notSignedIn            // 401 — no/invalid token
    case notConfigured          // 503 — backend missing ANTHROPIC_API_KEY
    case upstreamFailure        // 502 — analysis upstream (Anthropic) failed
    case badRequest(String)     // 400 — validation error from server
    case server(String)         // 500 / other non-2xx
    case decoding(String)       // response body could not be decoded
    case network(String)        // transport-level failure (offline, timeout)
    case unknown

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You're not signed in. Sign in to analyze calls."
        case .notConfigured:
            return "Call analysis isn't configured on the server yet."
        case .upstreamFailure:
            return "The analysis service is temporarily unavailable. Try again shortly."
        case .badRequest(let msg):
            return msg
        case .server(let msg):
            return msg
        case .decoding(let msg):
            return "Couldn't read the server response. \(msg)"
        case .network(let msg):
            return "Network error: \(msg)"
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}

// MARK: - API Envelope

private struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

// MARK: - API Client

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: String

    init(
        baseURL: String = Constants.API_BASE_URL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Public Endpoints

    /// POST /api/v1/calls/analyze — objection / blown-past detection.
    func analyzeTranscript(
        _ transcript: String,
        speakerLabels: [String]? = nil
    ) async throws -> CallAnalysis {
        var body: [String: Any] = ["transcript": transcript]
        if let speakerLabels, !speakerLabels.isEmpty {
            body["speakerLabels"] = speakerLabels
        }
        return try await post(path: "/api/v1/calls/analyze", body: body)
    }

    // MARK: - Core Request

    private func post<T: Decodable>(path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.server("Invalid URL: \(baseURL + path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Attach Auth0 Bearer token if present (Keychain via AuthTokenManager).
        if let token = AuthTokenManager.shared.getAccessToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            throw APIError.badRequest("Could not encode request body.")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        // Map status codes to typed errors before attempting to decode payload.
        switch http.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.notSignedIn
        case 503:
            throw APIError.notConfigured
        case 502:
            throw APIError.upstreamFailure
        case 400:
            throw APIError.badRequest(Self.serverMessage(from: data) ?? "Invalid request.")
        default:
            throw APIError.server(Self.serverMessage(from: data) ?? "Server error (\(http.statusCode)).")
        }

        // Decode the { success, data, error } envelope.
        let envelope: APIEnvelope<T>
        do {
            envelope = try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }

        guard envelope.success, let payload = envelope.data else {
            throw APIError.server(envelope.error ?? "Request failed.")
        }

        return payload
    }

    // MARK: - Helpers

    /// Best-effort extraction of the server's `error` string from an envelope.
    private static func serverMessage(from data: Data) -> String? {
        guard
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = obj["error"] as? String,
            !message.isEmpty
        else {
            return nil
        }
        return message
    }
}
