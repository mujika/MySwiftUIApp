import AVFoundation
import Foundation

// MARK: - Protocol

protocol MultiTrackMixerService: AnyObject {
    var isPlaying: Bool { get }
    var isRecording: Bool { get }
    func loadTracks(_ tracks: [Track]) throws
    func updateTrack(_ track: Track)
    func play()
    func stop()
    func startOverdub() throws -> URL
    func stopOverdub() -> TimeInterval
    func mixdown(tracks: [Track], to outputURL: URL) async throws
}

// MARK: - Implementation

final class AVMultiTrackMixer: MultiTrackMixerService {
    private var engine: AVAudioEngine?
    private var playerNodes: [UUID: AVAudioPlayerNode] = [:]
    private var audioFiles: [UUID: AVAudioFile] = [:]
    private var recorder: AVAudioRecorder?
    private var overdubURL: URL?

    private(set) var isPlaying = false
    private(set) var isRecording = false

    func loadTracks(_ tracks: [Track]) throws {
        stop()

        let engine = AVAudioEngine()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        for track in tracks {
            let file = try AVAudioFile(forReading: track.url)
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)

            player.volume = track.isMuted ? 0 : track.volume
            player.pan = track.pan

            playerNodes[track.id] = player
            audioFiles[track.id] = file
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)

        try engine.start()
        self.engine = engine
    }

    func updateTrack(_ track: Track) {
        guard let player = playerNodes[track.id] else { return }
        let hasSolo = playerNodes.keys.contains { _ in false } // Check later with actual solo state
        player.volume = track.isMuted ? 0 : track.volume
        player.pan = track.pan
    }

    func play() {
        guard let engine, engine.isRunning else { return }

        for (id, player) in playerNodes {
            if let file = audioFiles[id] {
                player.scheduleFile(file, at: nil)
                player.play()
            }
        }
        isPlaying = true
    }

    func stop() {
        for player in playerNodes.values {
            player.stop()
        }
        engine?.stop()
        engine = nil
        playerNodes.removeAll()
        audioFiles.removeAll()
        isPlaying = false
    }

    func startOverdub() throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("overdub_\(Int(Date().timeIntervalSince1970)).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        overdubURL = url
        isRecording = true

        // Also play existing tracks
        play()

        return url
    }

    func stopOverdub() -> TimeInterval {
        let duration = recorder?.currentTime ?? 0
        recorder?.stop()
        recorder = nil
        isRecording = false
        stop()
        return duration
    }

    func mixdown(tracks: [Track], to outputURL: URL) async throws {
        let engine = AVAudioEngine()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        var players: [(AVAudioPlayerNode, AVAudioFile)] = []

        for track in tracks where !track.isMuted {
            let file = try AVAudioFile(forReading: track.url)
            let player = AVAudioPlayerNode()
            engine.attach(player)

            let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
            engine.connect(player, to: engine.mainMixerNode, format: monoFormat)
            player.volume = track.volume
            player.pan = track.pan

            players.append((player, file))
        }

        let outputFile = try AVAudioFile(forWriting: outputURL, settings: [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ])

        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            try? outputFile.write(from: buffer)
        }

        try engine.start()

        var maxDuration: Double = 0
        for (player, file) in players {
            player.scheduleFile(file, at: nil)
            player.play()
            let dur = Double(file.length) / file.processingFormat.sampleRate
            maxDuration = max(maxDuration, dur)
        }

        try await Task.sleep(for: .milliseconds(Int(maxDuration * 1000) + 500))

        engine.mainMixerNode.removeTap(onBus: 0)
        for (player, _) in players { player.stop() }
        engine.stop()
    }
}
