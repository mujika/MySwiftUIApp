import Foundation
import AVFoundation

// MARK: - 拍子記号

/// メトロノームの拍子記号
struct TimeSignature: Equatable {
    /// 1小節あたりの拍数
    let beats: Int
    /// 拍の音価（4 = 四分音符, 8 = 八分音符）
    let noteValue: Int

    /// 日本語表示名
    var displayName: String {
        return "\(beats)/\(noteValue)"
    }

    /// よく使われる拍子記号の一覧
    static let common: [TimeSignature] = [
        TimeSignature(beats: 4, noteValue: 4),
        TimeSignature(beats: 3, noteValue: 4),
        TimeSignature(beats: 6, noteValue: 8),
        TimeSignature(beats: 2, noteValue: 4),
        TimeSignature(beats: 5, noteValue: 4),
        TimeSignature(beats: 7, noteValue: 8)
    ]
}

// MARK: - メトロノーム
/// 高精度なメトロノーム
/// AVAudioPlayerNodeとプログラム生成のクリック音を使用
/// DispatchSourceTimerによる正確なタイミング制御
/// タップテンポ機能付き
@MainActor
final class Metronome: ObservableObject {

    // MARK: - 公開プロパティ

    /// BPM（40〜240、デフォルト120）
    @Published var bpm: Int = 120

    /// 拍子記号
    @Published var timeSignature: TimeSignature = TimeSignature(beats: 4, noteValue: 4)

    /// メトロノームが再生中か
    @Published var isPlaying: Bool = false

    /// 現在の拍番号（1始まり）
    @Published var currentBeat: Int = 1

    /// サブディビジョン数（1=なし, 2=8分, 3=三連, 4=16分）
    @Published var subdivisions: Int = 1

    /// クリック音量（0〜1）
    @Published var volume: Float = 0.8

    // MARK: - 内部プロパティ

    /// クリック再生用のプレイヤーノード
    private var playerNode: AVAudioPlayerNode?

    /// メトロノーム用のミキサーノード
    private let mixerNode = AVAudioMixerNode()

    /// AVAudioEngineへの弱参照
    private weak var engine: AVAudioEngine?

    /// 高精度タイマー
    private var timer: DispatchSourceTimer?

    /// アクセント付きクリック音のバッファ
    private var accentClickBuffer: AVAudioPCMBuffer?

    /// 通常クリック音のバッファ
    private var normalClickBuffer: AVAudioPCMBuffer?

    /// サブディビジョンクリック音のバッファ
    private var subdivisionClickBuffer: AVAudioPCMBuffer?

    /// オーディオフォーマット
    private var audioFormat: AVAudioFormat?

    /// タップテンポの記録用
    private var tapTimestamps: [Date] = []

    /// 現在のサブディビジョンカウント
    private var currentSubdivision: Int = 0

    // MARK: - 初期化

    init() {}

    // MARK: - エンジンへの接続

    /// メトロノームノードをAVAudioEngineに登録
    /// - Parameter engine: 対象のAVAudioEngine
    func attachToEngine(_ engine: AVAudioEngine) {
        self.engine = engine

        playerNode = AVAudioPlayerNode()
        guard let playerNode = playerNode else { return }

        engine.attach(playerNode)
        engine.attach(mixerNode)

        // プレイヤー → ミキサー → メインミキサー
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        audioFormat = format

        engine.connect(playerNode, to: mixerNode, format: format)
        engine.connect(mixerNode, to: engine.mainMixerNode, format: format)

        mixerNode.outputVolume = volume

        // クリック音バッファを生成
        generateClickBuffers(format: format)
    }

    // MARK: - クリック音生成

    /// サイン波バーストによるクリック音バッファを生成
    private func generateClickBuffers(format: AVAudioFormat) {
        let sampleRate = Float(format.sampleRate)
        // クリック音の長さ（約10ms）
        let clickDuration: Float = 0.01
        let frameCount = AVAudioFrameCount(sampleRate * clickDuration)

        // アクセントクリック（高い音: 1200Hz）
        accentClickBuffer = generateSineBurst(
            frequency: 1200.0,
            amplitude: 0.9,
            frameCount: frameCount,
            sampleRate: sampleRate,
            format: format
        )

        // 通常クリック（中間の音: 800Hz）
        normalClickBuffer = generateSineBurst(
            frequency: 800.0,
            amplitude: 0.7,
            frameCount: frameCount,
            sampleRate: sampleRate,
            format: format
        )

        // サブディビジョンクリック（低い音: 600Hz、小音量）
        subdivisionClickBuffer = generateSineBurst(
            frequency: 600.0,
            amplitude: 0.3,
            frameCount: frameCount,
            sampleRate: sampleRate,
            format: format
        )
    }

    /// 指定パラメータでサイン波バーストのPCMバッファを生成
    private func generateSineBurst(frequency: Float, amplitude: Float, frameCount: AVAudioFrameCount, sampleRate: Float, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        let twoPi = Float.pi * 2.0

        for i in 0..<Int(frameCount) {
            let phase = twoPi * frequency * Float(i) / sampleRate
            // エンベロープ（減衰するサイン波）
            let envelope = 1.0 - (Float(i) / Float(frameCount))
            channelData[i] = sin(phase) * amplitude * envelope * envelope
        }

        return buffer
    }

    // MARK: - メトロノーム制御

    /// メトロノームを開始
    func start() {
        guard !isPlaying else { return }
        guard let playerNode = playerNode else { return }

        playerNode.play()
        isPlaying = true
        currentBeat = 1
        currentSubdivision = 0

        // タイマーを起動
        startTimer()
    }

    /// メトロノームを停止
    func stop() {
        isPlaying = false
        timer?.cancel()
        timer = nil
        playerNode?.stop()
        currentBeat = 1
        currentSubdivision = 0
    }

    /// BPMを設定（範囲チェック付き）
    func setBPM(_ newBPM: Int) {
        bpm = max(40, min(240, newBPM))
        // 再生中なら再起動してタイミングを更新
        if isPlaying {
            timer?.cancel()
            timer = nil
            startTimer()
        }
    }

    // MARK: - タイマー管理

    /// 高精度タイマーを起動
    private func startTimer() {
        timer?.cancel()

        // 1拍の間隔を計算（秒）
        let beatInterval = 60.0 / Double(bpm)
        // サブディビジョン込みの間隔
        let tickInterval = beatInterval / Double(subdivisions)

        let timerSource = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timerSource.schedule(deadline: .now(), repeating: tickInterval, leeway: .milliseconds(1))

        timerSource.setEventHandler { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleTick()
            }
        }

        timer = timerSource
        timerSource.resume()
    }

    /// 各ティックで呼ばれるハンドラ
    private func handleTick() {
        guard isPlaying else { return }

        if currentSubdivision == 0 {
            // メインビート
            if currentBeat == 1 {
                // 1拍目: アクセント
                scheduleClick(accentClickBuffer)
            } else {
                // その他の拍: 通常クリック
                scheduleClick(normalClickBuffer)
            }
        } else {
            // サブディビジョンクリック
            scheduleClick(subdivisionClickBuffer)
        }

        // サブディビジョンカウントを進める
        currentSubdivision += 1
        if currentSubdivision >= subdivisions {
            currentSubdivision = 0
            // 次の拍に進む
            currentBeat += 1
            if currentBeat > timeSignature.beats {
                currentBeat = 1
            }
        }
    }

    /// クリック音をスケジュール
    private func scheduleClick(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer = buffer, let playerNode = playerNode else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    // MARK: - タップテンポ

    /// タップテンポ: タップ間隔からBPMを算出
    /// 最低3回のタップが必要
    func tapTempo() {
        let now = Date()

        // 2秒以上間隔が空いたらリセット
        if let lastTap = tapTimestamps.last {
            if now.timeIntervalSince(lastTap) > 2.0 {
                tapTimestamps.removeAll()
            }
        }

        tapTimestamps.append(now)

        // 直近6回のタップを保持
        if tapTimestamps.count > 6 {
            tapTimestamps.removeFirst()
        }

        // 最低3回のタップでBPM計算
        guard tapTimestamps.count >= 3 else { return }

        // タップ間隔の平均を計算
        var totalInterval: TimeInterval = 0
        for i in 1..<tapTimestamps.count {
            totalInterval += tapTimestamps[i].timeIntervalSince(tapTimestamps[i - 1])
        }
        let averageInterval = totalInterval / Double(tapTimestamps.count - 1)

        // BPMに変換
        guard averageInterval > 0 else { return }
        let calculatedBPM = Int(60.0 / averageInterval)
        setBPM(calculatedBPM)
    }

    // MARK: - 音量制御

    /// メトロノームの音量を更新
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        mixerNode.outputVolume = volume
    }

    deinit {
        timer?.cancel()
    }
}
