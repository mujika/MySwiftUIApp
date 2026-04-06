import Foundation
import AVFoundation
import SwiftUI

// MARK: - メインオーディオマネージャー
/// アプリのオーディオエンジンを統括管理するクラス
/// AVAudioEngineを所有し、エフェクトチェーン、録音、モニタリングを制御
/// 録音はAVAudioEngineのタップベースで実装（AVAudioRecorderは使用しない）
///
/// 信号フロー:
/// inputNode → effectsChain(inputMixer → [EQ → Comp → Dist → Delay → Reverb → NoiseGate] → outputMixer)
///           → mainMixerNode（モニタリング用）
///           → 録音タップ（effectsChain出力から取得）
@MainActor
final class AudioManager: ObservableObject {

    // MARK: - 公開プロパティ（UI連携）

    /// 録音中フラグ
    @Published var isRecording: Bool = false

    /// 録音経過時間（秒）
    @Published var recordingDuration: TimeInterval = 0

    /// 録音ファイル一覧
    @Published var recordings: [Recording] = []

    /// マイク使用許可フラグ
    @Published var hasPermission: Bool = false

    /// リアルタイム音声レベル（0〜1）
    @Published var audioLevel: Float = 0.0

    /// リアルタイム波形データ（最新100サンプル）
    @Published var waveformSamples: [Float] = Array(repeating: 0, count: 100)

    /// モニタリング（スピーカーへのパススルー）有効フラグ
    @Published var isMonitoring: Bool = false {
        didSet { updateMonitoring() }
    }

    /// 現在のエフェクトプリセット
    @Published var currentEffectsPreset: EffectsPreset = .clean {
        didSet { effectsChain.applyPreset(currentEffectsPreset) }
    }

    /// エンジンが起動しているか
    @Published var isEngineRunning: Bool = false

    // MARK: - エフェクトチェーン

    /// エフェクトチェーン（外部からアクセス可能）
    let effectsChain: EffectsChain

    // MARK: - 内部プロパティ

    /// メインオーディオエンジン
    private let audioEngine = AVAudioEngine()

    /// モニタリング制御用ミキサー
    private let monitorMixer = AVAudioMixerNode()

    /// 録音タイマー
    private var recordingTimer: Timer?

    /// 音声レベル計測タイマー
    private var levelTimer: Timer?

    /// 録音中のオーディオファイル
    private var recordingFile: AVAudioFile?

    /// 録音中のファイルURL
    private var recordingURL: URL?

    /// 録音タップがインストール済みか
    private var isRecordingTapInstalled: Bool = false

    /// レベル計測タップがインストール済みか
    private var isLevelTapInstalled: Bool = false

    /// 録音開始時刻
    private var recordingStartTime: Date?

    /// 録音保存用ディレクトリ
    private var recordingsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - 初期化

    init() {
        effectsChain = EffectsChain()
        setupAudioSession()
        setupNotifications()
        setupAudioEngineGraph()
        startEngine()
        loadRecordings()
    }

    // MARK: - オーディオセッション設定

    /// AVAudioSessionの初期設定
    /// playAndRecordカテゴリ、デフォルトスピーカー、Bluetooth許可
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
            )
            try session.setPreferredSampleRate(44100)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setPrefersNoInterruptionsFromSystemAlerts(true)
            try session.setActive(true)
        } catch {
            print("オーディオセッションの設定に失敗: \(error)")
        }
    }

    // MARK: - オーディオエンジングラフ構築

    /// AVAudioEngineのノードグラフを構築
    /// inputNode → effectsChain → monitorMixer → mainMixerNode
    private func setupAudioEngineGraph() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // エフェクトチェーンをエンジンに登録
        effectsChain.attachToEngine(audioEngine)

        // モニタリング用ミキサーを登録
        audioEngine.attach(monitorMixer)

        // 入力 → エフェクトチェーン入力
        audioEngine.connect(inputNode, to: effectsChain.getInputNode(), format: inputFormat)

        // エフェクトチェーンの内部接続を構築
        effectsChain.rebuildChain(format: inputFormat)

        // エフェクトチェーン出力 → モニタリングミキサー
        audioEngine.connect(effectsChain.getOutputNode(), to: monitorMixer, format: inputFormat)

        // モニタリングミキサー → メインミキサー
        audioEngine.connect(monitorMixer, to: audioEngine.mainMixerNode, format: inputFormat)

        // 初期状態: モニタリングOFF（音量0）
        monitorMixer.outputVolume = 0.0

        // ノイズゲートのタップを設置
        effectsChain.noiseGateEffect.installGateTap(format: inputFormat)
    }

    // MARK: - エンジン起動

    /// AVAudioEngineを起動
    private func startEngine() {
        do {
            try audioEngine.start()
            isEngineRunning = true
            // レベル計測タップを設置
            installLevelTap()
            print("オーディオエンジンを起動しました")
        } catch {
            print("オーディオエンジンの起動に失敗: \(error)")
            isEngineRunning = false
        }
    }

    // MARK: - モニタリング制御

    /// モニタリング（スピーカー出力）の有効/無効を切り替え
    private func updateMonitoring() {
        monitorMixer.outputVolume = isMonitoring ? 1.0 : 0.0
    }

    // MARK: - マイクパーミッション

    /// マイク使用許可をリクエスト
    func requestPermission() async {
        if #available(iOS 17.0, *) {
            let granted = await AVAudioApplication.requestRecordPermission()
            hasPermission = granted
        } else {
            let permission = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            hasPermission = permission
        }
    }

    // MARK: - 録音制御

    /// 録音を開始（エフェクトチェーン出力をファイルに記録）
    func startRecording() {
        guard hasPermission else {
            print("マイクの使用許可がありません")
            return
        }

        // エンジンが停止している場合は再起動
        if !audioEngine.isRunning {
            startEngine()
        }

        // 録音ファイルを作成
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        recordingURL = fileURL

        let inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)

        // M4A録音用の設定（44100Hz、ステレオ対応）
        let recordingSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: inputFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recordingFile = try AVAudioFile(forWriting: fileURL, settings: recordingSettings)
        } catch {
            print("録音ファイルの作成に失敗: \(error)")
            return
        }

        // エフェクトチェーン出力にタップを設置して録音
        installRecordingTap(format: inputFormat)

        isRecording = true
        recordingDuration = 0
        recordingStartTime = Date()

        // 録音時間タイマーを開始
        startRecordingTimer()

        print("録音を開始しました: \(fileURL.lastPathComponent)")
    }

    /// 録音を停止してファイルを保存
    func stopRecording() {
        guard isRecording else { return }

        // 録音タップを除去
        removeRecordingTap()

        recordingFile = nil
        isRecording = false
        audioLevel = 0.0
        recordingStartTime = nil

        // タイマーを停止
        stopRecordingTimer()

        // 録音一覧を更新
        loadRecordings()

        print("録音を停止しました")
    }

    // MARK: - 録音タップ管理

    /// エフェクトチェーン出力に録音用タップをインストール
    private func installRecordingTap(format: AVAudioFormat) {
        guard !isRecordingTapInstalled else { return }

        let outputNode = effectsChain.getOutputNode()
        outputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            // バッファをファイルに書き込み
            do {
                try self.recordingFile?.write(from: buffer)
            } catch {
                print("録音バッファの書き込みに失敗: \(error)")
            }
        }
        isRecordingTapInstalled = true
    }

    /// 録音タップを除去
    private func removeRecordingTap() {
        guard isRecordingTapInstalled else { return }
        effectsChain.getOutputNode().removeTap(onBus: 0)
        isRecordingTapInstalled = false
    }

    // MARK: - レベル計測タップ

    /// 入力ノードにレベル計測用タップをインストール
    private func installLevelTap() {
        guard !isLevelTapInstalled else { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        isLevelTapInstalled = true
    }

    /// レベル計測タップを除去
    private func removeLevelTap() {
        guard isLevelTapInstalled else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        isLevelTapInstalled = false
    }

    // MARK: - オーディオバッファ処理

    /// オーディオバッファからレベルと波形データを計算
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        // RMSレベルを計算
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(frameLength))
        let avgPower = 20 * log10(max(rms, 1e-10))
        let normalizedLevel = max(0, (avgPower + 80) / 80)

        // 波形サンプルを抽出（均等にダウンサンプリング）
        let sampleCount = 100
        let stride = max(1, frameLength / sampleCount)
        var newSamples = [Float]()
        for i in Swift.stride(from: 0, to: min(frameLength, sampleCount * stride), by: stride) {
            newSamples.append(channelData[i])
        }
        // サンプルが足りない場合はゼロで埋める
        while newSamples.count < sampleCount {
            newSamples.append(0)
        }

        // メインスレッドでUI更新
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = normalizedLevel
            self?.waveformSamples = Array(newSamples.prefix(sampleCount))
        }
    }

    // MARK: - 録音タイマー

    /// 録音経過時間の更新タイマーを開始
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    /// 録音タイマーを停止
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - 録音ファイル管理

    /// ドキュメントディレクトリから録音ファイル一覧を読み込み
    func loadRecordings() {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: recordingsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            recordings = files
                .filter { $0.pathExtension == "m4a" && $0.lastPathComponent.hasPrefix("recording_") }
                .compactMap { url in
                    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                          let creationDate = attributes[.creationDate] as? Date else {
                        return nil
                    }
                    return Recording(url: url, creationDate: creationDate)
                }
                .sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("録音ファイルの読み込みに失敗: \(error)")
        }
    }

    /// 指定された録音ファイルを削除
    /// - Parameter recording: 削除対象の録音
    func deleteRecording(_ recording: Recording) {
        do {
            try FileManager.default.removeItem(at: recording.url)
            loadRecordings()
        } catch {
            print("録音ファイルの削除に失敗: \(error)")
        }
    }

    // MARK: - エフェクトチェーン再構築

    /// エフェクトチェーンを再構築（エフェクト有効/無効変更時に呼び出し）
    func rebuildEffectsChain() {
        let wasRunning = audioEngine.isRunning
        if wasRunning {
            audioEngine.stop()
        }

        let format = audioEngine.inputNode.outputFormat(forBus: 0)
        effectsChain.rebuildChain(format: format)

        if wasRunning {
            do {
                try audioEngine.start()
            } catch {
                print("エフェクトチェーン再構築後のエンジン起動に失敗: \(error)")
            }
        }
    }

    // MARK: - 割り込み通知

    /// オーディオセッション割り込み通知の監視を設定
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    /// オーディオ割り込みハンドラ（電話着信等）
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        Task { @MainActor in
            switch type {
            case .began:
                // 割り込み開始: 録音中なら一時停止
                print("オーディオセッションが中断されました")
                if self.isRecording {
                    self.stopRecording()
                }
                self.isEngineRunning = false

            case .ended:
                // 割り込み終了: 可能なら再開
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

                if options.contains(.shouldResume) {
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        if !self.audioEngine.isRunning {
                            try self.audioEngine.start()
                            self.isEngineRunning = true
                            print("オーディオエンジンを再開しました")
                        }
                    } catch {
                        print("オーディオ再開に失敗: \(error)")
                    }
                }

            @unknown default:
                break
            }
        }
    }

    /// オーディオルート変更ハンドラ（ヘッドフォン抜き差し等）
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        Task { @MainActor in
            switch reason {
            case .oldDeviceUnavailable:
                // ヘッドフォンが外された場合、モニタリングを停止
                print("出力デバイスが切断されました")
                if self.isMonitoring {
                    self.isMonitoring = false
                }
            default:
                break
            }
        }
    }

    // MARK: - クリーンアップ

    deinit {
        NotificationCenter.default.removeObserver(self)
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        audioEngine.stop()
    }
}
