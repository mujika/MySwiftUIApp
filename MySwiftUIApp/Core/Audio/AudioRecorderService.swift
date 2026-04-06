import AVFoundation
import Foundation

// MARK: - Protocol

protocol AudioRecorderService {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    var inputGain: Float { get set }
    var isMonitoringEnabled: Bool { get set }
    func requestPermission() async -> Bool
    func startRecording() throws -> URL
    func pauseRecording()
    func resumeRecording()
    func stopRecording() throws -> TimeInterval
}

// MARK: - Implementation

final class AVAudioRecorderService: AudioRecorderService {
    private var recorder: AVAudioRecorder?
    private var monitorEngine: AVAudioEngine?

    var isRecording: Bool { recorder?.isRecording ?? false }
    var isPaused: Bool { recorder != nil && !isRecording }

    var inputGain: Float = 1.0 {
        didSet {
            let session = AVAudioSession.sharedInstance()
            if session.isInputGainSettable {
                try? session.setInputGain(inputGain)
            }
        }
    }

    var isMonitoringEnabled: Bool = false {
        didSet {
            if isMonitoringEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() throws -> URL {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)

        if session.isInputGainSettable {
            try session.setInputGain(inputGain)
        }

        let url = Self.makeRecordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.record()
        return url
    }

    func pauseRecording() {
        recorder?.pause()
    }

    func resumeRecording() {
        recorder?.record()
    }

    func stopRecording() throws -> TimeInterval {
        guard let recorder else {
            throw AudioError.notRecording
        }
        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil

        stopMonitoring()

        let session = AVAudioSession.sharedInstance()
        try session.setActive(false, options: .notifyOthersOnDeactivation)

        return duration
    }

    // MARK: - Monitoring (hear yourself through speakers)

    private func startMonitoring() {
        guard monitorEngine == nil else { return }
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let output = engine.mainMixerNode
        let format = input.outputFormat(forBus: 0)
        engine.connect(input, to: output, format: format)
        do {
            try engine.start()
            monitorEngine = engine
        } catch {
            print("Monitor start failed: \(error)")
        }
    }

    private func stopMonitoring() {
        monitorEngine?.stop()
        monitorEngine = nil
    }

    private static func makeRecordingURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        return dir.appendingPathComponent("recording_\(timestamp).m4a")
    }
}

// MARK: - Errors

enum AudioError: LocalizedError {
    case notRecording
    case permissionDenied
    case recordingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notRecording:
            return "録音が開始されていません"
        case .permissionDenied:
            return "マイクの使用許可が必要です"
        case .recordingFailed(let error):
            return "録音に失敗しました: \(error.localizedDescription)"
        }
    }
}
