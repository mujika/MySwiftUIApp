import Foundation
import AVFoundation

// MARK: - トラック状態

/// マルチトラックの各トラックの状態を保持する構造体
struct TrackState: Identifiable {
    let id: UUID
    /// トラック名
    var name: String
    /// オーディオファイルのURL
    var url: URL
    /// トラック音量（0〜1）
    var volume: Float
    /// パン（-1:左 〜 0:中央 〜 1:右）
    var pan: Float
    /// ミュート状態
    var isMuted: Bool
    /// ソロ状態
    var isSolo: Bool

    init(name: String, url: URL, volume: Float = 1.0, pan: Float = 0.0) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.volume = volume
        self.pan = pan
        self.isMuted = false
        self.isSolo = false
    }
}

// MARK: - マルチトラックエンジン
/// 最大8トラックの同時再生を管理するマルチトラックエンジン
/// 各トラックにはAVAudioPlayerNode + AVAudioMixerNodeが割り当てられ、
/// 個別のボリューム、パン、ミュート、ソロ制御が可能
/// ミックスダウン（バウンス）機能で全トラックを1つのファイルに書き出し
@MainActor
final class MultiTrackEngine: ObservableObject {

    // MARK: - 公開プロパティ

    /// 全トラックの状態
    @Published var tracks: [TrackState] = []

    /// 再生中か
    @Published var isPlaying: Bool = false

    /// 現在の再生位置（秒）
    @Published var currentTime: TimeInterval = 0

    /// 全体の長さ（最長トラック基準）
    @Published var totalDuration: TimeInterval = 0

    // MARK: - 内部プロパティ

    /// 最大トラック数
    private let maxTracks = 8

    /// 各トラックのプレイヤーノード
    private var playerNodes: [UUID: AVAudioPlayerNode] = [:]

    /// 各トラックのミキサーノード
    private var mixerNodes: [UUID: AVAudioMixerNode] = [:]

    /// 各トラックのオーディオファイル
    private var audioFiles: [UUID: AVAudioFile] = [:]

    /// メインミキサーノード（全トラックの出力を統合）
    private let mainMixer = AVAudioMixerNode()

    /// AVAudioEngineへの弱参照
    private weak var engine: AVAudioEngine?

    /// 再生位置更新用タイマー
    private var progressTimer: Timer?

    /// 再生開始時刻
    private var playbackStartTime: Date?

    // MARK: - 初期化

    init() {}

    // MARK: - エンジンへの接続

    /// マルチトラックエンジンのメインミキサーをAVAudioEngineに登録
    /// - Parameter engine: 対象のAVAudioEngine
    func attachToEngine(_ engine: AVAudioEngine) {
        self.engine = engine
        engine.attach(mainMixer)

        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(mainMixer, to: engine.mainMixerNode, format: format)
    }

    // MARK: - トラック管理

    /// 新しいトラックを追加
    /// - Parameters:
    ///   - url: オーディオファイルのURL
    ///   - name: トラック名（省略時はファイル名）
    /// - Returns: 追加されたトラックのID（最大数超過時はnil）
    @discardableResult
    func addTrack(url: URL, name: String? = nil) -> UUID? {
        guard tracks.count < maxTracks else {
            print("最大トラック数（\(maxTracks)）に達しています")
            return nil
        }
        guard let engine = engine else { return nil }

        let trackName = name ?? url.deletingPathExtension().lastPathComponent
        let trackState = TrackState(name: trackName, url: url)
        let trackId = trackState.id

        // オーディオファイルを読み込み
        do {
            let audioFile = try AVAudioFile(forReading: url)
            audioFiles[trackId] = audioFile

            // トラックの長さを更新
            let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
            if duration > totalDuration {
                totalDuration = duration
            }
        } catch {
            print("トラック用オーディオファイルの読み込みに失敗: \(error)")
            return nil
        }

        // プレイヤーノードとミキサーノードを作成
        let playerNode = AVAudioPlayerNode()
        let mixerNode = AVAudioMixerNode()

        engine.attach(playerNode)
        engine.attach(mixerNode)

        let format = audioFiles[trackId]!.processingFormat
        engine.connect(playerNode, to: mixerNode, format: format)
        engine.connect(mixerNode, to: mainMixer, format: format)

        playerNodes[trackId] = playerNode
        mixerNodes[trackId] = mixerNode

        tracks.append(trackState)

        return trackId
    }

    /// 指定トラックを除去
    /// - Parameter id: 除去するトラックのID
    func removeTrack(id: UUID) {
        guard let engine = engine else { return }

        // プレイヤーノードを停止しデタッチ
        if let playerNode = playerNodes[id] {
            playerNode.stop()
            engine.detach(playerNode)
            playerNodes.removeValue(forKey: id)
        }

        // ミキサーノードをデタッチ
        if let mixerNode = mixerNodes[id] {
            engine.detach(mixerNode)
            mixerNodes.removeValue(forKey: id)
        }

        audioFiles.removeValue(forKey: id)
        tracks.removeAll { $0.id == id }

        // 全体の長さを再計算
        recalculateTotalDuration()
    }

    // MARK: - トラックパラメータ制御

    /// トラックの音量を設定
    /// - Parameters:
    ///   - trackId: 対象トラックのID
    ///   - value: 音量（0〜1）
    func setVolume(trackId: UUID, value: Float) {
        guard let index = tracks.firstIndex(where: { $0.id == trackId }) else { return }
        tracks[index].volume = max(0, min(1, value))
        updateTrackAudio(trackId: trackId)
    }

    /// トラックのパンを設定
    /// - Parameters:
    ///   - trackId: 対象トラックのID
    ///   - value: パン（-1:左 〜 0:中央 〜 1:右）
    func setPan(trackId: UUID, value: Float) {
        guard let index = tracks.firstIndex(where: { $0.id == trackId }) else { return }
        tracks[index].pan = max(-1, min(1, value))
        updateTrackAudio(trackId: trackId)
    }

    /// トラックのミュートを切り替え
    func toggleMute(trackId: UUID) {
        guard let index = tracks.firstIndex(where: { $0.id == trackId }) else { return }
        tracks[index].isMuted.toggle()
        updateTrackAudio(trackId: trackId)
    }

    /// トラックのソロを切り替え
    func toggleSolo(trackId: UUID) {
        guard let index = tracks.firstIndex(where: { $0.id == trackId }) else { return }
        tracks[index].isSolo.toggle()
        // ソロ状態が変わったら全トラックのオーディオを更新
        updateAllTracksAudio()
    }

    // MARK: - オーディオ状態更新

    /// 指定トラックのオーディオ状態を更新（ミュート/ソロ/ボリューム/パン）
    private func updateTrackAudio(trackId: UUID) {
        guard let track = tracks.first(where: { $0.id == trackId }),
              let mixerNode = mixerNodes[trackId] else { return }

        let hasSoloTrack = tracks.contains { $0.isSolo }

        // ミュート判定: 明示的ミュートまたはソロトラックが存在する場合にソロでない
        let shouldMute = track.isMuted || (hasSoloTrack && !track.isSolo)
        mixerNode.outputVolume = shouldMute ? 0.0 : track.volume
        mixerNode.pan = track.pan
    }

    /// 全トラックのオーディオ状態を更新
    private func updateAllTracksAudio() {
        for track in tracks {
            updateTrackAudio(trackId: track.id)
        }
    }

    // MARK: - 再生制御

    /// 全トラックの再生を開始
    func play() {
        guard !isPlaying else { return }

        // 全トラックをスケジュールして再生
        for track in tracks {
            guard let playerNode = playerNodes[track.id],
                  let audioFile = audioFiles[track.id] else { continue }

            playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)
            playerNode.play()
        }

        isPlaying = true
        playbackStartTime = Date()
        startProgressTimer()
    }

    /// 全トラックの再生を一時停止
    func pause() {
        for (_, playerNode) in playerNodes {
            playerNode.pause()
        }
        isPlaying = false
        progressTimer?.invalidate()
    }

    /// 全トラックの再生を停止
    func stop() {
        for (_, playerNode) in playerNodes {
            playerNode.stop()
        }
        isPlaying = false
        currentTime = 0
        progressTimer?.invalidate()
        progressTimer = nil
    }

    /// 指定位置にシーク
    /// - Parameter time: シーク先の時間（秒）
    func seek(to time: TimeInterval) {
        let wasPlaying = isPlaying
        stop()
        currentTime = time

        // 各トラックを指定位置からスケジュール
        for track in tracks {
            guard let playerNode = playerNodes[track.id],
                  let audioFile = audioFiles[track.id] else { continue }

            let sampleRate = audioFile.processingFormat.sampleRate
            let startFrame = AVAudioFramePosition(time * sampleRate)
            let totalFrames = audioFile.length

            guard startFrame < totalFrames else { continue }

            let frameCount = AVAudioFrameCount(totalFrames - startFrame)
            playerNode.scheduleSegment(audioFile, startingFrame: startFrame, frameCount: frameCount, at: nil, completionHandler: nil)
        }

        if wasPlaying {
            play()
        }
    }

    // MARK: - 進捗管理

    /// 再生進捗更新タイマーを開始
    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isPlaying, let startTime = self.playbackStartTime else { return }
                let elapsed = Date().timeIntervalSince(startTime)
                self.currentTime = elapsed

                // 全トラック再生完了チェック
                if elapsed >= self.totalDuration {
                    self.stop()
                }
            }
        }
    }

    /// 全体の長さを再計算
    private func recalculateTotalDuration() {
        totalDuration = audioFiles.values.reduce(0) { maxDuration, file in
            let duration = Double(file.length) / file.processingFormat.sampleRate
            return max(maxDuration, duration)
        }
    }

    // MARK: - ミックスダウン（バウンス）

    /// 全トラックを1つのファイルにミックスダウン
    /// - Returns: ミックスダウンされたファイルのURL
    func mixdown() async throws -> URL {
        guard !tracks.isEmpty else {
            throw MultiTrackError.noTracksToMix
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("mixdown_\(Date().timeIntervalSince1970).m4a")

        // 基準フォーマットを取得
        guard let firstFile = audioFiles.values.first else {
            throw MultiTrackError.noTracksToMix
        }
        let processingFormat = firstFile.processingFormat
        let sampleRate = processingFormat.sampleRate
        let totalFrames = Int(totalDuration * sampleRate)
        let bufferSize = 4096

        // 出力ファイルを作成
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: processingFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: settings)

        // 各トラックのファイルを読み込み用にオープン
        var readFiles: [(file: AVAudioFile, track: TrackState)] = []
        for track in tracks {
            let file = try AVAudioFile(forReading: track.url)
            readFiles.append((file: file, track: track))
        }

        // ソロトラックの有無を確認
        let hasSolo = tracks.contains { $0.isSolo }

        // バッファ単位で処理
        var framesProcessed = 0
        while framesProcessed < totalFrames {
            let framesToProcess = min(bufferSize, totalFrames - framesProcessed)
            guard let mixBuffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: AVAudioFrameCount(framesToProcess)) else { break }
            mixBuffer.frameLength = AVAudioFrameCount(framesToProcess)

            // ミックスバッファをゼロクリア
            if let data = mixBuffer.floatChannelData {
                for ch in 0..<Int(processingFormat.channelCount) {
                    memset(data[ch], 0, framesToProcess * MemoryLayout<Float>.size)
                }
            }

            // 各トラックを加算
            for (readFile, track) in readFiles {
                // ミュート/ソロ判定
                let shouldMute = track.isMuted || (hasSolo && !track.isSolo)
                if shouldMute { continue }

                guard let trackBuffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: AVAudioFrameCount(framesToProcess)) else { continue }
                trackBuffer.frameLength = AVAudioFrameCount(framesToProcess)

                // ファイルの残りフレーム数を確認
                let remainingFrames = readFile.length - readFile.framePosition
                if remainingFrames <= 0 { continue }

                let readFrames = min(Int(remainingFrames), framesToProcess)
                trackBuffer.frameLength = AVAudioFrameCount(readFrames)

                do {
                    try readFile.read(into: trackBuffer, frameCount: AVAudioFrameCount(readFrames))
                } catch {
                    continue
                }

                // ボリュームを適用して加算
                if let mixData = mixBuffer.floatChannelData, let trackData = trackBuffer.floatChannelData {
                    for ch in 0..<Int(processingFormat.channelCount) {
                        for i in 0..<readFrames {
                            mixData[ch][i] += trackData[ch][i] * track.volume
                        }
                    }
                }
            }

            // 出力ファイルに書き込み
            try outputFile.write(from: mixBuffer)
            framesProcessed += framesToProcess
        }

        return outputURL
    }

    deinit {
        progressTimer?.invalidate()
    }
}

// MARK: - マルチトラックエラー

/// マルチトラックエンジンのエラー定義
enum MultiTrackError: LocalizedError {
    case noTracksToMix
    case fileReadError
    case fileWriteError

    var errorDescription: String? {
        switch self {
        case .noTracksToMix: return "ミックスするトラックがありません"
        case .fileReadError: return "オーディオファイルの読み込みに失敗しました"
        case .fileWriteError: return "オーディオファイルの書き込みに失敗しました"
        }
    }
}
