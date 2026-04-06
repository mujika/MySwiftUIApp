import AVFoundation
import Accelerate
import Foundation

// MARK: - Protocol

protocol PitchDetectorService {
    var detectedFrequency: Float { get }
    var detectedNote: PitchDetectorNote? { get }
    func start() throws
    func stop()
}

struct PitchDetectorNote: Equatable {
    let name: String
    let octave: Int
    let frequency: Float
    let centsOff: Float

    var displayName: String { "\(name)\(octave)" }
    var isInTune: Bool { abs(centsOff) < 5 }
}

// MARK: - Guitar Standard Tuning

enum GuitarString: Int, CaseIterable {
    case e2 = 6, a2 = 5, d3 = 4, g3 = 3, b3 = 2, e4 = 1

    var name: String {
        switch self {
        case .e2: return "E2"
        case .a2: return "A2"
        case .d3: return "D3"
        case .g3: return "G3"
        case .b3: return "B3"
        case .e4: return "E4"
        }
    }

    var frequency: Float {
        switch self {
        case .e2: return 82.41
        case .a2: return 110.00
        case .d3: return 146.83
        case .g3: return 196.00
        case .b3: return 246.94
        case .e4: return 329.63
        }
    }

    var stringNumber: Int { rawValue }
}

// MARK: - Implementation

final class FFTPitchDetector: PitchDetectorService {
    private var engine: AVAudioEngine?
    private let sampleRate: Float = 44100
    private let bufferSize: AVAudioFrameCount = 4096

    private(set) var detectedFrequency: Float = 0
    private(set) var detectedNote: PitchDetectorNote?

    private static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)!

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.analyzeBuffer(buffer)
        }

        engine.prepare()
        try engine.start()
        self.engine = engine
    }

    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        detectedFrequency = 0
        detectedNote = nil
    }

    // MARK: - FFT Analysis

    private func analyzeBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        let frequency = detectPitch(data: channelData, count: frameCount)
        guard frequency > 60 && frequency < 1200 else {
            detectedFrequency = 0
            detectedNote = nil
            return
        }

        detectedFrequency = frequency
        detectedNote = frequencyToNote(frequency)
    }

    private func detectPitch(data: UnsafePointer<Float>, count: Int) -> Float {
        // Autocorrelation-based pitch detection (more accurate for guitar than FFT peak)
        let minPeriod = Int(sampleRate / 1200) // max freq 1200Hz
        let maxPeriod = Int(sampleRate / 60)   // min freq 60Hz

        guard maxPeriod < count else { return 0 }

        var bestCorrelation: Float = 0
        var bestPeriod = 0

        for period in minPeriod...maxPeriod {
            var correlation: Float = 0
            var energy1: Float = 0
            var energy2: Float = 0

            let length = min(count - period, period * 2)
            for i in 0..<length {
                correlation += data[i] * data[i + period]
                energy1 += data[i] * data[i]
                energy2 += data[i + period] * data[i + period]
            }

            let denominator = sqrt(energy1 * energy2)
            guard denominator > 0 else { continue }

            let normalizedCorrelation = correlation / denominator

            if normalizedCorrelation > bestCorrelation {
                bestCorrelation = normalizedCorrelation
                bestPeriod = period
            }
        }

        guard bestCorrelation > 0.5, bestPeriod > 0 else { return 0 }

        return sampleRate / Float(bestPeriod)
    }

    private func frequencyToNote(_ frequency: Float) -> PitchDetectorNote {
        // MIDI note number: 69 = A4 = 440Hz
        let midiNote = 12 * log2(frequency / 440.0) + 69
        let roundedMidi = roundf(midiNote)
        let centsOff = (midiNote - roundedMidi) * 100

        let noteIndex = Int(roundedMidi) % 12
        let octave = Int(roundedMidi) / 12 - 1
        let noteName = Self.noteNames[(noteIndex + 12) % 12]
        let exactFreq = 440.0 * pow(2.0, (roundedMidi - 69) / 12.0)

        return PitchDetectorNote(
            name: noteName,
            octave: octave,
            frequency: exactFreq,
            centsOff: centsOff
        )
    }
}
