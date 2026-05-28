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
    let audioManager = AudioRecordingManager()
    let speechManager = SpeechTranscriptionManager()
    let translationManager = TranslationManager()

    init() {
        // Auth state check will be added in Auth0 session
    }
}
