import SwiftUI

// MARK: - Animated Progress Ring

struct AnimatedRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: [Color]
    var size: CGFloat = 120
    var showGlow: Bool = true

    @State private var animatedProgress: Double = 0
    @State private var rotation: Double = -90

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(
                    Color.white.opacity(0.08),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradient + [gradient.first ?? .white]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation))

            // Glow at tip
            if showGlow && animatedProgress > 0.01 {
                Circle()
                    .fill(gradient.last ?? .white)
                    .frame(width: lineWidth * 1.5, height: lineWidth * 1.5)
                    .blur(radius: lineWidth * 0.5)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(rotation + 360 * animatedProgress))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Multi-Ring Display (Apple Watch Style)

struct MultiRingView: View {
    let rings: [(progress: Double, colors: [Color], label: String, icon: String)]
    var size: CGFloat = 160

    var body: some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.offset) { index, ring in
                let ringSize = size - CGFloat(index) * 40
                let lineWidth: CGFloat = 14

                AnimatedRing(
                    progress: ring.progress,
                    lineWidth: lineWidth,
                    gradient: ring.colors,
                    size: ringSize
                )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Circular Timer Ring

struct TimerRing: View {
    let progress: Double
    let timeString: String
    let subtitle: String
    let color: Color
    var size: CGFloat = 260

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(color.opacity(0.1), lineWidth: 30)
                .frame(width: size, height: size)
                .scaleEffect(pulseScale)

            // Track
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 8)
                .frame(width: size - 20, height: size - 20)

            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: size - 20, height: size - 20)
                .rotationEffect(.degrees(-90))

            // Orbital dot
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .shadow(color: color.opacity(0.6), radius: 6)
                .offset(y: -(size - 20) / 2)
                .rotationEffect(.degrees(-90 + 360 * progress))

            // Center content
            VStack(spacing: 4) {
                Text(timeString)
                    .font(LuminaTheme.monoFont(48))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(subtitle)
                    .font(LuminaTheme.bodyFont(14))
                    .foregroundStyle(LuminaTheme.textTertiary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.03
            }
        }
    }
}
