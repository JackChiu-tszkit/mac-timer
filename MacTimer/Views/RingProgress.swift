import SwiftUI

struct RingProgress: View {
    var progress: Double
    var accent: Color
    var track: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityLabel("Remaining time")
        .accessibilityValue("\(Int((min(max(progress, 0), 1) * 100).rounded())) percent")
    }
}
