import Foundation
import Observation

@Observable
@MainActor
final class MetronomeViewModel {
    private var metronome: MetronomeService
    private var timer: Timer?

    private(set) var isPlaying = false
    private(set) var currentBeat = 0

    var bpm: Int {
        get { metronome.bpm }
        set { metronome.bpm = max(30, min(300, newValue)) }
    }

    var timeSignature: TimeSignature {
        get { metronome.timeSignature }
        set { metronome.timeSignature = newValue }
    }

    var beatsInBar: Int { timeSignature.beats }

    static let availableSignatures: [TimeSignature] = [
        .common, .waltz, .six8,
        TimeSignature(beats: 2, noteValue: 4),
        TimeSignature(beats: 5, noteValue: 4),
        TimeSignature(beats: 7, noteValue: 8),
    ]

    init(metronome: MetronomeService) {
        self.metronome = metronome
    }

    func toggle() {
        if isPlaying { stop() } else { start() }
    }

    func incrementBPM(by amount: Int = 1) {
        bpm += amount
    }

    func decrementBPM(by amount: Int = 1) {
        bpm -= amount
    }

    func tapTempo(tapTimes: inout [Date]) {
        let now = Date()
        tapTimes.append(now)
        if tapTimes.count > 4 { tapTimes.removeFirst() }
        guard tapTimes.count >= 2 else { return }

        let intervals = zip(tapTimes.dropFirst(), tapTimes).map { $0.timeIntervalSince($1) }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let tappedBPM = Int(60.0 / avgInterval)
        bpm = tappedBPM
    }

    // MARK: - Private

    private func start() {
        metronome.start()
        isPlaying = true
        startPolling()
    }

    private func stop() {
        metronome.stop()
        isPlaying = false
        currentBeat = 0
        stopPolling()
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentBeat = self.metronome.currentBeat
            }
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
}
