import SwiftUI
import Observation

// MARK: - Breath Phase

enum BreathPhase: String {
    case idle = "Ready"
    case inhale = "Breathe In"
    case holdIn = "Hold"
    case exhale = "Breathe Out"
    case holdOut = "Hold"

    var displayText: String { rawValue }

    var color: Color {
        switch self {
        case .idle: return LuminaTheme.textSecondary
        case .inhale: return Color(hex: 0x89F7FE)
        case .holdIn: return Color(hex: 0xA770EF)
        case .exhale: return Color(hex: 0xFDB99B)
        case .holdOut: return Color(hex: 0xCF8BF3)
        }
    }
}

// MARK: - Breath ViewModel

@Observable
final class BreathViewModel {
    var pattern: BreathPattern = .calm
    var phase: BreathPhase = .idle
    var isActive = false
    var orbScale: CGFloat = 0.6
    var cycleCount = 0
    var totalCycles = 5
    var phaseProgress: Double = 0
    var sessionElapsed: TimeInterval = 0

    private var timer: Timer?
    private var phaseTimer: Timer?
    private var phaseStartTime: Date?
    private var currentPhaseDuration: Double = 0

    var isComplete: Bool { cycleCount >= totalCycles }

    var phaseDisplayText: String {
        if phase == .holdIn || phase == .holdOut {
            return "Hold"
        }
        return phase.displayText
    }

    func start() {
        guard !isActive else { return }
        isActive = true
        cycleCount = 0
        sessionElapsed = 0
        beginCycle()

        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let start = self.phaseStartTime else { return }
            let elapsed = Date().timeIntervalSince(start)
            self.phaseProgress = min(elapsed / self.currentPhaseDuration, 1.0)
            self.sessionElapsed += 0.05
        }
    }

    func stop() {
        isActive = false
        phase = .idle
        phaseTimer?.invalidate()
        phaseTimer = nil
        timer?.invalidate()
        timer = nil
        withAnimation(LuminaTheme.gentleSpring) {
            orbScale = 0.6
        }
    }

    private func beginCycle() {
        guard isActive, cycleCount < totalCycles else {
            if cycleCount >= totalCycles {
                stop()
            }
            return
        }
        transition(to: .inhale)
    }

    private func transition(to newPhase: BreathPhase) {
        guard isActive else { return }

        let phases = pattern.phases
        let duration: Double

        switch newPhase {
        case .inhale:
            duration = phases.0
        case .holdIn:
            duration = phases.1
        case .exhale:
            duration = phases.2
        case .holdOut:
            duration = phases.3
        case .idle:
            stop()
            return
        }

        // Skip zero-duration phases
        if duration <= 0 {
            let next = nextPhase(after: newPhase)
            if next == .inhale {
                cycleCount += 1
            }
            if next == .idle || cycleCount >= totalCycles {
                stop()
                return
            }
            transition(to: next)
            return
        }

        phase = newPhase
        currentPhaseDuration = duration
        phaseStartTime = Date()
        phaseProgress = 0

        // Animate orb
        let targetScale: CGFloat
        switch newPhase {
        case .inhale: targetScale = 1.0
        case .holdIn: targetScale = 1.0
        case .exhale: targetScale = 0.6
        case .holdOut: targetScale = 0.6
        case .idle: targetScale = 0.6
        }

        withAnimation(.easeInOut(duration: duration)) {
            orbScale = targetScale
        }

        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self, self.isActive else { return }
            let next = self.nextPhase(after: newPhase)
            if next == .inhale {
                self.cycleCount += 1
            }
            if self.cycleCount >= self.totalCycles {
                self.stop()
                return
            }
            self.transition(to: next)
        }
    }

    private func nextPhase(after current: BreathPhase) -> BreathPhase {
        switch current {
        case .idle: return .inhale
        case .inhale: return .holdIn
        case .holdIn: return .exhale
        case .exhale: return .holdOut
        case .holdOut: return .inhale
        }
    }

    var formattedSessionTime: String {
        let minutes = Int(sessionElapsed) / 60
        let seconds = Int(sessionElapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var overallProgress: Double {
        guard totalCycles > 0 else { return 0 }
        let cycleProgress = Double(cycleCount) / Double(totalCycles)
        let currentCycleContribution = phaseProgress / Double(totalCycles) * 0.25
        return min(cycleProgress + currentCycleContribution, 1.0)
    }
}
