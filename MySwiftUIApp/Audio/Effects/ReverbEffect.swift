import Foundation
import AVFoundation

// MARK: - リバーブエフェクト
/// 空間の残響をシミュレートするリバーブエフェクト
/// AVAudioUnitReverbをラップし、各種プリセットとウェット/ドライミックスを制御
@MainActor
final class ReverbEffect: ObservableObject, AudioEffect {

    // MARK: - AudioEffectプロトコル準拠

    let effectType: EffectType = .reverb
    var audioNode: AVAudioNode { reverbNode }

    @Published var isEnabled: Bool = true {
        didSet { reverbNode.bypass = !isEnabled }
    }

    // MARK: - リバーブパラメータ

    /// ウェット/ドライミックス（0〜100）
    @Published var wetDryMix: Float = 30.0 {
        didSet { reverbNode.wetDryMix = wetDryMix }
    }

    /// 現在のリバーブプリセット
    @Published var reverbPreset: ReverbEffectPreset = .mediumHall {
        didSet { reverbNode.loadFactoryPreset(reverbPreset.avPreset) }
    }

    // MARK: - 内部プロパティ

    private let reverbNode: AVAudioUnitReverb

    // MARK: - 初期化

    init() {
        reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.mediumHall)
        reverbNode.wetDryMix = 30.0
    }

    // MARK: - リセット

    /// 全パラメータをデフォルト値にリセット
    func reset() {
        wetDryMix = 30.0
        reverbPreset = .mediumHall
        isEnabled = true
    }
}

// MARK: - リバーブエフェク���プリセット定���

/// 利用可能な��バーブエフェクトプリセットの列挙型
/// Preset.swiftのReverbPresetTypeとの名前衝突を避けるため別名を使用
enum ReverbEffectPreset: String, CaseIterable, Identifiable {
    case smallRoom
    case mediumRoom
    case largeRoom
    case mediumHall
    case largeHall
    case cathedral
    case plate

    var id: String { rawValue }

    /// 日本語表示名
    var displayName: String {
        switch self {
        case .smallRoom: return "小部屋"
        case .mediumRoom: return "中部屋"
        case .largeRoom: return "大部屋"
        case .mediumHall: return "中ホール"
        case .largeHall: return "大ホール"
        case .cathedral: return "大聖堂"
        case .plate: return "プレート"
        }
    }

    /// 対応するAVAudioUnitReverbPresetに変換
    var avPreset: AVAudioUnitReverbPreset {
        switch self {
        case .smallRoom: return .smallRoom
        case .mediumRoom: return .mediumRoom
        case .largeRoom: return .largeRoom
        case .mediumHall: return .mediumHall
        case .largeHall: return .largeHall
        case .cathedral: return .cathedral
        case .plate: return .plate
        }
    }
}
