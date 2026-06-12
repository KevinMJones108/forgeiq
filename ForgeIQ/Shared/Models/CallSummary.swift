//
//  CallSummary.swift
//  ForgeIQ
//
//  Session 10 — AI Call Summary + Blown Past Detector models
//

import Foundation

struct CallSummary: Codable, Identifiable {
    let id: UUID
    let recordingId: UUID?
    let summary: String
    let wentWell: [String]
    let learningPoints: [String]
    let blownPast: [BlownPastSignal]
    let commitments: [Commitment]
    let nextStep: String?
    let callScore: Int?
    let talkTimeRepPct: Int?
    let talkTimeProspectPct: Int?
    let reEngagementCandidate: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case recordingId = "recording_id"
        case summary
        case wentWell = "went_well"
        case learningPoints = "learning_points"
        case blownPast = "blown_past"
        case commitments
        case nextStep = "next_step"
        case callScore = "call_score"
        case talkTimeRepPct = "talk_time_rep_pct"
        case talkTimeProspectPct = "talk_time_prospect_pct"
        case reEngagementCandidate = "re_engagement_candidate"
    }

    var highSignalCount: Int {
        blownPast.filter { $0.severity == .high }.count
    }
}

// MARK: - Blown Past Signal

struct BlownPastSignal: Codable, Identifiable, Hashable {
    let timestamp: String
    let prospectSaid: String
    let signalType: String
    let signalDescription: String
    let whatHappened: String
    let suggestedResponse: String

    var id: String { "\(timestamp)-\(prospectSaid)" }

    enum CodingKeys: String, CodingKey {
        case timestamp
        case prospectSaid = "prospect_said"
        case signalType = "signal_type"
        case signalDescription = "signal_description"
        case whatHappened = "what_happened"
        case suggestedResponse = "suggested_response"
    }

    enum Severity: String {
        case high = "HIGH"
        case med = "MED"
        case low = "LOW"
    }

    var severity: Severity {
        Severity(rawValue: signalType.uppercased()) ?? .low
    }
}

// MARK: - Commitment

struct Commitment: Codable, Identifiable, Hashable {
    let owner: String
    let text: String
    let due: String

    var id: String { "\(owner)-\(text)" }
}

// MARK: - Rep Stats (dashboard)

struct RepStats: Codable {
    let totalCalls: Int
    let avgCallScore: Double?
    let avgTalkTimeRepPct: Int?
    let reEngagementCount: Int

    enum CodingKeys: String, CodingKey {
        case totalCalls = "total_calls"
        case avgCallScore = "avg_call_score"
        case avgTalkTimeRepPct = "avg_talk_time_rep_pct"
        case reEngagementCount = "re_engagement_count"
    }
}
