import AVFoundation
import Foundation

// MARK: - Protocol

protocol MetronomeService {
    var bpm: Int { get set }
    var timeSignature: TimeSignature { get set }
    var isPlaying: Bool { get }
    var currentBeat: Int { get }
    func start()
    func stop()
}

struct TimeSignature: Equatable {
    let beats: Int
    let noteValue: Int

    static let common = TimeSignature(beats: 4, noteValue: 4)
    static let waltz = TimeSignature(beats: 3, noteValue: 4)
    static let six8 = TimeSignature(beats: 6, noteValue: 8)

    var display: String { "\(beats)/\(noteValue)" }
}

// MARK: - Implementation

final class AudioEngineMetronome: MetronomeService {
    var bpm: Int = 120
    var timeSignature: TimeSignature = .common
    private(set) var isPlaying = false
    private(set) var currentBeat = 0

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var timer: DispatchSourceTimer?

    // Pre-rendered click buffers
    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?
    private let sampleRate: Double = 44100

    init() {
        generateClickBuffers()
    }

    func start() {
        guard !isPlaying else { return }
        do {
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)

            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            engine.connect(player, to: engine.mainMixerNode, format: format)

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try session.setActive(true)

            try engine.start()
            player.play()

            self.engine = engine
            self.playerNode = player
            isPlaying = true
            currentBeat = 0

            startTimer()
        } catch {
            print("Metronome start failed: \(error)")
        }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
        isPlaying = false
        currentBeat = 0
    }

    // MARK: - Timer

    private func startTimer() {
        let interval = 60.0 / Double(bpm)
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        timer.resume()
        self.timer = timer
    }

    private func tick() {
        currentBeat = (currentBeat % timeSignature.beats) + 1
        let buffer = (currentBeat == 1) ? accentBuffer : normalBuffer
        guard let buffer, let player = playerNode else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    // MARK: - Click Sound Generation

    private func generateClickBuffers() {
        accentBuffer = generateClick(frequency: 1200, duration: 0.03, amplitude: 0.8)
        normalBuffer = generateClick(frequency: 800, duration: 0.02, amplitude: 0.5)
    }

    private func generateClick(frequency: Double, duration: Double, amplitude: Float) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return nil }
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(1.0 - t / duration) // Linear decay
            data[i] = amplitude * envelope * sin(Float(2.0 * .pi * frequency * t))
        }
        return buffer
    }
}
