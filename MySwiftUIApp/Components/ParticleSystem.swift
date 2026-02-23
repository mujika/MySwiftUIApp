import SwiftUI

// MARK: - Particle

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var radius: CGFloat
    var opacity: Double
    var color: Color
    var life: Double
    var maxLife: Double

    var isAlive: Bool { life > 0 }

    mutating func update(deltaTime: Double) {
        position.x += velocity.dx * deltaTime
        position.y += velocity.dy * deltaTime
        life -= deltaTime
        opacity = max(0, life / maxLife)
        radius = max(0.5, radius * (1 - deltaTime * 0.3))
    }
}

// MARK: - Particle Emitter Configuration

struct ParticleEmitterConfig {
    var emissionRate: Double = 8
    var particleLifeRange: ClosedRange<Double> = 2...4
    var speedRange: ClosedRange<Double> = 20...60
    var radiusRange: ClosedRange<CGFloat> = 1.5...4
    var colors: [Color] = [LuminaTheme.accent, LuminaTheme.accentSecondary, LuminaTheme.accentTertiary]
    var spreadAngle: Double = .pi * 2
    var baseAngle: Double = -.pi / 2
    var gravity: CGVector = .zero
}

// MARK: - Particle System View (Canvas-based for performance)

struct ParticleSystemView: View {
    let config: ParticleEmitterConfig
    let center: CGPoint
    let isEmitting: Bool

    @State private var particles: [Particle] = []
    @State private var lastUpdate: Date = .now
    @State private var emissionAccumulator: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Draw all living particles
                for particle in particles where particle.isAlive {
                    let rect = CGRect(
                        x: particle.position.x - particle.radius,
                        y: particle.position.y - particle.radius,
                        width: particle.radius * 2,
                        height: particle.radius * 2
                    )
                    context.opacity = particle.opacity * 0.8
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particle.color)
                    )
                    // Glow effect
                    let glowRect = rect.insetBy(dx: -particle.radius, dy: -particle.radius)
                    context.opacity = particle.opacity * 0.2
                    context.fill(
                        Circle().path(in: glowRect),
                        with: .color(particle.color)
                    )
                }
            }
            .onChange(of: timeline.date) { _, now in
                let dt = min(now.timeIntervalSince(lastUpdate), 0.05)
                lastUpdate = now
                stepSimulation(deltaTime: dt)
            }
        }
    }

    private func stepSimulation(deltaTime: Double) {
        // Update existing particles
        for i in particles.indices {
            particles[i].update(deltaTime: deltaTime)
            particles[i].velocity.dx += config.gravity.dx * deltaTime
            particles[i].velocity.dy += config.gravity.dy * deltaTime
        }

        // Remove dead particles
        particles.removeAll { !$0.isAlive }

        // Emit new particles
        guard isEmitting else { return }
        emissionAccumulator += config.emissionRate * deltaTime
        let toEmit = Int(emissionAccumulator)
        emissionAccumulator -= Double(toEmit)

        for _ in 0..<toEmit {
            let angle = config.baseAngle + Double.random(in: -config.spreadAngle/2...config.spreadAngle/2)
            let speed = Double.random(in: config.speedRange)
            let life = Double.random(in: config.particleLifeRange)
            let radius = CGFloat.random(in: config.radiusRange)
            let color = config.colors.randomElement() ?? .white

            particles.append(Particle(
                position: center,
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                radius: radius,
                opacity: 1.0,
                color: color,
                life: life,
                maxLife: life
            ))
        }

        // Cap particle count
        if particles.count > 200 {
            particles.removeFirst(particles.count - 200)
        }
    }
}

// MARK: - Ambient Floating Particles

struct AmbientParticlesView: View {
    let particleCount: Int
    let colors: [Color]

    @State private var offsets: [CGSize] = []
    @State private var opacities: [Double] = []
    @State private var scales: [Double] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { i in
                    Circle()
                        .fill(colors[i % colors.count])
                        .frame(width: CGFloat.random(in: 2...6), height: CGFloat.random(in: 2...6))
                        .offset(offsets.indices.contains(i) ? offsets[i] : .zero)
                        .opacity(opacities.indices.contains(i) ? opacities[i] : 0)
                        .scaleEffect(scales.indices.contains(i) ? scales[i] : 1)
                }
            }
            .onAppear {
                setupParticles(in: geo.size)
                animateParticles(in: geo.size)
            }
        }
    }

    private func setupParticles(in size: CGSize) {
        offsets = (0..<particleCount).map { _ in
            CGSize(
                width: CGFloat.random(in: -size.width/2...size.width/2),
                height: CGFloat.random(in: -size.height/2...size.height/2)
            )
        }
        opacities = (0..<particleCount).map { _ in Double.random(in: 0.1...0.4) }
        scales = (0..<particleCount).map { _ in Double.random(in: 0.5...1.5) }
    }

    private func animateParticles(in size: CGSize) {
        for i in 0..<particleCount {
            let duration = Double.random(in: 4...8)
            let delay = Double.random(in: 0...3)
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay)) {
                offsets[i] = CGSize(
                    width: CGFloat.random(in: -size.width/2...size.width/2),
                    height: CGFloat.random(in: -size.height/2...size.height/2)
                )
                opacities[i] = Double.random(in: 0.1...0.5)
                scales[i] = Double.random(in: 0.8...2.0)
            }
        }
    }
}
