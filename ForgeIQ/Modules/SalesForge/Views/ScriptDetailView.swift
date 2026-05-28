//
//  ScriptDetailView.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 11 — Sales script library
//

import SwiftUI

struct ScriptDetailView: View {
    let script: Script
    @ObservedObject var viewModel: ScriptLibraryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color(hex: "1C2B2B").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(script.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        if let product = script.productName, !product.isEmpty {
                            Text(product)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Text("Created: \(script.createdAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // Select for next call button
                    Button(action: selectForNextCall) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Select for Next Call")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "00C853"))
                        .cornerRadius(12)
                    }

                    // Talking points
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Talking Points (\(script.talkingPoints.count))")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(Array(script.talkingPoints.enumerated()), id: \.offset) { index, point in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "00C853"))
                                    .frame(width: 24, alignment: .leading)

                                Text(point)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Script", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteScript(id: script.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(script.title)\"?")
        }
    }

    private func selectForNextCall() {
        viewModel.selectedScript = script
        // TODO: Navigate to HomeView or dismiss with notification
        dismiss()
    }
}
