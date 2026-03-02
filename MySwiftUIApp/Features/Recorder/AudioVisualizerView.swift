import SwiftUI

struct AudioVisualizerView: View {
    let level: Float
    private let barCount = 20

    var body: some View {
        VStack(spacing: 16) {
            barsView
            levelBar
        }
        .padding()
    }

    // MARK: - Subviews

    private var barsView: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
        .frame(height: 100)
    }

    private var levelBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 4)
                    .fill(levelColor)
                    .frame(width: geometry.size.width * CGFloat(level))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Helpers

    private func barHeight(for index: Int) -> CGFloat {
        let threshold = Float(index) / Float(barCount)
        let base: CGFloat = 4
        guard level > threshold else { return base }
        return max(base, 100 * CGFloat(level) * CGFloat.random(in: 0.6...1.0))
    }

    private func barColor(for index: Int) -> Color {
        let ratio = Double(index) / Double(barCount - 1)
        if ratio < 0.33 { return .blue }
        if ratio < 0.66 { return .green }
        return .orange
    }

    private var levelColor: Color {
        if level < 0.5 { return .green }
        if level < 0.8 { return .yellow }
        return .red
    }
}

#Preview {
    AudioVisualizerView(level: 0.6)
}
