import Foundation
import AVFoundation

// MARK: - ループレコーダー
/// ループ録音とオーバーダビング機能を提供
/// 最初のループの長さを基準にして、最大8レイヤーまで重ねて録音可能
/// 各レイヤーはAVAudioPlayerNodeで同時再生
@MainActor
final class LoopRecorder: ObservableObject {

    // MARK: - 公開プロパティ

    /// ループ再生中か
    @Published var isLooping: Bool = false

    /// ループの長さ（秒）
    @Published var loopLength: TimeInterval = 0

    /// 録音済みレイヤーのURL一覧
    @Published var layers: [URL] = []

    /// 現在のレイヤー番号（0始まり）
    @Published var currentLayer: Int = 0

    /// オーバーダビング中か
    @Published var isOverdubbing: Bool = false

    /// 録音中か（最初のループ作成時）
    @Published var isRecordingFirstLoop: Bool = false

    /// 現在の再生位置（0〜1）
    @Published var playbackProgress: Double = 0.0

    // MARK: - 内部プロパティ

    /// 最大レイヤー数
    private let maxLayers = 8

    /// 各レイヤー用のプレイヤーノード
    private var playerNodes: [AVAudioPlayerNode] = []

    /// 各レイヤーのオーディオファイル
    private var audioFiles: [AVAudioFile?] = []

    /// ループ録音用のミキサーノード
    private let loopMixer = AVAudioMixerNode()

    /// 録音用のタップフォーマット
    private var recordingFormat: AVAudioFormat?

    /// 現在録音中のオーディオファイル
    private var currentRecordingFile: AVAudioFile?

    /// AVAudioEngineへの弱参照
    private weak var engine: AVAudioEngine?

    /// ループ再生タイマー
    private var loopTimer: Timer?

    /// ループ開始時刻
    private var loopStartTime: Date?

    /// 録音タップが設置されているか
    private var isTapInstalled: Bool = false

    /// ループ保存用ディレクトリ
    private var loopDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let loopDir = documents.appendingPathComponent("Loops", isDirectory: true)
        try? FileManager.default.createDirectory(at: loopDir, withIntermediateDirectories: true)
        return loopDir
    }

    // MARK: - 初期化

    init() {}

    // MARK: - エンジンへの接続

    /// ループレコーダーのノードをAVAudioEngineに登録
    /// - Parameter engine: 対象のAVAudioEngine
    func attachToEngine(_ engine: AVAudioEngine) {
        self.engine = engine
        engine.attach(loopMixer)

        // ミキサーをメインミキサーに接続
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        recordingFormat = format
        engine.connect(loopMixer, to: engine.mainMixerNode, format: format)
    }

    // MARK: - ループ制御

    /// 最初のループ録音を開始
    /// 入力ノードからの音声をファイルに記録し、停止時にループ長を確定
    func startLoop() {
        guard !isRecordingFirstLoop, !isLooping else { return }
        guard let engine = engine else { return }

        let format = engine.inputNode.outputFormat(forBus: 0)
        recordingFormat = format

        // 録音ファイルを作成
        let fileURL = loopDirectory.appendingPathComponent("loop_layer_0.caf")
        do {
            currentRecordingFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        } catch {
            print("ループ録音ファイルの作成に失敗: \(error)")
            return
        }

        // 入力ノードにタップを設置して録音
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            do {
                try self.currentRecordingFile?.write(from: buffer)
            } catch {
                print("ループ録音の書き込みに失敗: \(error)")
            }
        }

        isTapInstalled = true
        isRecordingFirstLoop = true
        loopStartTime = Date()
    }

    /// 最初のループ録音を停止し、ループ再生を開始
    func stopLoop() {
        guard isRecordingFirstLoop else { return }
        guard let engine = engine else { return }

        // タップを除去
        if isTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        // ループ長を確定
        if let startTime = loopStartTime {
            loopLength = Date().timeIntervalSince(startTime)
        }

        currentRecordingFile = nil
        isRecordingFirstLoop = false

        // レイヤーを登録
        let fileURL = loopDirectory.appendingPathComponent("loop_layer_0.caf")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            layers = [fileURL]
            currentLayer = 0

            // プレイヤーノードを作成してループ再生を開始
            setupPlayerNode(for: fileURL, at: 0)
            startLooping()
        }
    }

    // MARK: - オーバーダビング

    /// オーバーダビングを開始（既存ループに新しいレイヤーを重ねる）
    func startOverdub() {
        guard isLooping, !isOverdubbing else { return }
        guard layers.count < maxLayers else {
            print("最大レイヤー数（\(maxLayers)）に達しています")
            return
        }
        guard let engine = engine, let format = recordingFormat else { return }

        let layerIndex = layers.count
        let fileURL = loopDirectory.appendingPathComponent("loop_layer_\(layerIndex).caf")

        do {
            currentRecordingFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        } catch {
            print("オーバーダブ録音ファイルの作成に失敗: \(error)")
            return
        }

        // 入力からの録音タップを設置
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            do {
                try self.currentRecordingFile?.write(from: buffer)
            } catch {
                print("オーバーダブの書き込みに失敗: \(error)")
            }
        }

        isTapInstalled = true
        isOverdubbing = true
    }

    /// オーバーダビングを停止
    func stopOverdub() {
        guard isOverdubbing else { return }
        guard let engine = engine else { return }

        // タップを除去
        if isTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        currentRecordingFile = nil
        isOverdubbing = false

        // 新しいレイヤーを登録
        let layerIndex = layers.count
        let fileURL = loopDirectory.appendingPathComponent("loop_layer_\(layerIndex).caf")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            layers.append(fileURL)
            currentLayer = layerIndex

            // プレイヤーノードを作成してループに追加
            setupPlayerNode(for: fileURL, at: layerIndex)
        }
    }

    // MARK: - プレイヤーノード管理

    /// 指定URLのオーディオファイル用プレイヤーノードを作成
    private func setupPlayerNode(for url: URL, at index: Int) {
        guard let engine = engine else { return }

        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)

        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: loopMixer, format: format)

        // 配列のサイズを調整
        while playerNodes.count <= index {
            playerNodes.append(AVAudioPlayerNode())
        }
        while audioFiles.count <= index {
            audioFiles.append(nil)
        }

        playerNodes[index] = playerNode

        do {
            let audioFile = try AVAudioFile(forReading: url)
            audioFiles[index] = audioFile
        } catch {
            print("オーディオファイルの読み込みに失敗: \(error)")
        }
    }

    // MARK: - ループ再生

    /// 全レイヤーのループ再生を開始
    private func startLooping() {
        isLooping = true
        scheduleAllLayers()
        startProgressTimer()
    }

    /// 全レイヤーをスケジュールして再生
    private func scheduleAllLayers() {
        for i in 0..<layers.count {
            guard i < playerNodes.count, i < audioFiles.count else { continue }
            guard let audioFile = audioFiles[i] else { continue }
            let playerNode = playerNodes[i]

            playerNode.stop()
            playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
                // 再生完了後にループ（再スケジュール）
                DispatchQueue.main.async {
                    guard let self = self, self.isLooping else { return }
                    self.scheduleAllLayers()
                }
            }
            playerNode.play()
        }
    }

    /// 再生進捗更新タイマーを開始
    private func startProgressTimer() {
        loopTimer?.invalidate()
        loopStartTime = Date()

        loopTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isLooping, let startTime = self.loopStartTime else { return }
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = elapsed.truncatingRemainder(dividingBy: self.loopLength) / self.loopLength
                self.playbackProgress = max(0, min(1, progress))
            }
        }
    }

    // MARK: - レイヤー管理

    /// 指定レイヤーをクリア
    /// - Parameter index: クリアするレイヤーのインデックス
    func clearLayer(_ index: Int) {
        guard index >= 0 && index < layers.count else { return }

        // プレイヤーを停止
        if index < playerNodes.count {
            playerNodes[index].stop()
        }

        // ファイルを削除
        try? FileManager.default.removeItem(at: layers[index])

        // 配列から除去
        layers.remove(at: index)
        if index < audioFiles.count {
            audioFiles.remove(at: index)
        }
        if index < playerNodes.count {
            if let engine = engine {
                engine.detach(playerNodes[index])
            }
            playerNodes.remove(at: index)
        }

        // レイヤーが空になったらループを停止
        if layers.isEmpty {
            stopAll()
        }

        currentLayer = max(0, layers.count - 1)
    }

    /// 全レイヤーをクリアしてループを停止
    func clearAll() {
        stopAll()

        // 全プレイヤーをデタッチ
        for playerNode in playerNodes {
            engine?.detach(playerNode)
        }

        // 全ファイルを削除
        for url in layers {
            try? FileManager.default.removeItem(at: url)
        }

        layers.removeAll()
        playerNodes.removeAll()
        audioFiles.removeAll()
        currentLayer = 0
        loopLength = 0
        playbackProgress = 0
    }

    /// 全再生を停止
    private func stopAll() {
        isLooping = false
        isOverdubbing = false
        isRecordingFirstLoop = false

        loopTimer?.invalidate()
        loopTimer = nil

        for playerNode in playerNodes {
            playerNode.stop()
        }

        if isTapInstalled, let engine = engine {
            engine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        playbackProgress = 0
    }

    deinit {
        loopTimer?.invalidate()
    }
}
