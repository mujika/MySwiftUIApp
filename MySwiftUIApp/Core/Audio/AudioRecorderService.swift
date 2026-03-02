import AVFoundation
import Foundation

// MARK: - Protocol

protocol AudioRecorderService {
    var isRecording: Bool { get }
    func requestPermission() async -> Bool
    func startRecording() throws -> URL
    func stopRecording() throws -> TimeInterval
}

// MARK: - Implementation

final class AVAudioRecorderService: AudioRecorderService {
    private var recorder: AVAudioRecorder?
    private var recordingStartTime: Date?

    var isRecording: Bool {
        recorder?.isRecording ?? false
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
        recordingStartTime = Date()
        return url
    }

    func stopRecording() throws -> TimeInterval {
        guard let recorder else {
            throw AudioError.notRecording
        }
        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        recordingStartTime = nil

        let session = AVAudioSession.sharedInstance()
        try session.setActive(false, options: .notifyOthersOnDeactivation)

        return duration
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
