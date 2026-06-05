//
//  AppEnvironment.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 6 — App environment with managers
//

import SwiftUI

@MainActor
class AppEnvironment: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    // Core managers — shared across app
    // NOTE: TranslationManager is intentionally NOT instantiated in Phase 1.
    // Translation is a stub (throws) and is hidden from the shipping UI.
    // It will be wired in a later phase. The file remains on disk.
    let audioManager = AudioRecordingManager()
    let speechManager = SpeechTranscriptionManager()

    init() {
        // Auth state check will be added in Auth0 session
    }
}
