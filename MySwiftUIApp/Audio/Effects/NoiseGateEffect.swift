import Foundation
import AVFoundation

// MARK: - ノイズゲートエフェクト
/// 入力レベルがスレッショルド以下の場合に音声をミュートするノイズゲート
/// AVAudioMixerNodeを使用し、入力レベルを監視して音量を制御
/// スムーズなアタック/リリースでクリックノイズを防止
@MainActor
final class NoiseGateEffect: ObservableObject, AudioEffect {

    // MARK: - AudioEffectプロトコル準拠

    let effectType: EffectType = .noiseGate
    var audioNode: AVAudioNode { mixerNode }

    @Published var isEnabled: Bool = true {
        didSet {
            if !isEnabled {
                // 無効時はフルボリュームに戻す
                mixerNode.outputVolume = 1.0
            }
        }
    }

    // MARK: - ノイズゲートパラメータ

    /// スレッショルド（-60〜0 dB）
    /// この値以下の入力レベルでゲートが閉じる
    @Published var threshold: Float = -40.0

    // MARK: - 内部プロパティ

    let mixerNode: AVAudioMixerNode

    /// 現在のゲート状態（開/閉）
    private var isGateOpen: Bool = false

    /// スムージング用の現在のゲインファクター（0〜1）
    private var currentGain: Float = 0.0

    /// アタックタイム（ゲートが開く速度、秒）
    private let attackTime: Float = 0.005

    /// リリースタイム（ゲートが閉じる速度、秒）
    private let releaseTime: Float = 0.05

    /// サンプルレート（スムージング計算用）
    private var sampleRate: Float = 44100.0

    /// オーディオタップが設置されているか
    private var isTapInstalled: Bool = false

    // MARK: - 初期化

    init() {
        mixerNode = AVAudioMixerNode()
    }

    // MARK: - タップ管理

    /// ノイズゲート処理用のオーディオタップを設置
    /// - Parameter format: 入力オーディオフォーマット
    func installGateTap(format: AVAudioFormat) {
        guard !isTapInstalled else { return }
        sampleRate = Float(format.sampleRate)

        mixerNode.installTap(onBus: 0, bufferSize: 256, format: format) { [weak self] buffer, _ in
            self?.processGateBuffer(buffer)
        }
        isTapInstalled = true
    }

    /// タップを除去
    func removeGateTap() {
        guard isTapInstalled else { return }
        mixerNode.removeTap(onBus: 0)
        isTapInstalled = false
    }

    // MARK: - ゲート処理

    /// バッファの入力レベルを計算し、ゲートの開閉を制御
    private func processGateBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isEnabled else { return }
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        // RMSレベルを計算
        var sumSquares: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sumSquares += sample * sample
        }
        let rms = sqrt(sumSquares / Float(frameLength))
        let dbLevel = 20.0 * log10(max(rms, 1e-10))

        // スレッショルドとの比較でゲート開閉を決定
        let shouldOpen = dbLevel > threshold

        // スムーズなゲイン遷移を計算
        let samplesPerBlock = Float(frameLength)
        let attackCoeff = 1.0 - exp(-samplesPerBlock / (attackTime * sampleRate))
        let releaseCoeff = 1.0 - exp(-samplesPerBlock / (releaseTime * sampleRate))

        if shouldOpen {
            // ゲートを開く（アタック）
            currentGain += attackCoeff * (1.0 - currentGain)
        } else {
            // ゲートを閉じる（リリース）
            currentGain += releaseCoeff * (0.0 - currentGain)
        }

        // ゲインを0〜1にクランプ
        currentGain = max(0.0, min(1.0, currentGain))

        // メインスレッドでミキサー音量を更新
        let gain = currentGain
        DispatchQueue.main.async { [weak self] in
            self?.mixerNode.outputVolume = gain
        }
    }

    // MARK: - リセット

    /// 全パラメータをデフォルト値にリセット
    func reset() {
        threshold = -40.0
        isEnabled = true
        currentGain = 0.0
        mixerNode.outputVolume = 1.0
    }

    deinit {
        if isTapInstalled {
            mixerNode.removeTap(onBus: 0)
        }
    }
}
