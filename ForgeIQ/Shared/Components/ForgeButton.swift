//
//  ForgeButton.swift
//  ForgeIQ
//
//  Shared component — primary ForgeGreen button with haptics + spring press
//

import SwiftUI

struct ForgeButton: View {
    // MARK: - Properties

    let title: String
    var systemImage: String?
    var isLoading: Bool = false
    let action: () -> Void

    @State private var isPressed = false
    private let haptics = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Body

    var body: some View {
        Button(action: {
            haptics.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Constants.FORGEIQ_GREEN)
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Constants.FORGEIQ_FORGE.ignoresSafeArea()
        VStack(spacing: 16) {
            ForgeButton(title: "Sign In", systemImage: "person.fill") {}
            ForgeButton(title: "Loading", isLoading: true) {}
        }
        .padding()
    }
}
