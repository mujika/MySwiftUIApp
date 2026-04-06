import Foundation
import AVFoundation
import SwiftUI

// MARK: - オーディオプレイヤーマネージャー
/// AVAudioPlayerNodeベースの高機能再生マネージャー
/// 可変速再生、シーク、波形データ生成、プログレス追跡を提供
/// AVAudioEngineベースで実装し、AVAudioPlayerは使用しない
@MainActor
final class AudioPlayerManager: ObservableObject {

    // MARK: - 公開プロパティ

    /// 再生中フラグ
    @Published var isPlaying: Bool = false

    /// 現在の再生位置（秒）
    @Published var currentTime: TimeInterval = 0

    /// オーディオファイルの全長（秒）
    @Published var duration: TimeInterval = 0

    /// 再生速度（0.5〜2.0）
    @Published var playbackRate: Float = 1.0

    /// 再生音量（0〜1）
    @Published var volume: Float = 1.0 {
        didSet { mixerNode.outputVolume = volume }
    }

    /// 現在再生中の録音
    @Published var currentRecording: Recording?

    /// 再生進捗（0〜1）
    @Published var playbackProgress: Double = 0.0

    /// 以前の命名規則と互換性を持つプロパティ
    var playingRecording: Recording? { currentRecording }

    // MARK: - 利用可能な再生速度

    /// 選択可能な再生速度一覧
    static let availableRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    // MARK: - 内部プロパティ

    /// 再生用オーディオエンジン
    private let playbackEngine = AVAudioEngine()

    /// 再生用プレイヤーノード
    private let playerNode = AVAudioPlayerNode()

    /// 速度変更用のタイムピッチノード
    private let timePitchNode = AVAudioUnitTimePitch()

    /// ミキサーノード（音量制御用）
    private let mixerNode = AVAudioMixerNode()

    /// 現在のオーディオファイル
    private var audioFile: AVAudioFile?

    /// 進捗更新タイマー（60fps）
    private var progressTimer: Timer?

    /// 再生開始フレーム位置
    private var startingFramePosition: AVAudioFramePosition = 0

    /// エンジンが準備済みか
    private var isEngineSetup: Bool = false

    // MARK: - 初期化

    init() {
        setupPlaybackEngine()
    }

    // MARK: - エンジン設定

    /// 再生用AVAudioEngineのグラフを構築
    /// playerNode → timePitchNode → mixerNode → mainMixerNode → outputNode
    private func setupPlaybackEngine() {
        playbackEngine.attach(playerNode)
        playbackEngine.attach(timePitchNode)
        playbackEngine.attach(mixerNode)

        // ノード接続はファイル読み込み時に行う
        isEngineSetup = true
    }

    /// オーディオファイルのフォーマットに合わせてノードを接続
    private func connectNodes(format: AVAudioFormat) {
        // 既存の接続を解除
        playbackEngine.disconnectNodeOutput(playerNode)
        playbackEngine.disconnectNodeOutput(timePitchNode)
        playbackEngine.disconnectNodeOutput(mixerNode)

        // playerNode → timePitch → mixer → mainMixer
        playbackEngine.connect(playerNode, to: timePitchNode, format: format)
        playbackEngine.connect(timePitchNode, to: mixerNode, format: format)
        playbackEngine.connect(mixerNode, to: playbackEngine.mainMixerNode, format: format)
    }

    // MARK: - 再生制御

    /// 指定された録音を再生
    /// - Parameter recording: 再生する録音
    func play(recording: Recording) {
        // 再生中なら停止
        if isPlaying {
            stop()
        }

        do {
            // オーディオファイルを読み込み
            audioFile = try AVAudioFile(forReading: recording.url)
            guard let audioFile = audioFile else { return }

            let format = audioFile.processingFormat
            duration = Double(audioFile.length) / format.sampleRate

            // ノードを接続
            connectNodes(format: format)

            // レート設定
            timePitchNode.rate = playbackRate
            mixerNode.outputVolume = volume

            // エンジンを起動
            if !playbackEngine.isRunning {
                try playbackEngine.start()
            }

            // ファイルをスケジュール
            startingFramePosition = 0
            playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.handlePlaybackCompletion()
                }
            }

            playerNode.play()
            isPlaying = true
            currentRecording = recording

            // 進捗タイマーを開始（60fps）
            startProgressTimer()

        } catch {
            print("録音の再生に失敗: \(error)")
        }
    }

    /// 再生を一時停止
    func pause() {
        guard isPlaying else { return }

        // 現在位置を保存
        if let nodeTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            startingFramePosition = playerTime.sampleTime + startingFramePosition
        }

        playerNode.pause()
        isPlaying = false
        stopProgressTimer()
    }

    /// 再生を停止してリセット
    func stop() {
        playerNode.stop()
        playbackEngine.stop()
        isPlaying = false
        currentTime = 0
        playbackProgress = 0
        startingFramePosition = 0
        currentRecording = nil
        stopProgressTimer()
    }

    /// 旧APIとの互換性メソッド
    func playRecording(_ recording: Recording) {
        play(recording: recording)
    }

    /// 旧APIとの互換性メソッド
    func stopPlayback() {
        stop()
    }

    /// 指定位置にシーク
    /// - Parameter time: シーク先の時間（秒）
    func seek(to time: TimeInterval) {
        guard let audioFile = audioFile else { return }

        let wasPlaying = isPlaying
        playerNode.stop()

        let format = audioFile.processingFormat
        let sampleRate = format.sampleRate
        let seekFrame = AVAudioFramePosition(time * sampleRate)
        let totalFrames = audioFile.length

        guard seekFrame >= 0 && seekFrame < totalFrames else { return }

        let remainingFrames = AVAudioFrameCount(totalFrames - seekFrame)
        startingFramePosition = seekFrame

        // 指定位置からスケジュール
        playerNode.scheduleSegment(
            audioFile,
            startingFrame: seekFrame,
            frameCount: remainingFrames,
            at: nil
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.handlePlaybackCompletion()
            }
        }

        currentTime = time
        playbackProgress = time / duration

        if wasPlaying {
            playerNode.play()
        }
    }

    /// 再生速度を設定
    /// - Parameter rate: 再生速度（0.5〜2.0）
    func setRate(_ rate: Float) {
        let clampedRate = max(0.5, min(2.0, rate))
        playbackRate = clampedRate
        timePitchNode.rate = clampedRate
    }

    // MARK: - 再生完了ハンドラ

    /// 再生完了時の処理
    private func handlePlaybackCompletion() {
        isPlaying = false
        currentTime = 0
        playbackProgress = 0
        startingFramePosition = 0
        currentRecording = nil
        stopProgressTimer()
    }

    // MARK: - 進捗タイマー

    /// 再生進捗更新タイマーを開始（60fps）
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }

    /// 進捗タイマーを停止
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    /// 現在の再生位置を計算して更新
    private func updateProgress() {
        guard isPlaying, let audioFile = audioFile else { return }

        if let nodeTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            let sampleRate = audioFile.processingFormat.sampleRate
            let currentSample = Double(playerTime.sampleTime + startingFramePosition)
            currentTime = currentSample / sampleRate
            playbackProgress = currentTime / duration
        }
    }

    // MARK: - 波形データ生成

    /// オーディオファイルから波形表示用のサンプルデータを生成
    /// - Parameters:
    ///   - url: オーディオファイルのURL
    ///   - sampleCount: 出力サンプル数
    /// - Returns: 正規化された波形サンプル配列
    func generateWaveformData(from url: URL, sampleCount: Int = 200) -> [Float] {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let totalFrames = Int(audioFile.length)

            guard totalFrames > 0 else { return Array(repeating: 0, count: sampleCount) }

            // 全フレームを読み込み
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)) else {
                return Array(repeating: 0, count: sampleCount)
            }
            try audioFile.read(into: buffer)

            guard let channelData = buffer.floatChannelData?[0] else {
                return Array(repeating: 0, count: sampleCount)
            }

            // ダウンサンプリング（各区間の最大振幅を取得）
            let framesPerSample = totalFrames / sampleCount
            var waveform = [Float]()

            for i in 0..<sampleCount {
                let startFrame = i * framesPerSample
                let endFrame = min(startFrame + framesPerSample, totalFrames)
                var maxAmplitude: Float = 0

                for j in startFrame..<endFrame {
                    let amplitude = abs(channelData[j])
                    if amplitude > maxAmplitude {
                        maxAmplitude = amplitude
                    }
                }
                waveform.append(maxAmplitude)
            }

            // 正規化
            let peak = waveform.max() ?? 1.0
            if peak > 0 {
                waveform = waveform.map { $0 / peak }
            }

            return waveform

        } catch {
            print("波形データの生成に失敗: \(error)")
            return Array(repeating: 0, count: sampleCount)
        }
    }

    // MARK: - クリーンアップ

    deinit {
        progressTimer?.invalidate()
        playbackEngine.stop()
    }
}
