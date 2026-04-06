import Foundation
import AVFoundation

// MARK: - オーディオエフェクトプロトコル
/// 全エフェクトが準拠するプロトコル
/// AVAudioNodeのラッパーとして機能し、有効/無効の切り替えとリセットを提供
protocol AudioEffect: AnyObject {
    /// エフェクトの種類
    var effectType: EffectType { get }
    /// エフェクトの有効/無効状態
    var isEnabled: Bool { get set }
    /// 対応するAVAudioNode
    var audioNode: AVAudioNode { get }
    /// パラメータをデフォルト値にリセット
    func reset()
}

// MARK: - エフェクトタイプ定義

/// 利用可能なエフェクトの種類
enum EffectType: String, CaseIterable, Codable, Identifiable {
    case eq
    case compressor
    case distortion
    case delay
    case reverb
    case noiseGate

    var id: String { rawValue }

    /// 日本語表示名
    var displayName: String {
        switch self {
        case .eq: return "イコライザー"
        case .compressor: return "コンプレッサー"
        case .distortion: return "ディストーション"
        case .delay: return "ディレイ"
        case .reverb: return "リバーブ"
        case .noiseGate: return "ノイズゲート"
        }
    }

    /// SF Symbolsアイコン名
    var icon: String {
        switch self {
        case .eq: return "slider.horizontal.3"
        case .compressor: return "waveform.path"
        case .distortion: return "bolt.fill"
        case .delay: return "clock.arrow.2.circlepath"
        case .reverb: return "waveform.badge.magnifyingglass"
        case .noiseGate: return "speaker.slash.fill"
        }
    }
}

// MARK: - エフェクトプリセット

/// エフェクトチェーン全体のプリセット
enum EffectsPreset: String, CaseIterable, Identifiable {
    case clean
    case acoustic
    case crunch
    case highGain
    case ambient

    var id: String { rawValue }

    /// 日本語表示名
    var displayName: String {
        switch self {
        case .clean: return "クリーン"
        case .acoustic: return "アコースティック"
        case .crunch: return "クランチ"
        case .highGain: return "ハイゲイン"
        case .ambient: return "アンビエント"
        }
    }
}

// MARK: - エフェクトチェーン
/// オーディオエフェクトの直列接続を管理するクラス
/// エフェクトの順序変更、個別バイパス、チェーン全体の有効/無効を制御
/// 接続順: 入力 → EQ → コンプレッサー → ディストーション → ディレイ → リバーブ → ノイズゲート → 出力
@MainActor
final class EffectsChain: ObservableObject {

    // MARK: - 公開プロパティ

    /// エフェクトの処理順序
    @Published var effectOrder: [EffectType] = [.eq, .compressor, .distortion, .delay, .reverb, .noiseGate]

    /// チェーン全体の有効/無効
    @Published var isChainEnabled: Bool = true

    /// 現在のプリセット
    @Published var currentPreset: EffectsPreset = .clean

    // MARK: - エフェクトインスタンス

    let eqEffect: EQEffect
    let compressorEffect: CompressorEffect
    let distortionEffect: DistortionEffect
    let delayEffect: DelayEffect
    let reverbEffect: ReverbEffect
    let noiseGateEffect: NoiseGateEffect

    // MARK: - 内部プロパティ

    /// 入力用ミキサーノード（チェーンの入口）
    let inputMixer: AVAudioMixerNode

    /// 出力用ミキサーノード（チェーンの出口）
    let outputMixer: AVAudioMixerNode

    /// チェーンに登録されたエフェクトの配列
    private var effects: [AudioEffect] = []

    /// エフェクトが接続されたAVAudioEngineへの弱参照
    private weak var engine: AVAudioEngine?

    // MARK: - 初期化

    init() {
        inputMixer = AVAudioMixerNode()
        outputMixer = AVAudioMixerNode()

        eqEffect = EQEffect()
        compressorEffect = CompressorEffect()
        distortionEffect = DistortionEffect()
        delayEffect = DelayEffect()
        reverbEffect = ReverbEffect()
        noiseGateEffect = NoiseGateEffect()

        // デフォルトでは歪み系をオフにしておく
        distortionEffect.isEnabled = false
        delayEffect.isEnabled = false

        buildEffectsArray()
    }

    // MARK: - エフェクト配列構築

    /// effectOrderに基づいてエフェクト配列を構築
    private func buildEffectsArray() {
        effects = effectOrder.compactMap { type in
            switch type {
            case .eq: return eqEffect
            case .compressor: return compressorEffect
            case .distortion: return distortionEffect
            case .delay: return delayEffect
            case .reverb: return reverbEffect
            case .noiseGate: return noiseGateEffect
            }
        }
    }

    // MARK: - エンジンへの接続

    /// エフェクトチェーンの全ノードをAVAudioEngineに登録
    /// - Parameter engine: 対象のAVAudioEngine
    func attachToEngine(_ engine: AVAudioEngine) {
        self.engine = engine

        // ミキサーノードを追加
        engine.attach(inputMixer)
        engine.attach(outputMixer)

        // 各エフェクトノードを追加
        for effect in effects {
            engine.attach(effect.audioNode)
        }
    }

    /// エフェクトチェーンのノード接続を構築
    /// - Parameter format: オーディオフォーマット
    func rebuildChain(format: AVAudioFormat) {
        guard let engine = engine else { return }

        // 既存の接続を解除（安全に）
        disconnectAllNodes()

        buildEffectsArray()

        if !isChainEnabled {
            // チェーン全体が無効の場合、入力を直接出力に接続
            engine.connect(inputMixer, to: outputMixer, format: format)
            return
        }

        // 有効なエフェクトのみを収集
        let activeEffects = effects.filter { $0.isEnabled }

        if activeEffects.isEmpty {
            // 有効なエフェクトがない場合、バイパス
            engine.connect(inputMixer, to: outputMixer, format: format)
            return
        }

        // 入力ミキサー → 最初のエフェクト
        engine.connect(inputMixer, to: activeEffects[0].audioNode, format: format)

        // エフェクト間を直列接続
        for i in 0..<(activeEffects.count - 1) {
            engine.connect(activeEffects[i].audioNode, to: activeEffects[i + 1].audioNode, format: format)
        }

        // 最後のエフェクト → 出力ミキサー
        engine.connect(activeEffects[activeEffects.count - 1].audioNode, to: outputMixer, format: format)
    }

    // MARK: - ノード切断

    /// 全エフェクトノードの接続を解除
    private func disconnectAllNodes() {
        guard let engine = engine else { return }

        engine.disconnectNodeOutput(inputMixer)
        engine.disconnectNodeOutput(outputMixer)

        for effect in effects {
            engine.disconnectNodeOutput(effect.audioNode)
        }
    }

    // MARK: - 入出力ノード取得

    /// チェーンの入力ノードを取得
    func getInputNode() -> AVAudioNode {
        return inputMixer
    }

    /// チェーンの出力ノードを取得
    func getOutputNode() -> AVAudioNode {
        return outputMixer
    }

    // MARK: - プリセット適用

    /// 指定されたプリセットを全エフェクトに適用
    /// - Parameter preset: 適用するプリセット
    func applyPreset(_ preset: EffectsPreset) {
        currentPreset = preset

        switch preset {
        case .clean:
            // クリーン: EQとコンプのみ
            eqEffect.isEnabled = true
            eqEffect.lowGain = 0.0
            eqEffect.midGain = 0.0
            eqEffect.highGain = 2.0
            compressorEffect.isEnabled = true
            compressorEffect.threshold = -15.0
            compressorEffect.headRoom = 10.0
            distortionEffect.isEnabled = false
            delayEffect.isEnabled = false
            reverbEffect.isEnabled = true
            reverbEffect.wetDryMix = 15.0
            reverbEffect.reverbPreset = .smallRoom
            noiseGateEffect.isEnabled = true
            noiseGateEffect.threshold = -45.0

        case .acoustic:
            // アコースティック: 軽いEQとリバーブ
            eqEffect.isEnabled = true
            eqEffect.lowGain = 2.0
            eqEffect.midGain = -1.0
            eqEffect.highGain = 3.0
            compressorEffect.isEnabled = true
            compressorEffect.threshold = -20.0
            compressorEffect.headRoom = 8.0
            distortionEffect.isEnabled = false
            delayEffect.isEnabled = false
            reverbEffect.isEnabled = true
            reverbEffect.wetDryMix = 25.0
            reverbEffect.reverbPreset = .mediumHall
            noiseGateEffect.isEnabled = true
            noiseGateEffect.threshold = -45.0

        case .crunch:
            // クランチ: 軽い歪み
            eqEffect.isEnabled = true
            eqEffect.lowGain = 3.0
            eqEffect.midGain = 2.0
            eqEffect.highGain = 1.0
            compressorEffect.isEnabled = true
            compressorEffect.threshold = -18.0
            compressorEffect.headRoom = 6.0
            distortionEffect.isEnabled = true
            distortionEffect.distortionPreset = .crunch
            distortionEffect.wetDryMix = 40.0
            distortionEffect.preGain = -6.0
            delayEffect.isEnabled = false
            reverbEffect.isEnabled = true
            reverbEffect.wetDryMix = 20.0
            reverbEffect.reverbPreset = .smallRoom
            noiseGateEffect.isEnabled = true
            noiseGateEffect.threshold = -35.0

        case .highGain:
            // ハイゲイン: 強い歪み
            eqEffect.isEnabled = true
            eqEffect.lowGain = 4.0
            eqEffect.midGain = 5.0
            eqEffect.highGain = 2.0
            compressorEffect.isEnabled = true
            compressorEffect.threshold = -15.0
            compressorEffect.headRoom = 3.0
            distortionEffect.isEnabled = true
            distortionEffect.distortionPreset = .distortion
            distortionEffect.wetDryMix = 70.0
            distortionEffect.preGain = -3.0
            delayEffect.isEnabled = false
            reverbEffect.isEnabled = true
            reverbEffect.wetDryMix = 15.0
            reverbEffect.reverbPreset = .smallRoom
            noiseGateEffect.isEnabled = true
            noiseGateEffect.threshold = -30.0

        case .ambient:
            // アンビエント: ディレイとリバーブ強め
            eqEffect.isEnabled = true
            eqEffect.lowGain = -2.0
            eqEffect.midGain = 0.0
            eqEffect.highGain = 4.0
            compressorEffect.isEnabled = true
            compressorEffect.threshold = -20.0
            compressorEffect.headRoom = 8.0
            distortionEffect.isEnabled = false
            delayEffect.isEnabled = true
            delayEffect.delayTime = 0.4
            delayEffect.feedback = 45.0
            delayEffect.wetDryMix = 35.0
            reverbEffect.isEnabled = true
            reverbEffect.wetDryMix = 55.0
            reverbEffect.reverbPreset = .cathedral
            noiseGateEffect.isEnabled = true
            noiseGateEffect.threshold = -50.0
        }

        // チェーンが接続済みの場合、再構築
        if let engine = engine {
            let format = engine.inputNode.outputFormat(forBus: 0)
            rebuildChain(format: format)
        }
    }

    // MARK: - 全エフェクトリセット

    /// 全エフェクトをデフォルト値にリセット
    func resetAll() {
        for effect in effects {
            effect.reset()
        }
        effectOrder = [.eq, .compressor, .distortion, .delay, .reverb, .noiseGate]
        isChainEnabled = true
        currentPreset = .clean
    }

    // MARK: - エフェクト取得

    /// タイプからエフェクトインスタンスを取得
    /// - Parameter type: エフェクトタイプ
    /// - Returns: 対応するAudioEffect
    func effect(for type: EffectType) -> AudioEffect {
        switch type {
        case .eq: return eqEffect
        case .compressor: return compressorEffect
        case .distortion: return distortionEffect
        case .delay: return delayEffect
        case .reverb: return reverbEffect
        case .noiseGate: return noiseGateEffect
        }
    }
}
