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
    private let spectrogram: SpectrogramService
    private let motionControl: MotionControlService

    // MARK: - State

    private(set) var isRecording = false
    private(set) var isPaused = false
    private(set) var hasPermission = false
    private(set) var audioLevel: Float = 0
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var error: AudioError?

    // Spectrogram
    private(set) var frequencyBins: [Float] = []
    var isSpectrogramVisible = true

    // Motion
    private(set) var motionPitch: Double = 0
    private(set) var motionRoll: Double = 0
    private(set) var isMotionActive = false

    var isMotionAvailable: Bool { motionControl.isAvailable }

    var isMonitoring: Bool {
        get { recorder.isMonitoringEnabled }
        set { recorder.isMonitoringEnabled = newValue }
    }

    var inputGain: Float {
        get { recorder.inputGain }
        set { recorder.inputGain = newValue }
    }

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
        repository: RecordingRepository,
        spectrogram: SpectrogramService,
        motionControl: MotionControlService
    ) {
        self.recorder = recorder
        self.levelMonitor = levelMonitor
        self.repository = repository
        self.spectrogram = spectrogram
        self.motionControl = motionControl

        motionControl.onShake = { [weak self] in
            Task { @MainActor [weak self] in
                self?.toggleRecording()
            }
        }
    }

    // MARK: - Actions

    func requestPermission() async {
        hasPermission = await recorder.requestPermission()
        if !hasPermission {
            error = .permissionDenied
        }
    }

    func toggleRecording() {
        if isRecording || isPaused {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func togglePause() {
        if isPaused { resumeRecording() } else { pauseRecording() }
    }

    func toggleMotion() {
        if isMotionActive {
            motionControl.stop()
            isMotionActive = false
        } else {
            motionControl.start()
            isMotionActive = true
        }
    }

    func dismissError() { error = nil }

    // MARK: - Private

    private func startRecording() {
        do {
            recordingURL = try recorder.startRecording()
            try levelMonitor.start()
            try spectrogram.start()
            isRecording = true
            isPaused = false
            recordingDuration = 0
            error = nil
            startTimer()
        } catch {
            self.error = .recordingFailed(underlying: error)
        }
    }

    private func pauseRecording() {
        recorder.pauseRecording()
        isPaused = true
        isRecording = false
        stopTimer()
    }

    private func resumeRecording() {
        recorder.resumeRecording()
        isPaused = false
        isRecording = true
        startTimer()
    }

    private func stopRecording() {
        do {
            _ = try recorder.stopRecording()
            levelMonitor.stop()
            spectrogram.stop()
            isRecording = false
            isPaused = false
            audioLevel = 0
            frequencyBins = []
            stopTimer()
            recordingURL = nil
        } catch {
            self.error = .recordingFailed(underlying: error)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isRecording else { return }
                self.recordingDuration += 0.05
                self.audioLevel = self.levelMonitor.currentLevel
                self.frequencyBins = self.spectrogram.frequencyBins
                if self.isMotionActive {
                    self.motionPitch = self.motionControl.pitch
                    self.motionRoll = self.motionControl.roll
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
