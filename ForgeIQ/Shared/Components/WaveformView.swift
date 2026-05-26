import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    private let barCount = 12
    private let minHeight: CGFloat = 4
    private let maxHeight: CGFloat = 60

    var body: some View {
        TimelineView(.animation) { timeline in
            HStack(spacing: 4) {
                ForEach(0..<barCount, id: \.self) { index in
                    BarView(
                        height: calculateBarHeight(for: index),
                        color: Color(hex: "#00C853") // ForgeGreen
                    )
                }
            }
        }
    }

    private func calculateBarHeight(for index: Int) -> CGFloat {
        if audioLevel < 0.01 {
            return minHeight
        }

        // Create variation across bars for visual interest
        // Center bars respond more, edge bars less
        let centerOffset = abs(Float(index) - Float(barCount) / 2.0)
        let centerWeight = 1.0 - (centerOffset / Float(barCount / 2)) * 0.5

        // Add slight variation based on bar position
        let variation = sin(Float(index) * 0.5) * 0.2 + 1.0

        // Calculate final height
        let scaledLevel = CGFloat(audioLevel * centerWeight * variation)
        let targetHeight = minHeight + (maxHeight - minHeight) * scaledLevel

        return max(minHeight, min(maxHeight, targetHeight))
    }
}

struct BarView: View {
    let height: CGFloat
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 6, height: height)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: height)
    }
}

// Color extension removed - declared in Constants.swift

// MARK: - Preview

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            VStack {
                Text("Silent (0.0)")
                    .foregroundColor(.white)
                WaveformView(audioLevel: 0.0)
            }

            VStack {
                Text("Low (0.3)")
                    .foregroundColor(.white)
                WaveformView(audioLevel: 0.3)
            }

            VStack {
                Text("Medium (0.6)")
                    .foregroundColor(.white)
                WaveformView(audioLevel: 0.6)
            }

            VStack {
                Text("High (1.0)")
                    .foregroundColor(.white)
                WaveformView(audioLevel: 1.0)
            }
        }
        .padding()
        .background(Color(hex: "#1C2B2B"))
    }
}
