//
//  APIClient.swift
//  ForgeIQ
//
//  Session 9/10 — URLSession client with Auth0 bearer headers
//  All requests hit the Node.js backend; envelope is { success, data, error }.
//

import Foundation

enum APIError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case serverError(String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not signed in. Please log in and try again."
        case .invalidURL:
            return "Invalid API URL."
        case .serverError(let message):
            return message
        case .decodingFailed:
            return "Unexpected response from server."
        }
    }
}

// MARK: - Response Envelope

private struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

final class APIClient {
    // MARK: - Singleton

    static let shared = APIClient()
    private init() {}

    private let session = URLSession.shared

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoderContext in
            let container = try decoderContext.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = formatter.date(from: string) ?? fallback.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return decoder
    }()

    // MARK: - Core Request

    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let token = AuthTokenManager.shared.accessToken else {
            throw APIError.notAuthenticated
        }
        guard let url = URL(string: "\(Constants.API_BASE_URL)\(path)") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("No HTTP response")
        }

        let envelope: APIEnvelope<T>
        do {
            envelope = try decoder.decode(APIEnvelope<T>.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }

        guard (200...299).contains(httpResponse.statusCode), envelope.success else {
            throw APIError.serverError(envelope.error ?? "Request failed (\(httpResponse.statusCode))")
        }
        guard let payload = envelope.data else {
            throw APIError.decodingFailed
        }
        return payload
    }

    // MARK: - Auth

    struct SyncResponse: Decodable {
        let user: User
    }

    @discardableResult
    func syncUser(email: String, name: String?) async throws -> User {
        let response: SyncResponse = try await request(
            "/api/v1/auth/sync",
            method: "POST",
            body: ["email": email, "name": name ?? ""]
        )
        return response.user
    }

    struct MeResponse: Decodable {
        let user: UserProfile
    }

    func getMe() async throws -> UserProfile {
        let response: MeResponse = try await request("/api/v1/auth/me")
        return response.user
    }

    // MARK: - Voice

    struct RemoteRecording: Decodable {
        let id: UUID
        let title: String
    }

    private struct CreateRecordingResponse: Decodable {
        let recording: RemoteRecording
    }

    func createRecording(title: String, durationSec: Int) async throws -> RemoteRecording {
        let response: CreateRecordingResponse = try await request(
            "/api/v1/voice/recordings",
            method: "POST",
            body: ["title": title, "audio_duration_sec": durationSec]
        )
        return response.recording
    }

    private struct SaveTranscriptResponse: Decodable {
        struct SavedTranscript: Decodable {
            let id: UUID
        }
        let transcript: SavedTranscript
    }

    @discardableResult
    func saveTranscript(
        recordingId: UUID,
        text: String,
        sourceLanguage: String,
        translatedText: String?,
        targetLanguage: String?
    ) async throws -> UUID {
        let response: SaveTranscriptResponse = try await request(
            "/api/v1/voice/transcripts",
            method: "POST",
            body: [
                "recording_id": recordingId.uuidString.lowercased(),
                "transcript_text": text,
                "source_language": sourceLanguage,
                "translated_text": translatedText as Any,
                "target_language": targetLanguage as Any
            ]
        )
        return response.transcript.id
    }

    // MARK: - AI Call Summary (Session 10)

    private struct CallSummaryResponse: Decodable {
        let callSummary: CallSummary

        enum CodingKeys: String, CodingKey {
            case callSummary = "call_summary"
        }
    }

    func generateCallSummary(recordingId: UUID?, transcript: String) async throws -> CallSummary {
        var body: [String: Any] = ["transcript": transcript]
        if let recordingId {
            body["recording_id"] = recordingId.uuidString.lowercased()
        }
        let response: CallSummaryResponse = try await request(
            "/api/v1/ai/call-summary",
            method: "POST",
            body: body
        )
        return response.callSummary
    }

    private struct RepStatsResponse: Decodable {
        let stats: RepStats
    }

    func getRepStats() async throws -> RepStats {
        let response: RepStatsResponse = try await request("/api/v1/ai/rep-stats")
        return response.stats
    }

    // MARK: - CRM (Session 10)

    struct LogCallResult: Decodable {
        let logged: Bool
        let tasksCreated: Int
        let reEngagementTask: Bool

        enum CodingKeys: String, CodingKey {
            case logged
            case tasksCreated = "tasks_created"
            case reEngagementTask = "re_engagement_task"
        }
    }

    func logCall(callSummaryId: UUID, contactName: String, duration: String?) async throws -> LogCallResult {
        try await request(
            "/api/v1/crm/log-call",
            method: "POST",
            body: [
                "call_summary_id": callSummaryId.uuidString.lowercased(),
                "contact_name": contactName,
                "duration": duration as Any
            ]
        )
    }
}
