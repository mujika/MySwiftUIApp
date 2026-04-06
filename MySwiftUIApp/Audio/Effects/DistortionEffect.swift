import Foundation
import AVFoundation

// MARK: - ディストーションエフェクト
/// ギター向けの歪みエフェクト
/// AVAudioUnitDistortionをラップし、プリセットとウェット/ドライミックスを制御
@MainActor
final class DistortionEffect: ObservableObject, AudioEffect {

    // MARK: - AudioEffectプロトコル準拠

    let effectType: EffectType = .distortion
    var audioNode: AVAudioNode { distortionNode }

    @Published var isEnabled: Bool = true {
        didSet { distortionNode.bypass = !isEnabled }
    }

    // MARK: - ディストーションパラメータ

    /// ウェット/ドライミックス（0〜100、歪みの強さとして使用）
    @Published var wetDryMix: Float = 30.0 {
        didSet { distortionNode.wetDryMix = wetDryMix }
    }

    /// プリゲイン（-80〜20 dB）
    @Published var preGain: Float = -6.0 {
        didSet { distortionNode.preGain = preGain }
    }

    /// ディストーションプリセット
    @Published var distortionPreset: DistortionPreset = .crunch {
        didSet { applyPreset(distortionPreset) }
    }

    // MARK: - 内部プロパティ

    private let distortionNode: AVAudioUnitDistortion

    // MARK: - 初期化

    init() {
        distortionNode = AVAudioUnitDistortion()
        // 初期プリセットを適用
        applyPreset(.crunch)
    }

    // MARK: - プリセット適用

    /// 選択されたプリセットをノードに適用
    private func applyPreset(_ preset: DistortionPreset) {
        distortionNode.loadFactoryPreset(preset.avPreset)
        // プリセット適用後にウェット/ドライとプリゲインを再設定
        distortionNode.wetDryMix = wetDryMix
        distortionNode.preGain = preGain
    }

    // MARK: - リセット

    /// 全パラメータをデフォルト値にリセット
    func reset() {
        wetDryMix = 30.0
        preGain = -6.0
        distortionPreset = .crunch
        isEnabled = true
    }
}

// MARK: - ディストーションプリセット定義

/// ギター向けディストーションプリセットの列挙型
enum DistortionPreset: String, CaseIterable, Identifiable {
    case clean
    case crunch
    case overdrive
    case distortion
    case fuzz

    var id: String { rawValue }

    /// 日本語表示名
    var displayName: String {
        switch self {
        case .clean: return "クリーン"
        case .crunch: return "クランチ"
        case .overdrive: return "オーバードライブ"
        case .distortion: return "ディストーション"
        case .fuzz: return "ファズ"
        }
    }

    /// 対応するAVAudioUnitDistortionPresetに変換
    var avPreset: AVAudioUnitDistortionPreset {
        switch self {
        case .clean: return .drumsBitBrush
        case .crunch: return .drumsBufferBeats
        case .overdrive: return .speechAlienChatter
        case .distortion: return .speechCosmicInterference
        case .fuzz: return .speechGoldenPi
        }
    }
}
