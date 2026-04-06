import Foundation
import Observation

@Observable
@MainActor
final class EffectsViewModel {
    private let effects: AudioEffectsService
    private let repository: RecordingRepository

    private(set) var isProcessing = false
    private(set) var errorMessage: String?

    // Reverb
    var reverbEnabled: Bool {
        get { effects.reverbEnabled }
        set { effects.reverbEnabled = newValue }
    }
    var reverbWetDry: Float {
        get { effects.reverbSettings.wetDryMix }
        set { effects.reverbSettings.wetDryMix = newValue }
    }
    var reverbPresetIndex: Int = 3 {
        didSet {
            let presets = ReverbSettings.presets
            if reverbPresetIndex < presets.count {
                effects.reverbSettings.preset = presets[reverbPresetIndex].preset
            }
        }
    }

    // Delay
    var delayEnabled: Bool {
        get { effects.delayEnabled }
        set { effects.delayEnabled = newValue }
    }
    var delayWetDry: Float {
        get { effects.delaySettings.wetDryMix }
        set { effects.delaySettings.wetDryMix = newValue }
    }
    var delayTime: Float {
        get { Float(effects.delaySettings.delayTime) }
        set { effects.delaySettings.delayTime = TimeInterval(newValue) }
    }
    var delayFeedback: Float {
        get { effects.delaySettings.feedback }
        set { effects.delaySettings.feedback = newValue }
    }

    // EQ
    var eqEnabled: Bool {
        get { effects.eqEnabled }
        set { effects.eqEnabled = newValue }
    }
    var eqLow: Float {
        get { effects.eqSettings.lowGain }
        set { effects.eqSettings.lowGain = newValue }
    }
    var eqMid: Float {
        get { effects.eqSettings.midGain }
        set { effects.eqSettings.midGain = newValue }
    }
    var eqHigh: Float {
        get { effects.eqSettings.highGain }
        set { effects.eqSettings.highGain = newValue }
    }

    // Compressor
    var compressorEnabled: Bool {
        get { effects.compressorEnabled }
        set { effects.compressorEnabled = newValue }
    }
    var compThreshold: Float {
        get { effects.compressorSettings.threshold }
        set { effects.compressorSettings.threshold = newValue }
    }

    // Distortion
    var distortionEnabled: Bool {
        get { effects.distortionEnabled }
        set { effects.distortionEnabled = newValue }
    }
    var distortionWetDry: Float {
        get { effects.distortionSettings.wetDryMix }
        set { effects.distortionSettings.wetDryMix = newValue }
    }
    var distortionPreGain: Float {
        get { effects.distortionSettings.preGain }
        set { effects.distortionSettings.preGain = newValue }
    }

    var hasActiveEffects: Bool { effects.isActive }

    init(effects: AudioEffectsService, repository: RecordingRepository) {
        self.effects = effects
        self.repository = repository
    }

    func applyEffects(to recording: Recording) async {
        isProcessing = true
        errorMessage = nil

        let outputURL = recording.url.deletingLastPathComponent()
            .appendingPathComponent("fx_\(Int(Date().timeIntervalSince1970)).m4a")

        do {
            try await effects.processFile(inputURL: recording.url, outputURL: outputURL)
            isProcessing = false
        } catch {
            errorMessage = "エフェクト適用に失敗しました"
            isProcessing = false
        }
    }

    func resetAll() {
        reverbEnabled = false
        delayEnabled = false
        eqEnabled = false
        compressorEnabled = false
        distortionEnabled = false
        effects.reverbSettings = .default
        effects.delaySettings = .default
        effects.eqSettings = .default
        effects.compressorSettings = .default
        effects.distortionSettings = .default
    }

    func dismissError() { errorMessage = nil }
}
