//
//  ScriptUploadView.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 11 — Sales script library
//

import SwiftUI

struct ScriptUploadView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ScriptLibraryViewModel

    @State private var title = ""
    @State private var productName = ""
    @State private var talkingPointsText = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C2B2B").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Script Title")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("e.g., EPDirectory Cold Call v1", text: $title)
                                .textFieldStyle(ForgeTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Product Name (optional)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("e.g., EPDirectory Pro", text: $productName)
                                .textFieldStyle(ForgeTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Talking Points (one per line)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextEditor(text: $talkingPointsText)
                                .frame(height: 200)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }

                        Button(action: saveScript) {
                            Text("Save Script")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "00C853"))
                                .cornerRadius(12)
                        }
                        .disabled(title.isEmpty || talkingPointsText.isEmpty)
                        .opacity(title.isEmpty || talkingPointsText.isEmpty ? 0.5 : 1.0)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Script")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "00C853"))
                }
            }
        }
    }

    private func saveScript() {
        let points = talkingPointsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        Task {
            await viewModel.createScript(
                title: title,
                productName: productName.isEmpty ? nil : productName,
                talkingPoints: points
            )
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}

struct ForgeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}
