import Foundation
import Observation

@Observable
@MainActor
final class TunerViewModel {
    private let pitchDetector: PitchDetectorService
    private var timer: Timer?

    private(set) var isActive = false
    private(set) var frequency: Float = 0
    private(set) var currentNote: PitchDetectorNote?
    private(set) var closestString: GuitarString?
    private(set) var errorMessage: String?

    var centsOff: Float { currentNote?.centsOff ?? 0 }
    var isInTune: Bool { currentNote?.isInTune ?? false }

    init(pitchDetector: PitchDetectorService) {
        self.pitchDetector = pitchDetector
    }

    func toggle() {
        if isActive { stop() } else { start() }
    }

    func start() {
        do {
            try pitchDetector.start()
            isActive = true
            errorMessage = nil
            startPolling()
        } catch {
            errorMessage = "チューナーの起動に失敗しました"
        }
    }

    func stop() {
        pitchDetector.stop()
        isActive = false
        frequency = 0
        currentNote = nil
        closestString = nil
        stopPolling()
    }

    func dismissError() { errorMessage = nil }

    // MARK: - Private

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePitch()
            }
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func updatePitch() {
        frequency = pitchDetector.detectedFrequency
        currentNote = pitchDetector.detectedNote

        if frequency > 0 {
            closestString = GuitarString.allCases.min(by: {
                abs($0.frequency - frequency) < abs($1.frequency - frequency)
            })
        } else {
            closestString = nil
        }
    }
}
