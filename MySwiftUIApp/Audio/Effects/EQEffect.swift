import Foundation
import AVFoundation

// MARK: - 3バンドパラメトリックイコライザーエフェクト
/// ロー、ミッド、ハイの3バンドEQを提供するエフェクト
/// AVAudioUnitEQをラップし、各バンドのゲインと周波数を個別に制御可能
@MainActor
final class EQEffect: ObservableObject, AudioEffect {

    // MARK: - AudioEffectプロトコル準拠

    let effectType: EffectType = .eq
    var audioNode: AVAudioNode { eqNode }

    @Published var isEnabled: Bool = true {
        didSet { eqNode.bypass = !isEnabled }
    }

    // MARK: - EQパラメータ（各バンドのゲイン: -12〜+12 dB）

    @Published var lowGain: Float = 0.0 {
        didSet { updateBand(0, gain: lowGain) }
    }

    @Published var midGain: Float = 0.0 {
        didSet { updateBand(1, gain: midGain) }
    }

    @Published var highGain: Float = 0.0 {
        didSet { updateBand(2, gain: highGain) }
    }

    // MARK: - 各バンドの中心周波数

    @Published var lowFrequency: Float = 80.0 {
        didSet { updateBandFrequency(0, frequency: lowFrequency) }
    }

    @Published var midFrequency: Float = 1000.0 {
        didSet { updateBandFrequency(1, frequency: midFrequency) }
    }

    @Published var highFrequency: Float = 8000.0 {
        didSet { updateBandFrequency(2, frequency: highFrequency) }
    }

    // MARK: - 内部プロパティ

    private let eqNode: AVAudioUnitEQ

    // MARK: - 初期化

    init() {
        // 3バンドのパラメトリックEQを作成
        eqNode = AVAudioUnitEQ(numberOfBands: 3)
        configureBands()
    }

    // MARK: - バンド初期設定

    /// 各バンドの初期パラメータを設定
    private func configureBands() {
        guard eqNode.bands.count >= 3 else { return }

        // ローバンド（80Hz、パラメトリック）
        let lowBand = eqNode.bands[0]
        lowBand.filterType = .parametric
        lowBand.frequency = lowFrequency
        lowBand.bandwidth = 1.0
        lowBand.gain = lowGain
        lowBand.bypass = false

        // ミッドバンド（1kHz、パラメトリック）
        let midBand = eqNode.bands[1]
        midBand.filterType = .parametric
        midBand.frequency = midFrequency
        midBand.bandwidth = 1.0
        midBand.gain = midGain
        midBand.bypass = false

        // ハイバンド（8kHz、パラメトリック）
        let highBand = eqNode.bands[2]
        highBand.filterType = .parametric
        highBand.frequency = highFrequency
        highBand.bandwidth = 1.0
        highBand.gain = highGain
        highBand.bypass = false
    }

    // MARK: - パラメータ更新

    /// 指定バンドのゲインを更新
    private func updateBand(_ index: Int, gain: Float) {
        guard index < eqNode.bands.count else { return }
        // ゲインを-12〜+12 dBの範囲にクランプ
        eqNode.bands[index].gain = max(-12.0, min(12.0, gain))
    }

    /// 指定バンドの周波数を更新
    private func updateBandFrequency(_ index: Int, frequency: Float) {
        guard index < eqNode.bands.count else { return }
        eqNode.bands[index].frequency = frequency
    }

    // MARK: - リセット

    /// 全パラメータをデフォルト値にリセット
    func reset() {
        lowGain = 0.0
        midGain = 0.0
        highGain = 0.0
        lowFrequency = 80.0
        midFrequency = 1000.0
        highFrequency = 8000.0
        isEnabled = true
    }
}
