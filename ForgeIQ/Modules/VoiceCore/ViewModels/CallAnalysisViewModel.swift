//
//  CallAnalysisViewModel.swift
//  ForgeIQ
//
//  Drives the sales-intel screen: POST a saved transcript to
//  /api/v1/calls/analyze and expose loading / result / error states.
//

import Foundation
import SwiftUI

@MainActor
final class CallAnalysisViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded(CallAnalysis)
        case failed(message: String, isAuth: Bool)
    }

    @Published private(set) var state: State = .idle

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Actions

    func analyze(transcript: String) async {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .failed(message: "There's no transcript text to analyze.", isAuth: false)
            return
        }

        state = .loading

        do {
            let analysis = try await apiClient.analyzeTranscript(trimmed)
            state = .loaded(analysis)
        } catch let error as APIError {
            let isAuth = (error == .notSignedIn)
            state = .failed(
                message: error.errorDescription ?? "Analysis failed.",
                isAuth: isAuth
            )
        } catch {
            state = .failed(message: error.localizedDescription, isAuth: false)
        }
    }

    func reset() {
        state = .idle
    }
}
