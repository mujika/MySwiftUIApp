import AVFoundation
import Foundation

// MARK: - Effect Parameter Models

struct ReverbSettings: Equatable {
    var wetDryMix: Float = 30  // 0-100
    var preset: AVAudioUnitReverb.Preset = .mediumHall

    static let `default` = ReverbSettings()

    static let presets: [(name: String, preset: AVAudioUnitReverb.Preset)] = [
        ("Small Room", .smallRoom),
        ("Medium Room", .mediumRoom),
        ("Large Room", .largeRoom),
        ("Medium Hall", .mediumHall),
        ("Large Hall", .largeHall),
        ("Cathedral", .cathedral),
        ("Plate", .plate),
    ]
}

struct DelaySettings: Equatable {
    var wetDryMix: Float = 30       // 0-100
    var delayTime: TimeInterval = 0.3 // seconds
    var feedback: Float = 50         // 0-100

    static let `default` = DelaySettings()
}

struct EQSettings: Equatable {
    var lowGain: Float = 0    // -12..+12 dB
    var midGain: Float = 0
    var highGain: Float = 0

    static let `default` = EQSettings()
}

struct CompressorSettings: Equatable {
    var threshold: Float = -20   // dB
    var attackTime: Float = 0.01 // seconds
    var releaseTime: Float = 0.1
    var masterGain: Float = 0

    static let `default` = CompressorSettings()
}

struct DistortionSettings: Equatable {
    var wetDryMix: Float = 30
    var preGain: Float = -6      // -80..+20 dB

    static let `default` = DistortionSettings()
}

// MARK: - Protocol

protocol AudioEffectsService: AnyObject {
    var isActive: Bool { get }
    var reverbEnabled: Bool { get set }
    var delayEnabled: Bool { get set }
    var eqEnabled: Bool { get set }
    var compressorEnabled: Bool { get set }
    var distortionEnabled: Bool { get set }

    var reverbSettings: ReverbSettings { get set }
    var delaySettings: DelaySettings { get set }
    var eqSettings: EQSettings { get set }
    var compressorSettings: CompressorSettings { get set }
    var distortionSettings: DistortionSettings { get set }

    func processFile(inputURL: URL, outputURL: URL) async throws
}

// MARK: - Implementation

final class AVAudioEffectsProcessor: AudioEffectsService {
    var isActive: Bool {
        reverbEnabled || delayEnabled || eqEnabled || compressorEnabled || distortionEnabled
    }

    var reverbEnabled = false
    var delayEnabled = false
    var eqEnabled = false
    var compressorEnabled = false
    var distortionEnabled = false

    var reverbSettings = ReverbSettings.default
    var delaySettings = DelaySettings.default
    var eqSettings = EQSettings.default
    var compressorSettings = CompressorSettings.default
    var distortionSettings = DistortionSettings.default

    func processFile(inputURL: URL, outputURL: URL) async throws {
        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)

        let file = try AVAudioFile(forReading: inputURL)
        let format = file.processingFormat

        // Build effect chain
        var chain: [AVAudioNode] = [playerNode]

        if eqEnabled {
            let eq = AVAudioUnitEQ(numberOfBands: 3)
            configureBand(eq.bands[0], type: .lowShelf, freq: 200, gain: eqSettings.lowGain)
            configureBand(eq.bands[1], type: .parametric, freq: 1000, gain: eqSettings.midGain)
            configureBand(eq.bands[2], type: .highShelf, freq: 4000, gain: eqSettings.highGain)
            engine.attach(eq)
            chain.append(eq)
        }

        if compressorEnabled {
            let comp = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
                componentType: kAudioUnitType_Effect,
                componentSubType: kAudioUnitSubType_DynamicsProcessor,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0
            ))
            engine.attach(comp)
            chain.append(comp)
        }

        if distortionEnabled {
            let dist = AVAudioUnitDistortion()
            dist.wetDryMix = distortionSettings.wetDryMix
            dist.preGain = distortionSettings.preGain
            engine.attach(dist)
            chain.append(dist)
        }

        if delayEnabled {
            let delay = AVAudioUnitDelay()
            delay.wetDryMix = delaySettings.wetDryMix
            delay.delayTime = delaySettings.delayTime
            delay.feedback = delaySettings.feedback
            engine.attach(delay)
            chain.append(delay)
        }

        if reverbEnabled {
            let reverb = AVAudioUnitReverb()
            reverb.loadFactoryPreset(reverbSettings.preset)
            reverb.wetDryMix = reverbSettings.wetDryMix
            engine.attach(reverb)
            chain.append(reverb)
        }

        chain.append(engine.mainMixerNode)

        // Connect chain
        for i in 0..<chain.count - 1 {
            engine.connect(chain[i], to: chain[i + 1], format: format)
        }

        // Offline render
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: file.fileFormat.settings)

        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            try? outputFile.write(from: buffer)
        }

        try engine.start()
        playerNode.scheduleFile(file, at: nil)
        playerNode.play()

        // Wait for processing to complete
        let framesToProcess = file.length
        let sampleRate = format.sampleRate
        let durationSeconds = Double(framesToProcess) / sampleRate
        try await Task.sleep(for: .milliseconds(Int(durationSeconds * 1000) + 500))

        engine.mainMixerNode.removeTap(onBus: 0)
        playerNode.stop()
        engine.stop()
    }

    private func configureBand(_ band: AVAudioUnitEQFilterParameters, type: AVAudioUnitEQFilterType, freq: Float, gain: Float) {
        band.filterType = type
        band.frequency = freq
        band.gain = gain
        band.bypass = false
    }
}
