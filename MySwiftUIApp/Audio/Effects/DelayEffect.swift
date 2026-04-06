import Foundation
import AVFoundation

// MARK: - ディレイエフェクト
/// 音声を遅延させて繰り返すディレイエフェクト
/// AVAudioUnitDelayをラップし、ディレイタイム、フィードバック、ミックスを制御
@MainActor
final class DelayEffect: ObservableObject, AudioEffect {

    // MARK: - AudioEffectプロトコル準拠

    let effectType: EffectType = .delay
    var audioNode: AVAudioNode { delayNode }

    @Published var isEnabled: Bool = true {
        didSet { delayNode.bypass = !isEnabled }
    }

    // MARK: - ディレイパラメータ

    /// ディレイタイム（0.01〜2.0秒）
    @Published var delayTime: TimeInterval = 0.3 {
        didSet { delayNode.delayTime = delayTime }
    }

    /// フィードバック量（-100〜100%）
    @Published var feedback: Float = 30.0 {
        didSet { delayNode.feedback = feedback }
    }

    /// ウェット/ドライミックス（0〜100）
    @Published var wetDryMix: Float = 25.0 {
        didSet { delayNode.wetDryMix = wetDryMix }
    }

    /// ローパスカットオフ周波数（10〜(sampleRate/2) Hz）
    @Published var lowPassCutoff: Float = 15000.0 {
        didSet { delayNode.lowPassCutoff = lowPassCutoff }
    }

    // MARK: - 内部プロパティ

    private let delayNode: AVAudioUnitDelay

    // MARK: - 初期化

    init() {
        delayNode = AVAudioUnitDelay()
        delayNode.delayTime = 0.3
        delayNode.feedback = 30.0
        delayNode.wetDryMix = 25.0
        delayNode.lowPassCutoff = 15000.0
    }

    // MARK: - リセット

    /// 全パラメータをデフォルト値にリセット
    func reset() {
        delayTime = 0.3
        feedback = 30.0
        wetDryMix = 25.0
        lowPassCutoff = 15000.0
        isEnabled = true
    }
}
