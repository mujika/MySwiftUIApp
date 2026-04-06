import Foundation

// MARK: - EQバンド設定

/// パラメトリックEQの1バンド分の設定
struct EQBand: Codable, Identifiable {
    let id: UUID

    /// 中心周波数（Hz）
    var frequency: Double

    /// ゲイン（dB、-12.0〜+12.0）
    var gain: Double

    /// バンド幅（Q値、0.1〜10.0）
    var bandwidth: Double

    init(
        id: UUID = UUID(),
        frequency: Double = 1000,
        gain: Double = 0,
        bandwidth: Double = 1.0
    ) {
        self.id = id
        self.frequency = frequency
        self.gain = gain
        self.bandwidth = bandwidth
    }
}

// MARK: - EQ設定

/// イコライザー全体の設定
struct EQSettings: Codable {
    /// EQの有効/無効
    var isEnabled: Bool

    /// EQバンドの配列
    var bands: [EQBand]

    /// デフォルト設定（5バンドEQ）
    init(
        isEnabled: Bool = false,
        bands: [EQBand]? = nil
    ) {
        self.isEnabled = isEnabled
        self.bands = bands ?? [
            EQBand(frequency: 80, gain: 0, bandwidth: 1.0),
            EQBand(frequency: 250, gain: 0, bandwidth: 1.0),
            EQBand(frequency: 1000, gain: 0, bandwidth: 1.0),
            EQBand(frequency: 4000, gain: 0, bandwidth: 1.0),
            EQBand(frequency: 12000, gain: 0, bandwidth: 1.0)
        ]
    }
}

// MARK: - リバーブ設定

/// リバーブのプリセットタイプ
enum ReverbPresetType: String, Codable, CaseIterable {
    case smallRoom = "小部屋"
    case mediumRoom = "中部屋"
    case largeRoom = "大部屋"
    case hall = "ホール"
    case cathedral = "大聖堂"
    case plate = "プレート"

    /// 表示用の名前
    var displayName: String {
        return rawValue
    }
}

/// リバーブエフェクトの設定
struct ReverbSettings: Codable {
    /// リバーブの有効/無効
    var isEnabled: Bool

    /// ウェット/ドライ比率（0.0〜1.0）
    var wetDryMix: Double

    /// リバーブのプリセットタイプ
    var presetType: ReverbPresetType

    init(
        isEnabled: Bool = false,
        wetDryMix: Double = 0.3,
        presetType: ReverbPresetType = .mediumRoom
    ) {
        self.isEnabled = isEnabled
        self.wetDryMix = wetDryMix
        self.presetType = presetType
    }
}

// MARK: - ディレイ設定

/// ディレイエフェクトの設定
struct DelaySettings: Codable {
    /// ディレイの有効/無効
    var isEnabled: Bool

    /// ディレイタイム（秒、0.01〜2.0）
    var time: Double

    /// フィードバック量（0.0〜0.95）
    var feedback: Double

    /// ウェット/ドライ比率（0.0〜1.0）
    var wetDryMix: Double

    init(
        isEnabled: Bool = false,
        time: Double = 0.3,
        feedback: Double = 0.4,
        wetDryMix: Double = 0.3
    ) {
        self.isEnabled = isEnabled
        self.time = time
        self.feedback = feedback
        self.wetDryMix = wetDryMix
    }
}

// MARK: - コンプレッサー設定

/// コンプレッサーエフェクトの設定
struct CompressorSettings: Codable {
    /// コンプレッサーの有効/無効
    var isEnabled: Bool

    /// スレッショルド（dB、-40.0〜0.0）
    var threshold: Double

    /// 圧縮比（1.0〜20.0）
    var ratio: Double

    /// アタックタイム（秒、0.001〜0.2）
    var attack: Double

    /// リリースタイム（秒、0.01〜1.0）
    var release: Double

    init(
        isEnabled: Bool = false,
        threshold: Double = -20.0,
        ratio: Double = 4.0,
        attack: Double = 0.01,
        release: Double = 0.1
    ) {
        self.isEnabled = isEnabled
        self.threshold = threshold
        self.ratio = ratio
        self.attack = attack
        self.release = release
    }
}

// MARK: - ディストーション設定

/// ディストーションのタイプ
enum DistortionType: String, Codable, CaseIterable {
    case overdrive = "オーバードライブ"
    case distortion = "ディストーション"
    case fuzz = "ファズ"
    case bitCrusher = "ビットクラッシャー"

    /// 表示用の名前
    var displayName: String {
        return rawValue
    }
}

/// ディストーションエフェクトの設定
struct DistortionSettings: Codable {
    /// ディストーションの有効/無効
    var isEnabled: Bool

    /// ゲイン（0.0〜1.0）
    var gain: Double

    /// ディストーションタイプ
    var type: DistortionType

    /// ウェット/ドライ比率（0.0〜1.0）
    var wetDryMix: Double

    init(
        isEnabled: Bool = false,
        gain: Double = 0.5,
        type: DistortionType = .overdrive,
        wetDryMix: Double = 0.5
    ) {
        self.isEnabled = isEnabled
        self.gain = gain
        self.type = type
        self.wetDryMix = wetDryMix
    }
}

// MARK: - ノイズゲート設定

/// ノイズゲートエフェクトの設定
struct NoiseGateSettings: Codable {
    /// ノイズゲートの有効/無効
    var isEnabled: Bool

    /// スレッショルド（dB、-80.0〜0.0）
    var threshold: Double

    init(
        isEnabled: Bool = false,
        threshold: Double = -40.0
    ) {
        self.isEnabled = isEnabled
        self.threshold = threshold
    }
}

// MARK: - エフェクトチェーン設定

/// 全エフェクトの設定をまとめた構造体
struct EffectChainSettings: Codable {
    /// イコライザー設定
    var eqSettings: EQSettings

    /// リバーブ設定
    var reverbSettings: ReverbSettings

    /// ディレイ設定
    var delaySettings: DelaySettings

    /// コンプレッサー設定
    var compressorSettings: CompressorSettings

    /// ディストーション設定
    var distortionSettings: DistortionSettings

    /// ノイズゲート設定
    var noiseGateSettings: NoiseGateSettings

    /// デフォルト設定（全エフェクトOFF）
    init(
        eqSettings: EQSettings = EQSettings(),
        reverbSettings: ReverbSettings = ReverbSettings(),
        delaySettings: DelaySettings = DelaySettings(),
        compressorSettings: CompressorSettings = CompressorSettings(),
        distortionSettings: DistortionSettings = DistortionSettings(),
        noiseGateSettings: NoiseGateSettings = NoiseGateSettings()
    ) {
        self.eqSettings = eqSettings
        self.reverbSettings = reverbSettings
        self.delaySettings = delaySettings
        self.compressorSettings = compressorSettings
        self.distortionSettings = distortionSettings
        self.noiseGateSettings = noiseGateSettings
    }
}

// MARK: - プリセットモデル

/// エフェクトプリセットモデル
/// ファクトリープリセットとユーザー作成プリセットの両方を管理する
struct Preset: Identifiable, Codable {
    /// 一意識別子
    let id: UUID

    /// プリセット名
    var name: String

    /// SF Symbolのアイコン名
    var icon: String

    /// ファクトリープリセットかどうか（true=内蔵、false=ユーザー作成）
    let isFactory: Bool

    /// 作成日時
    let creationDate: Date

    /// エフェクトチェーンの全設定
    var effectSettings: EffectChainSettings

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "slider.horizontal.3",
        isFactory: Bool = false,
        creationDate: Date = Date(),
        effectSettings: EffectChainSettings = EffectChainSettings()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isFactory = isFactory
        self.creationDate = creationDate
        self.effectSettings = effectSettings
    }

    // MARK: - ファクトリープリセット

    /// 内蔵プリセット一覧を返す
    static var factoryPresets: [Preset] {
        return [
            cleanPreset,
            warmAcousticPreset,
            brightLeadPreset,
            heavyDistortionPreset,
            ambientReverbPreset,
            slapBackDelayPreset
        ]
    }

    /// クリーンプリセット（エフェクトなし、ノイズゲートのみ）
    static var cleanPreset: Preset {
        var settings = EffectChainSettings()
        settings.noiseGateSettings = NoiseGateSettings(isEnabled: true, threshold: -50.0)
        return Preset(
            name: "Clean",
            icon: "waveform",
            isFactory: true,
            effectSettings: settings
        )
    }

    /// ウォームアコースティックプリセット
    static var warmAcousticPreset: Preset {
        var settings = EffectChainSettings()
        // 低域を少しブースト、高域をカットして温かみのあるサウンドに
        settings.eqSettings = EQSettings(
            isEnabled: true,
            bands: [
                EQBand(frequency: 80, gain: 3.0, bandwidth: 1.0),
                EQBand(frequency: 250, gain: 2.0, bandwidth: 1.2),
                EQBand(frequency: 1000, gain: 0, bandwidth: 1.0),
                EQBand(frequency: 4000, gain: -1.0, bandwidth: 1.0),
                EQBand(frequency: 12000, gain: -3.0, bandwidth: 1.0)
            ]
        )
        // 軽いリバーブで空間感を追加
        settings.reverbSettings = ReverbSettings(
            isEnabled: true,
            wetDryMix: 0.2,
            presetType: .smallRoom
        )
        // 軽いコンプレッションでダイナミクスを整える
        settings.compressorSettings = CompressorSettings(
            isEnabled: true,
            threshold: -15.0,
            ratio: 3.0,
            attack: 0.02,
            release: 0.15
        )
        return Preset(
            name: "Warm Acoustic",
            icon: "guitars",
            isFactory: true,
            effectSettings: settings
        )
    }

    /// ブライトリードプリセット
    static var brightLeadPreset: Preset {
        var settings = EffectChainSettings()
        // 中高域をブーストしてリードギターらしい抜けを確保
        settings.eqSettings = EQSettings(
            isEnabled: true,
            bands: [
                EQBand(frequency: 80, gain: -2.0, bandwidth: 1.0),
                EQBand(frequency: 250, gain: 0, bandwidth: 1.0),
                EQBand(frequency: 1000, gain: 2.0, bandwidth: 1.5),
                EQBand(frequency: 4000, gain: 4.0, bandwidth: 1.0),
                EQBand(frequency: 12000, gain: 2.0, bandwidth: 1.0)
            ]
        )
        // 軽いオーバードライブ
        settings.distortionSettings = DistortionSettings(
            isEnabled: true,
            gain: 0.3,
            type: .overdrive,
            wetDryMix: 0.6
        )
        // ショートディレイでダブリング効果
        settings.delaySettings = DelaySettings(
            isEnabled: true,
            time: 0.08,
            feedback: 0.1,
            wetDryMix: 0.15
        )
        settings.noiseGateSettings = NoiseGateSettings(isEnabled: true, threshold: -45.0)
        return Preset(
            name: "Bright Lead",
            icon: "bolt.fill",
            isFactory: true,
            effectSettings: settings
        )
    }

    /// ヘヴィディストーションプリセット
    static var heavyDistortionPreset: Preset {
        var settings = EffectChainSettings()
        // ミッドスクープ（ドンシャリ）設定
        settings.eqSettings = EQSettings(
            isEnabled: true,
            bands: [
                EQBand(frequency: 80, gain: 4.0, bandwidth: 0.8),
                EQBand(frequency: 250, gain: 1.0, bandwidth: 1.0),
                EQBand(frequency: 1000, gain: -3.0, bandwidth: 1.5),
                EQBand(frequency: 4000, gain: 3.0, bandwidth: 1.0),
                EQBand(frequency: 12000, gain: 2.0, bandwidth: 1.0)
            ]
        )
        // 強めのディストーション
        settings.distortionSettings = DistortionSettings(
            isEnabled: true,
            gain: 0.8,
            type: .distortion,
            wetDryMix: 0.9
        )
        // 強めのコンプレッション
        settings.compressorSettings = CompressorSettings(
            isEnabled: true,
            threshold: -25.0,
            ratio: 8.0,
            attack: 0.005,
            release: 0.08
        )
        settings.noiseGateSettings = NoiseGateSettings(isEnabled: true, threshold: -35.0)
        return Preset(
            name: "Heavy Distortion",
            icon: "flame.fill",
            isFactory: true,
            effectSettings: settings
        )
    }

    /// アンビエントリバーブプリセット
    static var ambientReverbPreset: Preset {
        var settings = EffectChainSettings()
        // 高域を少し強調して空気感を出す
        settings.eqSettings = EQSettings(
            isEnabled: true,
            bands: [
                EQBand(frequency: 80, gain: -1.0, bandwidth: 1.0),
                EQBand(frequency: 250, gain: 0, bandwidth: 1.0),
                EQBand(frequency: 1000, gain: 0, bandwidth: 1.0),
                EQBand(frequency: 4000, gain: 2.0, bandwidth: 1.2),
                EQBand(frequency: 12000, gain: 3.0, bandwidth: 1.0)
            ]
        )
        // 深いリバーブで広がりのあるサウンド
        settings.reverbSettings = ReverbSettings(
            isEnabled: true,
            wetDryMix: 0.6,
            presetType: .cathedral
        )
        // ロングディレイでアンビエント感を追加
        settings.delaySettings = DelaySettings(
            isEnabled: true,
            time: 0.5,
            feedback: 0.5,
            wetDryMix: 0.25
        )
        return Preset(
            name: "Ambient Reverb",
            icon: "cloud.fill",
            isFactory: true,
            effectSettings: settings
        )
    }

    /// スラップバックディレイプリセット
    static var slapBackDelayPreset: Preset {
        var settings = EffectChainSettings()
        // ナチュラルなEQ
        settings.eqSettings = EQSettings(
            isEnabled: true,
            bands: [
                EQBand(frequency: 80, gain: 1.0, bandwidth: 1.0),
                EQBand(frequency: 250, gain: 0, bandwidth: 1.0),
                EQBand(frequency: 1000, gain: 1.0, bandwidth: 1.0),
                EQBand(frequency: 4000, gain: 1.5, bandwidth: 1.0),
                EQBand(frequency: 12000, gain: 0, bandwidth: 1.0)
            ]
        )
        // クラシックなスラップバックディレイ（ロカビリー/カントリー風）
        settings.delaySettings = DelaySettings(
            isEnabled: true,
            time: 0.12,
            feedback: 0.15,
            wetDryMix: 0.4
        )
        settings.noiseGateSettings = NoiseGateSettings(isEnabled: true, threshold: -50.0)
        return Preset(
            name: "Slap Back Delay",
            icon: "arrow.left.arrow.right",
            isFactory: true,
            effectSettings: settings
        )
    }
}
