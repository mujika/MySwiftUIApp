import Foundation
import AVFoundation
import Accelerate

// MARK: - ギターチューナー
/// FFTベースのピッチ検出を使用したギターチューナー
/// Accelerateフレームワーク（vDSP）による高速FFTと自己相関でピッチを検出
/// 標準チューニング: E2(82.41), A2(110), D3(146.83), G3(196), B3(246.94), E4(329.63)
@MainActor
final class Tuner: ObservableObject {

    // MARK: - 公開プロパティ

    /// 検出された周波数（Hz）
    @Published var detectedFrequency: Float = 0.0

    /// 検出された音名（例: "A4", "E2"）
    @Published var detectedNote: String = "-"

    /// ピッチのずれ（-50〜+50 セント）
    @Published var centsOffset: Float = 0.0

    /// チューニングが合っているか（±5セント以内）
    @Published var isInTune: Bool = false

    /// 検出されたオクターブ
    @Published var octave: Int = 0

    /// チューナーが動作中か
    @Published var isActive: Bool = false

    // MARK: - ギター標準チューニング参照周波数

    /// ギターの各弦の標準チューニング周波数
    static let guitarStrings: [(name: String, frequency: Float)] = [
        ("E2", 82.41),
        ("A2", 110.00),
        ("D3", 146.83),
        ("G3", 196.00),
        ("B3", 246.94),
        ("E4", 329.63)
    ]

    // MARK: - 内部プロパティ

    /// オーディオエンジンへの弱参照
    private weak var engine: AVAudioEngine?

    /// FFTサイズ（精度とレイテンシーのバランス）
    private let fftSize: Int = 4096

    /// FFTセットアップ（Accelerateフレームワーク）
    private var fftSetup: vDSP_DFT_Setup?

    /// サンプルバッファ（FFT用に蓄積）
    private var sampleBuffer: [Float] = []

    /// サンプルレート
    private var sampleRate: Float = 44100.0

    /// タップがインストール済みか
    private var isTapInstalled: Bool = false

    /// 音名定義（半音階）
    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// A4の基準周波数（Hz）
    private let referenceA4: Float = 440.0

    // MARK: - 初期化

    init() {
        // vDSP DFTセットアップを作成
        fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            .FORWARD
        )
    }

    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }

    // MARK: - チューナー制御

    /// チューナーを開始
    /// - Parameter engine: 使用するAVAudioEngine
    func start(engine: AVAudioEngine) {
        guard !isActive else { return }

        self.engine = engine
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        sampleRate = Float(format.sampleRate)
        sampleBuffer = [Float](repeating: 0, count: fftSize)

        // 入力ノードにタップを設置してピッチ検出
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fftSize), format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        isTapInstalled = true
        isActive = true
    }

    /// チューナーを停止
    func stop() {
        guard isActive, let engine = engine else { return }

        if isTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        isActive = false
        detectedFrequency = 0.0
        detectedNote = "-"
        centsOffset = 0.0
        isInTune = false
    }

    // MARK: - バッファ処理

    /// オーディオバッファからピッチを検出
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        // サンプルバッファに追加
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))

        // 十分なサンプルが溜まったらピッチ検出を実行
        let analysisSamples: [Float]
        if samples.count >= fftSize {
            analysisSamples = Array(samples.prefix(fftSize))
        } else {
            // バッファが小さい場合はゼロパディング
            analysisSamples = samples + [Float](repeating: 0, count: fftSize - samples.count)
        }

        // 自己相関法でピッチ検出
        let frequency = detectPitchAutocorrelation(analysisSamples)

        // メインスレッドでUI更新
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if frequency > 60.0 && frequency < 1200.0 {
                // ギターの音域内の場合のみ更新
                self.detectedFrequency = frequency
                self.updateNoteInfo(frequency: frequency)
            }
        }
    }

    // MARK: - 自己相関法によるピッチ検出

    /// 自己相関（Autocorrelation）を使用してピッチを検出
    /// - Parameter samples: 分析対象のサンプル配列
    /// - Returns: 検出された基本周波数（Hz）
    private func detectPitchAutocorrelation(_ samples: [Float]) -> Float {
        let n = samples.count

        // ハミング窓を適用
        var windowedSamples = [Float](repeating: 0, count: n)
        var window = [Float](repeating: 0, count: n)
        vDSP_hamm_window(&window, vDSP_Length(n), 0)
        vDSP_vmul(samples, 1, window, 1, &windowedSamples, 1, vDSP_Length(n))

        // 入力のRMSを確認（無音判定）
        var rms: Float = 0
        vDSP_rmsqv(windowedSamples, 1, &rms, vDSP_Length(n))
        guard rms > 0.01 else { return 0.0 }

        // 自己相関を計算（FFTベースで高速化）
        let correlationSize = n * 2
        var paddedSignal = windowedSamples + [Float](repeating: 0, count: n)
        var correlation = [Float](repeating: 0, count: correlationSize)

        // vDSPで畳み込みを使用して自己相関を計算
        vDSP_conv(paddedSignal, 1, windowedSamples, 1, &correlation, 1,
                  vDSP_Length(n), vDSP_Length(n))

        // ギターの音域に対応するラグ範囲を設定
        // 最低周波数 60Hz → 最大ラグ = sampleRate / 60
        // 最高周波数 1200Hz → 最小ラグ = sampleRate / 1200
        let minLag = Int(sampleRate / 1200.0)
        let maxLag = min(Int(sampleRate / 60.0), n - 1)

        guard minLag < maxLag else { return 0.0 }

        // 正規化された自己相関からピークを検出
        let zeroLagCorrelation = correlation[0]
        guard zeroLagCorrelation > 0 else { return 0.0 }

        var bestLag = minLag
        var bestCorrelation: Float = 0.0

        for lag in minLag..<maxLag {
            let normalizedCorrelation = correlation[lag] / zeroLagCorrelation
            if normalizedCorrelation > bestCorrelation {
                bestCorrelation = normalizedCorrelation
                bestLag = lag
            }
        }

        // 相関が十分に高い場合のみピッチとして採用
        guard bestCorrelation > 0.3 else { return 0.0 }

        // 放物線補間でサブサンプル精度を向上
        let refinedLag = parabolicInterpolation(correlation: correlation, peak: bestLag, maxIndex: n - 1)

        return sampleRate / refinedLag
    }

    // MARK: - 放物線補間

    /// ピーク付近の3点から放物線補間でより正確なラグを算出
    private func parabolicInterpolation(correlation: [Float], peak: Int, maxIndex: Int) -> Float {
        guard peak > 0 && peak < maxIndex else { return Float(peak) }

        let alpha = correlation[peak - 1]
        let beta = correlation[peak]
        let gamma = correlation[peak + 1]

        let denominator = alpha - 2.0 * beta + gamma
        guard abs(denominator) > 1e-10 else { return Float(peak) }

        let adjustment = 0.5 * (alpha - gamma) / denominator
        return Float(peak) + adjustment
    }

    // MARK: - 音名情報の更新

    /// 検出された周波数から音名、オクターブ、セントオフセットを計算
    private func updateNoteInfo(frequency: Float) {
        // A4=440Hzからの半音数を計算
        let halfStepsFromA4 = 12.0 * log2(frequency / referenceA4)
        let roundedHalfSteps = roundf(halfStepsFromA4)

        // セントオフセットを計算（四捨五入した半音からのずれ）
        let centsOff = (halfStepsFromA4 - roundedHalfSteps) * 100.0
        centsOffset = centsOff

        // チューニングの精度を判定（±5セント以内で合格）
        isInTune = abs(centsOff) <= 5.0

        // 音名とオクターブを計算
        // A4 = MIDI番号69、C0 = MIDI番号12
        let midiNumber = Int(roundedHalfSteps) + 69
        let noteIndex = ((midiNumber % 12) + 12) % 12
        let noteOctave = (midiNumber / 12) - 1

        detectedNote = "\(noteNames[noteIndex])\(noteOctave)"
        octave = noteOctave
    }

    // MARK: - 最も近いギター弦を取得

    /// 検出された周波数に最も近いギター弦の情報を返す
    /// - Returns: 弦名と周波数のタプル（nilの場合は検出なし）
    func closestGuitarString() -> (name: String, frequency: Float)? {
        guard detectedFrequency > 0 else { return nil }

        return Self.guitarStrings.min { a, b in
            abs(log2(a.frequency / detectedFrequency)) < abs(log2(b.frequency / detectedFrequency))
        }
    }
}
