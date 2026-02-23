import SwiftUI

struct BreatheView: View {
    @State private var vm = BreathViewModel()
    @Environment(DataStore.self) private var store

    var body: some View {
        ZStack {
            OrbBackground(
                color1: vm.phase.color,
                color2: LuminaTheme.accent
            )

            VStack(spacing: LuminaTheme.spacingXL) {
                // Header
                VStack(spacing: LuminaTheme.spacingXS) {
                    Text("Breathe")
                        .font(LuminaTheme.displayFont(32))
                        .foregroundStyle(.white)
                    Text(vm.isActive ? vm.formattedSessionTime : "Find your rhythm")
                        .font(LuminaTheme.bodyFont(15))
                        .foregroundStyle(LuminaTheme.textSecondary)
                }
                .padding(.top, LuminaTheme.spacingXL)

                Spacer()

                // Breathing Orb
                ZStack {
                    // Particle field
                    ParticleSystemView(
                        config: ParticleEmitterConfig(
                            emissionRate: vm.isActive ? 12 : 3,
                            particleLifeRange: 1.5...3.5,
                            speedRange: 15...45,
                            radiusRange: 1...3,
                            colors: [vm.phase.color.opacity(0.6), LuminaTheme.accent.opacity(0.4), .white.opacity(0.3)]
                        ),
                        center: CGPoint(x: UIScreen.main.bounds.width / 2, y: 150),
                        isEmitting: true
                    )
                    .frame(height: 300)
                    .allowsHitTesting(false)

                    // Main orb
                    FloatingOrb(
                        scale: vm.orbScale,
                        color1: vm.phase.color,
                        color2: LuminaTheme.accentSecondary
                    )

                    // Progress ring
                    if vm.isActive {
                        Circle()
                            .trim(from: 0, to: vm.overallProgress)
                            .stroke(
                                vm.phase.color.opacity(0.4),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(-90))
                    }
                }

                // Phase text
                Text(vm.isActive ? vm.phaseDisplayText : "")
                    .font(LuminaTheme.headingFont(24))
                    .foregroundStyle(vm.phase.color)
                    .animation(.easeInOut(duration: 0.5), value: vm.phase)
                    .frame(height: 30)

                // Cycle counter
                if vm.isActive {
                    HStack(spacing: LuminaTheme.spacingS) {
                        ForEach(0..<vm.totalCycles, id: \.self) { i in
                            Circle()
                                .fill(i < vm.cycleCount ? vm.phase.color : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                                .animation(.spring(response: 0.4), value: vm.cycleCount)
                        }
                    }
                }

                Spacer()

                // Pattern Selector (only when idle)
                if !vm.isActive {
                    patternSelector
                }

                // Controls
                controlsSection
                    .padding(.bottom, LuminaTheme.spacingXXL + 30)
            }
        }
    }

    // MARK: - Pattern Selector

    private var patternSelector: some View {
        VStack(spacing: LuminaTheme.spacingM) {
            Text("Pattern")
                .font(LuminaTheme.bodyFont(13))
                .foregroundStyle(LuminaTheme.textTertiary)

            HStack(spacing: LuminaTheme.spacingS) {
                ForEach(BreathPattern.allCases) { pattern in
                    Button {
                        withAnimation(LuminaTheme.snappySpring) {
                            vm.pattern = pattern
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(pattern.label)
                                .font(LuminaTheme.headingFont(13))
                            Text(formatPhases(pattern))
                                .font(LuminaTheme.monoFont(10))
                                .foregroundStyle(LuminaTheme.textTertiary)
                        }
                        .foregroundStyle(vm.pattern == pattern ? .white : LuminaTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(vm.pattern == pattern ? LuminaTheme.accent.opacity(0.3) : Color.white.opacity(0.06))
                                .overlay(
                                    Capsule()
                                        .stroke(vm.pattern == pattern ? LuminaTheme.accent.opacity(0.5) : .clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: LuminaTheme.spacingL) {
            if vm.isActive {
                LuminaButton(title: "Stop", icon: "stop.fill", color: Color(hex: 0xFF6B6B)) {
                    withAnimation(LuminaTheme.defaultSpring) {
                        vm.stop()
                    }
                }
            } else {
                LuminaButton(title: "Begin", icon: "wind", color: LuminaTheme.accent, isLarge: true) {
                    vm.start()
                }
            }
        }
    }

    private func formatPhases(_ pattern: BreathPattern) -> String {
        let p = pattern.phases
        let parts = [p.0, p.1, p.2, p.3].filter { $0 > 0 }
        return parts.map { String(Int($0)) }.joined(separator: "-")
    }
}

#Preview {
    BreatheView()
        .environment(DataStore())
}
