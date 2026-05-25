//
//  FilesTabView.swift
//  ForgeIQ
//
//  Session 7 — Files Module: List of saved transcripts
//

import SwiftUI

struct FilesTabView: View {
    @StateObject private var viewModel = FilesViewModel()
    @State private var recordingToDelete: Recording?
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var itemsToShare: [Any] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.FORGEIQ_FORGE.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar

                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredRecordings.isEmpty {
                        emptyStateView
                    } else {
                        recordingsList
                    }
                }
            }
            .navigationTitle("Files")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete Recording", isPresented: $showingDeleteAlert, presenting: recordingToDelete) { recording in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteRecording(recording)
                }
            } message: { recording in
                Text("Are you sure you want to delete '\(recording.title)'? This action cannot be undone.")
            }
            .sheet(isPresented: $showingShareSheet) {
                ActivityViewController(activityItems: itemsToShare)
            }
            .onAppear {
                viewModel.loadRecordings()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Constants.FORGEIQ_MID_GREY)

            TextField("Search transcripts...", text: $viewModel.searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Constants.FORGEIQ_MID_GREY)
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Constants.FORGEIQ_GREEN)
                .scaleEffect(1.5)

            Text("Loading recordings...")
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.searchText.isEmpty ? "waveform.circle" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Constants.FORGEIQ_MID_GREY)

            Text(viewModel.searchText.isEmpty ? "No recordings yet" : "No results found")
                .font(.title2)
                .foregroundColor(.white)

            Text(viewModel.searchText.isEmpty ? "Start recording to create transcripts" : "Try a different search term")
                .foregroundColor(Constants.FORGEIQ_MID_GREY)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Recordings List

    private var recordingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredRecordings) { recording in
                    NavigationLink(destination: TranscriptDetailView(recording: recording)) {
                        RecordingCard(recording: recording)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            itemsToShare = viewModel.shareRecording(recording)
                            showingShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            recordingToDelete = recording
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Recording Card Component

struct RecordingCard: View {
    let recording: Recording

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(Constants.FORGEIQ_GREEN)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(recording.formattedDate)
                        .font(.caption)
                        .foregroundColor(Constants.FORGEIQ_MID_GREY)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(recording.formattedDuration)
                        .font(.caption)
                        .foregroundColor(Constants.FORGEIQ_GREEN)

                    if recording.transcript != nil {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(Constants.FORGEIQ_GREEN)
                            .font(.caption)
                    }
                }
            }

            if let transcript = recording.transcript {
                Text(transcript.originalText)
                    .font(.subheadline)
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
    }
}

// MARK: - Activity View Controller (Share Sheet)

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    FilesTabView()
}
