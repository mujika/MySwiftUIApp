import SwiftUI

// MARK: - Adaptive Gradient Background

struct GradientBackground: View {
    var colors: [Color]? = nil
    var animate: Bool = true

    @State private var animateGradient = false

    private var resolvedColors: [Color] {
        colors ?? LuminaTheme.adaptiveColors
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: resolvedColors,
                startPoint: animateGradient ? .topLeading : .topTrailing,
                endPoint: animateGradient ? .bottomTrailing : .bottomLeading
            )

            // Noise texture overlay
            Rectangle()
                .fill(LuminaTheme.background.opacity(0.5))

            // Radial accent
            RadialGradient(
                gradient: Gradient(colors: [
                    resolvedColors.first?.opacity(0.3) ?? .clear,
                    .clear
                ]),
                center: .topTrailing,
                startRadius: 50,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
        .onAppear {
            guard animate else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Orb Background

struct OrbBackground: View {
    let color1: Color
    let color2: Color
    var orbCount: Int = 3

    @State private var positions: [CGPoint] = []
    @State private var scales: [CGFloat] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LuminaTheme.background
                    .ignoresSafeArea()

                ForEach(0..<orbCount, id: \.self) { i in
                    let color = i % 2 == 0 ? color1 : color2
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.4), color.opacity(0.0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(scales.indices.contains(i) ? scales[i] : 1)
                        .position(positions.indices.contains(i) ? positions[i] : CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                        .blur(radius: 60)
                }
            }
            .onAppear {
                setupOrbs(in: geo.size)
                animateOrbs(in: geo.size)
            }
        }
        .ignoresSafeArea()
    }

    private func setupOrbs(in size: CGSize) {
        positions = (0..<orbCount).map { _ in
            CGPoint(
                x: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
                y: CGFloat.random(in: size.height * 0.1...size.height * 0.9)
            )
        }
        scales = (0..<orbCount).map { _ in CGFloat.random(in: 0.8...1.2) }
    }

    private func animateOrbs(in size: CGSize) {
        for i in 0..<orbCount {
            let duration = Double.random(in: 6...12)
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                positions[i] = CGPoint(
                    x: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
                    y: CGFloat.random(in: size.height * 0.1...size.height * 0.9)
                )
                scales[i] = CGFloat.random(in: 0.6...1.4)
            }
        }
    }
}
