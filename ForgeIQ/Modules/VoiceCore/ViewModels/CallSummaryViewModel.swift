//
//  CallSummaryViewModel.swift
//  ForgeIQ
//
//  Session 10 — generates AI Call Summary and logs to Pipedrive
//

import Foundation
import SwiftUI

@MainActor
class CallSummaryViewModel: ObservableObject {
    // MARK: - Published State

    @Published var callSummary: CallSummary?
    @Published var isGenerating = false
    @Published var isLoggingToCRM = false
    @Published var crmLogMessage: String?
    @Published var errorMessage: String?

    private let haptics = UINotificationFeedbackGenerator()

    // MARK: - Generate Summary

    func generateSummary(recordingId: UUID?, transcript: String) async {
        guard !transcript.isEmpty else {
            errorMessage = "No transcript to analyse"
            return
        }

        isGenerating = true
        errorMessage = nil

        do {
            callSummary = try await APIClient.shared.generateCallSummary(
                recordingId: recordingId,
                transcript: transcript
            )
            haptics.notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            haptics.notificationOccurred(.error)
        }

        isGenerating = false
    }

    // MARK: - Pipedrive Auto-Log

    func logToPipedrive(contactName: String, duration: String?) async {
        guard let callSummary else {
            errorMessage = "Generate a summary first"
            return
        }

        isLoggingToCRM = true
        crmLogMessage = nil
        errorMessage = nil

        do {
            let result = try await APIClient.shared.logCall(
                callSummaryId: callSummary.id,
                contactName: contactName,
                duration: duration
            )
            var message = "Logged to Pipedrive — \(result.tasksCreated) follow-up task(s) created"
            if result.reEngagementTask {
                message += " + re-engagement task at day +7"
            }
            crmLogMessage = message
            haptics.notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            haptics.notificationOccurred(.error)
        }

        isLoggingToCRM = false
    }
}
