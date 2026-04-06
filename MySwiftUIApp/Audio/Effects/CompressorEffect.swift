import Foundation
import AVFoundation
import AudioToolbox

// MARK: - コンプレッサーエフェクト
/// ダイナミクスを制御するコンプレッサーエフェクト
/// iOS上ではAVAudioUnitEffectとAudioUnit C APIを使用して
/// DynamicsProcessorサブタイプでコンプレッションを実現する
@MainActor
final class CompressorEffect: ObservableObject, AudioEffect {

    // MARK: - AudioEffectプロトコル準拠

    let effectType: EffectType = .compressor
    var audioNode: AVAudioNode { compressorNode }

    @Published var isEnabled: Bool = true {
        didSet { compressorNode.bypass = !isEnabled }
    }

    // MARK: - コンプレッサーパラメータ

    /// スレッショルド（-40〜0 dB）
    @Published var threshold: Float = -20.0 {
        didSet { setParameter(0, value: threshold) }
    }

    /// ヘッドルーム（コンプレッションレシオに影響、0.1〜40 dB）
    /// ヘッドルームが小さいほど圧縮が強くなる
    @Published var headRoom: Float = 5.0 {
        didSet { setParameter(1, value: headRoom) }
    }

    /// アタックタイム（0.001〜0.2秒）
    @Published var attackTime: Float = 0.01 {
        didSet { setParameter(4, value: attackTime) }
    }

    /// リリースタイム（0.01〜3.0秒）
    @Published var releaseTime: Float = 0.1 {
        didSet { setParameter(5, value: releaseTime) }
    }

    /// マスターゲイン（-40〜40 dB）
    @Published var masterGain: Float = 0.0 {
        didSet { setParameter(6, value: masterGain) }
    }

    // MARK: - 内部プロパティ

    private let compressorNode: AVAudioUnitEffect

    // MARK: - 初期化

    init() {
        // DynamicsProcessorのAudioComponentDescriptionを生成
        let componentDescription = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_DynamicsProcessor,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        compressorNode = AVAudioUnitEffect(audioComponentDescription: componentDescription)

        // デフォルトパラメータを設定
        setParameter(0, value: -20.0)  // threshold
        setParameter(1, value: 5.0)    // headRoom
        setParameter(4, value: 0.01)   // attackTime
        setParameter(5, value: 0.1)    // releaseTime
        setParameter(6, value: 0.0)    // masterGain
    }

    // MARK: - パラメータ設定

    /// AudioUnit パラメータを設定する
    /// - Parameters:
    ///   - parameterID: パラメータID（DynamicsProcessor固有）
    ///   - value: 設定値
    private func setParameter(_ parameterID: AudioUnitParameterID, value: Float) {
        AudioUnitSetParameter(
            compressorNode.audioUnit,
            parameterID,
            kAudioUnitScope_Global,
            0,
            value,
            0
        )
    }

    // MARK: - リセット

    /// 全パラメータをデフォルト値にリセット
    func reset() {
        threshold = -20.0
        headRoom = 5.0
        attackTime = 0.01
        releaseTime = 0.1
        masterGain = 0.0
        isEnabled = true
    }
}
