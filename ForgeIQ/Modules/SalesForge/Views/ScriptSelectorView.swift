//
//  ScriptSelectorView.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 11 — Sales script library
//

import SwiftUI

struct ScriptSelectorView: View {
    @ObservedObject var viewModel: ScriptLibraryViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C2B2B").ignoresSafeArea()

                List {
                    // No script option
                    Button(action: {
                        viewModel.selectedScript = nil
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.gray)
                            Text("No script (freestyle)")
                                .foregroundColor(.white)
                            Spacer()
                            if viewModel.selectedScript == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "00C853"))
                            }
                        }
                    }
                    .listRowBackground(Color(hex: "1C2B2B"))

                    // Available scripts
                    ForEach(viewModel.scripts) { script in
                        Button(action: {
                            viewModel.selectedScript = script
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(script.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    if let product = script.productName, !product.isEmpty {
                                        Text(product)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                if viewModel.selectedScript?.id == script.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "00C853"))
                                }
                            }
                        }
                        .listRowBackground(Color(hex: "1C2B2B"))
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Script")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "00C853"))
                }
            }
            .task {
                await viewModel.fetchScripts()
            }
        }
    }
}
