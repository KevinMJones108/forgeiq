//
//  Recording.swift
//  ForgeIQ
//
//  Session 7 — Files Module: Recording Model
//

import Foundation

struct Recording: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let audioURL: URL
    let duration: TimeInterval // In seconds
    let createdAt: Date
    let language: String // ISO 639-1 code (e.g., "en")
    var transcript: Transcript?

    // MARK: - Computed Properties

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var transcriptFileName: String {
        "\(id.uuidString).txt"
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        title: String,
        audioURL: URL,
        duration: TimeInterval,
        createdAt: Date = Date(),
        language: String,
        transcript: Transcript? = nil
    ) {
        self.id = id
        self.title = title
        self.audioURL = audioURL
        self.duration = duration
        self.createdAt = createdAt
        self.language = language
        self.transcript = transcript
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Recording, rhs: Recording) -> Bool {
        lhs.id == rhs.id
    }
}
