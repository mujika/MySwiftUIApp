import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    let progress: Double // 0..1
    let onSeek: ((Double) -> Void)?

    init(samples: [Float], progress: Double = 0, onSeek: ((Double) -> Void)? = nil) {
        self.samples = samples
        self.progress = progress
        self.onSeek = onSeek
    }

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let barWidth = size.width / CGFloat(max(samples.count, 1))
                let midY = size.height / 2

                for (i, sample) in samples.enumerated() {
                    let x = CGFloat(i) * barWidth
                    let barHeight = CGFloat(sample) * size.height * 0.9
                    let isPlayed = Double(i) / Double(max(samples.count - 1, 1)) <= progress

                    let rect = CGRect(
                        x: x,
                        y: midY - barHeight / 2,
                        width: max(barWidth - 0.5, 0.5),
                        height: max(barHeight, 1)
                    )

                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 1),
                        with: .color(isPlayed ? .blue : .gray.opacity(0.4))
                    )
                }

                // Playhead
                let playheadX = size.width * progress
                let playheadRect = CGRect(x: playheadX - 1, y: 0, width: 2, height: size.height)
                context.fill(Path(playheadRect), with: .color(.blue))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = Double(value.location.x / geo.size.width)
                        onSeek?(max(0, min(1, ratio)))
                    }
            )
        }
    }
}

#Preview {
    WaveformView(
        samples: (0..<100).map { _ in Float.random(in: 0.1...1.0) },
        progress: 0.4
    )
    .frame(height: 80)
    .padding()
}
