import SwiftUI

// MARK: - Breathing Orb

struct FloatingOrb: View {
    let scale: CGFloat
    let color1: Color
    let color2: Color
    var innerGlow: Bool = true

    @State private var innerPulse: CGFloat = 0.8

    var body: some View {
        ZStack {
            // Outermost glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color1.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(scale * 1.2)
                .blur(radius: 20)

            // Middle ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color2.opacity(0.35), color1.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .scaleEffect(scale)
                .blur(radius: 8)

            // Core orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.9),
                            color1.opacity(0.8),
                            color2.opacity(0.6),
                            color2.opacity(0.2)
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(scale * 0.9)
                .blur(radius: 2)

            // Inner sparkle
            if innerGlow {
                Circle()
                    .fill(.white.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .scaleEffect(innerPulse * scale)
                    .blur(radius: 10)
            }

            // Specular highlight
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 50, height: 30)
                .offset(y: -25 * scale)
                .scaleEffect(scale * 0.8)
                .blur(radius: 3)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                innerPulse = 1.2
            }
        }
    }
}

// MARK: - Orbital Rings

struct OrbitalRingsView: View {
    let progress: Double
    let color: Color
    var ringCount: Int = 3

    var body: some View {
        ZStack {
            ForEach(0..<ringCount, id: \.self) { i in
                OrbitalRing(
                    progress: progress,
                    color: color.opacity(Double(ringCount - i) / Double(ringCount) * 0.3),
                    rotationOffset: Double(i) * 60,
                    tilt: Double(i) * 15 + 60,
                    dotCount: 3 + i
                )
            }
        }
    }
}

struct OrbitalRing: View {
    let progress: Double
    let color: Color
    let rotationOffset: Double
    let tilt: Double
    let dotCount: Int

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Ring path
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 1)
                .frame(width: 200, height: 200)

            // Orbital dots
            ForEach(0..<dotCount, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .offset(y: -100)
                    .rotationEffect(.degrees(Double(i) * (360 / Double(dotCount)) + rotation))
                    .opacity(progress)
            }
        }
        .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0.3, z: 0))
        .rotationEffect(.degrees(rotationOffset))
        .onAppear {
            withAnimation(.linear(duration: 10 + Double(dotCount)).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
