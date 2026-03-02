import AVFoundation
import Foundation

// MARK: - Protocol

protocol AudioLevelMonitor {
    var currentLevel: Float { get }
    func start() throws
    func stop()
}

// MARK: - Implementation

final class AVAudioLevelMonitor: AudioLevelMonitor {
    private var engine: AVAudioEngine?
    private(set) var currentLevel: Float = 0

    func start() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        engine.prepare()
        try engine.start()
        self.engine = engine
    }

    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        currentLevel = 0
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frameLength))
        let db = 20 * log10(max(rms, 1e-6))
        // Normalize: -60dB..0dB → 0..1
        let normalized = max(0, min(1, (db + 60) / 60))
        currentLevel = normalized
    }
}
