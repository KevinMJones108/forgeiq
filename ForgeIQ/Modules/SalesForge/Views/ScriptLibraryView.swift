//
//  ScriptLibraryView.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 11 — Sales script library
//

import SwiftUI

struct ScriptLibraryView: View {
    @StateObject private var viewModel = ScriptLibraryViewModel()
    @State private var showUpload = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C2B2B").ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "00C853")))
                            .padding()
                    } else if viewModel.scripts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No scripts yet")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Create your first sales script")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(viewModel.scripts) { script in
                                NavigationLink(destination: ScriptDetailView(script: script, viewModel: viewModel)) {
                                    ScriptRowView(script: script)
                                }
                                .listRowBackground(Color(hex: "1C2B2B"))
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Scripts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showUpload = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "00C853"))
                    }
                }
            }
            .sheet(isPresented: $showUpload) {
                ScriptUploadView(viewModel: viewModel)
            }
            .task {
                await viewModel.fetchScripts()
            }
        }
    }
}

struct ScriptRowView: View {
    let script: Script

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(script.title)
                .font(.headline)
                .foregroundColor(.white)
            if let product = script.productName, !product.isEmpty {
                Text(product)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text("\(script.talkingPoints.count) talking points")
                .font(.caption2)
                .foregroundColor(Color(hex: "00C853"))
        }
        .padding(.vertical, 4)
    }
}
