import AVFoundation
import Accelerate
import Foundation

// MARK: - Protocol

protocol WaveformAnalyzerService {
    func generateWaveform(url: URL, samplesCount: Int) async throws -> [Float]
}

// MARK: - Implementation

struct AVWaveformAnalyzer: WaveformAnalyzerService {
    func generateWaveform(url: URL, samplesCount: Int) async throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        guard frameCount > 0 else { return [] }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return []
        }
        try file.read(into: buffer)

        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        let totalFrames = Int(buffer.frameLength)

        let samplesPerBucket = max(1, totalFrames / samplesCount)
        var waveform: [Float] = []
        waveform.reserveCapacity(samplesCount)

        for i in 0..<samplesCount {
            let start = i * samplesPerBucket
            let end = min(start + samplesPerBucket, totalFrames)
            guard start < totalFrames else { break }

            var maxVal: Float = 0
            for j in start..<end {
                maxVal = max(maxVal, abs(channelData[j]))
            }
            waveform.append(maxVal)
        }

        // Normalize to 0..1
        let peak = waveform.max() ?? 1.0
        guard peak > 0 else { return waveform }
        return waveform.map { $0 / peak }
    }
}
