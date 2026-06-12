//
//  ForgeIQApp.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 1 — Xcode project creation
//  Session 9 — auth gate + shared manager injection
//

import SwiftUI

@main
struct ForgeIQApp: App {
    @StateObject private var appEnvironment = AppEnvironment()
    @StateObject private var audioManager = AudioRecordingManager()
    @StateObject private var speechManager = SpeechTranscriptionManager()
    @StateObject private var translationManager = TranslationManager()
    @StateObject private var ttsManager = ElevenLabsTTSManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appEnvironment)
                .environmentObject(audioManager)
                .environmentObject(speechManager)
                .environmentObject(translationManager)
                .environmentObject(ttsManager)
                .preferredColorScheme(.dark)
        }
    }
}
