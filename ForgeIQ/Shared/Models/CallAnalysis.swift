//
//  CallAnalysis.swift
//  ForgeIQ
//
//  Sales-intel: objection / "blown-past" analysis result returned by
//  POST /api/v1/calls/analyze. Shape mirrors objectionAnalysisService.js.
//

import Foundation

// MARK: - Objection

struct Objection: Codable, Hashable, Identifiable {
    // No id from backend — synthesize a stable one for SwiftUI lists.
    let id: UUID = UUID()

    let text: String
    let raisedBy: String
    let addressed: Bool
    let blewPast: Bool
    let severity: String // "low" | "med" | "high"
    let suggestedResponse: String

    // Backend never sends "id"; ignore it during decode.
    enum CodingKeys: String, CodingKey {
        case text, raisedBy, addressed, blewPast, severity, suggestedResponse
    }

    // MARK: - Display Helpers

    var severityLabel: String {
        switch severity.lowercased() {
        case "high": return "HIGH"
        case "med", "medium": return "MED"
        case "low": return "LOW"
        default: return severity.uppercased()
        }
    }

    var statusLabel: String {
        blewPast ? "BLEW PAST" : "ADDRESSED"
    }
}

// MARK: - Talk Ratio

struct TalkRatio: Codable, Hashable {
    let repPct: Double
    let prospectPct: Double
}

// MARK: - Call Analysis

struct CallAnalysis: Codable, Hashable {
    let objections: [Objection]
    let summary: String
    let talkRatio: TalkRatio?
    let model: String?

    var blewPastCount: Int {
        objections.filter { $0.blewPast }.count
    }

    var highSeverityCount: Int {
        objections.filter { $0.severity.lowercased() == "high" }.count
    }
}
