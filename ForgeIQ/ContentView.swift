//
//  ContentView.swift
//  ForgeIQ
//
//  Created by Kevin Jones via Claude Code
//  Session 1 — Xcode project creation
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Constants.FORGEIQ_FORGE
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("ForgeIQ")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                Text("Session 1 — Xcode Project Created")
                    .font(.system(size: 16))
                    .foregroundColor(Constants.FORGEIQ_MID_GREY)

                Circle()
                    .fill(Constants.FORGEIQ_GREEN)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
