import SwiftUI
import Observation

// MARK: - Focus Timer State

enum TimerState: Equatable {
    case idle
    case running
    case paused
    case breakTime
    case completed
}

// MARK: - Focus ViewModel

@Observable
final class FocusViewModel {
    var category: FocusCategory = .work
    var totalSeconds: Int = 25 * 60
    var remainingSeconds: Int = 25 * 60
    var focusState: TimerState = .idle
    var sessionsCompleted: Int = 0
    var breakSeconds: Int = 5 * 60
    var breakRemaining: Int = 5 * 60

    private var timer: Timer?
    private var startDate: Date?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }

    var breakProgress: Double {
        guard breakSeconds > 0 else { return 0 }
        return 1.0 - Double(breakRemaining) / Double(breakSeconds)
    }

    var timeString: String {
        let t = focusState == .breakTime ? breakRemaining : remainingSeconds
        let minutes = t / 60
        let seconds = t % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var subtitle: String {
        switch focusState {
        case .idle: return "Tap to begin"
        case .running: return category.label
        case .paused: return "Paused"
        case .breakTime: return "Take a break"
        case .completed: return "Well done!"
        }
    }

    var displayColor: Color {
        focusState == .breakTime ? Color(hex: 0x5FD068) : category.color
    }

    func selectCategory(_ cat: FocusCategory) {
        guard focusState == .idle else { return }
        category = cat
        totalSeconds = cat.defaultMinutes * 60
        remainingSeconds = totalSeconds
    }

    func start() {
        focusState = .running
        startDate = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        focusState = .paused
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        start()
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        focusState = .idle
        remainingSeconds = totalSeconds
        breakRemaining = breakSeconds
    }

    func togglePlayPause() {
        switch focusState {
        case .idle:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        case .breakTime:
            skipBreak()
        case .completed:
            reset()
        }
    }

    private func tick() {
        if focusState == .breakTime {
            if breakRemaining > 0 {
                breakRemaining -= 1
            } else {
                finishBreak()
            }
            return
        }

        guard focusState == .running else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            finishSession()
        }
    }

    private func finishSession() {
        sessionsCompleted += 1
        focusState = .breakTime
        breakRemaining = breakSeconds
    }

    func skipBreak() {
        timer?.invalidate()
        timer = nil
        focusState = .completed
    }

    private func finishBreak() {
        timer?.invalidate()
        timer = nil
        focusState = .completed
    }

    func createSession() -> FocusSession {
        FocusSession(
            category: category,
            durationMinutes: totalSeconds / 60,
            wasCompleted: remainingSeconds == 0
        )
    }

    func setDuration(minutes: Int) {
        guard focusState == .idle else { return }
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
    }
}
