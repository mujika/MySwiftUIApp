import SwiftUI

struct SpectrogramView: View {
    let bins: [Float]
    let displayBins: Int

    init(bins: [Float], displayBins: Int = 128) {
        self.bins = bins
        self.displayBins = displayBins
    }

    var body: some View {
        Canvas { context, size in
            let reducedBins = reduceBins(bins, to: displayBins)
            let barWidth = size.width / CGFloat(reducedBins.count)

            for (i, value) in reducedBins.enumerated() {
                let x = CGFloat(i) * barWidth
                let barHeight = CGFloat(value) * size.height
                let rect = CGRect(
                    x: x,
                    y: size.height - barHeight,
                    width: max(barWidth - 0.5, 0.5),
                    height: barHeight
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 1),
                    with: .color(binColor(value: value))
                )
            }
        }
    }

    private func reduceBins(_ bins: [Float], to count: Int) -> [Float] {
        guard !bins.isEmpty else { return [Float](repeating: 0, count: count) }
        let step = max(1, bins.count / count)
        return stride(from: 0, to: min(bins.count, count * step), by: step).map { i in
            let end = min(i + step, bins.count)
            let slice = bins[i..<end]
            return slice.max() ?? 0
        }
    }

    private func binColor(value: Float) -> Color {
        if value < 0.25 { return .blue.opacity(Double(value) * 4) }
        if value < 0.5 { return .cyan }
        if value < 0.75 { return .green }
        return .yellow
    }
}
