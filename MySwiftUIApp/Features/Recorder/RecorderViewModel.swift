import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class RecorderViewModel {
    // MARK: - Dependencies

    private let recorder: AudioRecorderService
    private let levelMonitor: AudioLevelMonitor
    private let repository: RecordingRepository

    // MARK: - State

    private(set) var isRecording = false
    private(set) var hasPermission = false
    private(set) var audioLevel: Float = 0
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var error: AudioError?

    private var recordingURL: URL?
    private var timer: Timer?

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Init

    init(
        recorder: AudioRecorderService,
        levelMonitor: AudioLevelMonitor,
        repository: RecordingRepository
    ) {
        self.recorder = recorder
        self.levelMonitor = levelMonitor
        self.repository = repository
    }

    // MARK: - Actions

    func requestPermission() async {
        hasPermission = await recorder.requestPermission()
        if !hasPermission {
            error = .permissionDenied
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func dismissError() {
        error = nil
    }

    // MARK: - Private

    private func startRecording() {
        do {
            recordingURL = try recorder.startRecording()
            try levelMonitor.start()
            isRecording = true
            recordingDuration = 0
            error = nil
            startTimer()
        } catch {
            self.error = .recordingFailed(underlying: error)
        }
    }

    private func stopRecording() {
        do {
            _ = try recorder.stopRecording()
            levelMonitor.stop()
            isRecording = false
            audioLevel = 0
            stopTimer()
            recordingURL = nil
        } catch {
            self.error = .recordingFailed(underlying: error)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isRecording else { return }
                self.recordingDuration += 0.1
                self.audioLevel = self.levelMonitor.currentLevel
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
