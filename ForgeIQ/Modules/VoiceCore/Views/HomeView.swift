//
//  HomeView.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 6 — Hero home screen single button UI
//

import SwiftUI

struct HomeView: View {
    // MARK: - State

    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var audioManager: AudioRecordingManager
    @EnvironmentObject var speechManager: SpeechTranscriptionManager

    @State private var showingShareSheet = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Constants.FORGEIQ_FORGE
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Main Button
                mainButton
                    .onTapGesture {
                        viewModel.handleButtonTap()
                    }

                // Waveform (only visible during recording)
                if viewModel.recordingState == .recording {
                    WaveformView(audioLevel: audioManager.audioLevel)
                        .frame(height: 60)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                }

                // Duration Counter (only visible during recording)
                if viewModel.recordingState == .recording {
                    Text(viewModel.durationString)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .transition(.opacity)
                }

                // Button Label
                Text(viewModel.buttonLabel)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                // Transcript View (only visible when complete)
                if viewModel.recordingState == .complete {
                    transcriptSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = viewModel.savedTranscriptURL {
                ActivityViewController(activityItems: [url])
            }
        }
        .onAppear {
            viewModel.setup(
                audioManager: audioManager,
                speechManager: speechManager
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.recordingState)
    }

    // MARK: - Main Button

    private var mainButton: some View {
        ZStack {
            // Outer ring for IDLE state (pulsing glow)
            if viewModel.recordingState == .idle {
                Circle()
                    .stroke(Constants.FORGEIQ_GREEN, lineWidth: 4)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)
            }

            // Outer ring for RECORDING state (solid red)
            if viewModel.recordingState == .recording {
                Circle()
                    .stroke(Color.red, lineWidth: 4)
                    .frame(width: 120, height: 120)
            }

            // Inner circle background
            Circle()
                .fill(Constants.FORGEIQ_FORGE.opacity(0.9))
                .frame(width: 110, height: 110)
                .overlay {
                    Circle()
                        .stroke(Constants.FORGEIQ_GREEN.opacity(0.3), lineWidth: 1)
                }

            // Button content
            buttonContent
        }
        .frame(width: 120, height: 120)
    }

    @ViewBuilder
    private var buttonContent: some View {
        switch viewModel.recordingState {
        case .idle:
            Image(systemName: "mic.fill")
                .font(.system(size: 40))
                .foregroundColor(Constants.FORGEIQ_GREEN)

        case .recording:
            Image(systemName: "stop.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)

        case .processing:
            processingSpinner

        case .complete:
            checkmarkAnimation
        }
    }

    // MARK: - Processing Spinner

    private var processingSpinner: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Constants.FORGEIQ_GREEN, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 40, height: 40)
            .rotationEffect(.degrees(spinnerRotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    spinnerRotation = 360
                }
            }
    }

    @State private var spinnerRotation: Double = 0

    // MARK: - Checkmark Animation

    private var checkmarkAnimation: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(Constants.FORGEIQ_GREEN)
            .scaleEffect(checkmarkScale)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    checkmarkScale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        checkmarkScale = 1.0
                    }
                }
            }
    }

    @State private var checkmarkScale: CGFloat = 0.8

    // MARK: - Pulsing Animation (IDLE state)

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6

    private var pulsingAnimation: Animation {
        Animation.easeInOut(duration: 1.4)
            .repeatForever(autoreverses: true)
    }

    // MARK: - Transcript Section

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Constants.FORGEIQ_GREEN)

            ScrollView {
                Text(viewModel.transcriptText)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .padding()
            .background(Constants.FORGEIQ_FORGE.opacity(0.5))
            .cornerRadius(12)

            // Share saved transcript (.txt)
            Button(action: {
                if viewModel.savedTranscriptURL != nil {
                    showingShareSheet = true
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Transcript")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Constants.FORGEIQ_GREEN)
                .cornerRadius(8)
            }
            .disabled(viewModel.savedTranscriptURL == nil)
            .opacity(viewModel.savedTranscriptURL == nil ? 0.5 : 1.0)

            // Saved confirmation + start over
            Text("Saved to Files")
                .font(.system(size: 12))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal)
    }

    // MARK: - Animation Modifiers

    private func startPulseAnimation() {
        withAnimation(pulsingAnimation) {
            pulseScale = 1.08
            pulseOpacity = 1.0
        }
    }
}

// Placeholder components removed - now in separate files

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(AudioRecordingManager())
        .environmentObject(SpeechTranscriptionManager())
}
