import Foundation
import AVFoundation
import Accelerate

// MARK: - オーディオエディター
/// 非破壊的なオーディオ編集操作を提供するクラス
/// トリム、フェードイン/アウト、ノーマライズ、マージの基本操作をサポート
/// 全操作は新しいファイルを作成し、元のファイルを変更しない
@MainActor
final class AudioEditor: ObservableObject {

    // MARK: - 公開プロパティ

    /// 編集処理の進捗（0〜1）
    @Published var editProgress: Double = 0.0

    /// 処理中か
    @Published var isProcessing: Bool = false

    // MARK: - 出力ディレクトリ

    /// 編集済みファイルの保存先
    private var editDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let editDir = documents.appendingPathComponent("Edits", isDirectory: true)
        try? FileManager.default.createDirectory(at: editDir, withIntermediateDirectories: true)
        return editDir
    }

    // MARK: - トリム

    /// オーディオファイルの指定区間を切り出し
    /// - Parameters:
    ///   - url: 入力ファイルのURL
    ///   - start: 開始時間（秒）
    ///   - end: 終了時間（秒）
    /// - Returns: トリムされたファイルのURL
    func trim(url: URL, start: TimeInterval, end: TimeInterval) async throws -> URL {
        isProcessing = true
        editProgress = 0.0

        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }

        let inputFile = try AVAudioFile(forReading: url)
        let processingFormat = inputFile.processingFormat
        let sampleRate = processingFormat.sampleRate

        // フレーム位置を計算
        let startFrame = AVAudioFramePosition(start * sampleRate)
        let endFrame = min(AVAudioFramePosition(end * sampleRate), inputFile.length)
        let totalFrames = endFrame - startFrame

        guard totalFrames > 0 else {
            throw AudioEditError.invalidRange
        }

        // 出力ファイルを作成
        let outputURL = editDirectory.appendingPathComponent(
            "\(url.deletingPathExtension().lastPathComponent)_trimmed.m4a"
        )
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: processingFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputSettings)

        // 入力ファイルの読み取り位置を開始フレームに設定
        inputFile.framePosition = startFrame

        let bufferSize: AVAudioFrameCount = 4096
        var framesProcessed: AVAudioFramePosition = 0

        while framesProcessed < totalFrames {
            let framesToRead = min(bufferSize, AVAudioFrameCount(totalFrames - framesProcessed))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: framesToRead) else { break }

            try inputFile.read(into: buffer, frameCount: framesToRead)
            try outputFile.write(from: buffer)

            framesProcessed += AVAudioFramePosition(framesToRead)

            let progress = Double(framesProcessed) / Double(totalFrames)
            await MainActor.run { self.editProgress = progress }
        }

        await MainActor.run { self.editProgress = 1.0 }
        return outputURL
    }

    // MARK: - フェードイン

    /// オーディオファイルの先頭にフェードインを適用
    /// - Parameters:
    ///   - url: 入力ファイルのURL
    ///   - duration: フェードインの長さ（秒）
    /// - Returns: フェードイン適用済みファイルのURL
    func fadeIn(url: URL, duration: TimeInterval) async throws -> URL {
        isProcessing = true
        editProgress = 0.0

        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }

        let inputFile = try AVAudioFile(forReading: url)
        let processingFormat = inputFile.processingFormat
        let sampleRate = processingFormat.sampleRate
        let totalFrames = inputFile.length
        let fadeFrames = AVAudioFramePosition(duration * sampleRate)

        let outputURL = editDirectory.appendingPathComponent(
            "\(url.deletingPathExtension().lastPathComponent)_fadein.m4a"
        )
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: processingFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputSettings)

        let bufferSize: AVAudioFrameCount = 4096
        var framesProcessed: AVAudioFramePosition = 0

        while framesProcessed < totalFrames {
            let framesToRead = min(bufferSize, AVAudioFrameCount(totalFrames - framesProcessed))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: framesToRead) else { break }

            try inputFile.read(into: buffer, frameCount: framesToRead)

            // フェード区間内のサンプルにゲインを適用
            if framesProcessed < fadeFrames {
                applyFade(to: buffer, startFrame: framesProcessed, fadeLength: fadeFrames, isFadeIn: true)
            }

            try outputFile.write(from: buffer)

            framesProcessed += AVAudioFramePosition(framesToRead)
            let progress = Double(framesProcessed) / Double(totalFrames)
            await MainActor.run { self.editProgress = progress }
        }

        await MainActor.run { self.editProgress = 1.0 }
        return outputURL
    }

    // MARK: - フェードアウト

    /// オーディオファイルの末尾にフェードアウトを適用
    /// - Parameters:
    ///   - url: 入力ファイルのURL
    ///   - duration: フェードアウトの長さ（秒）
    /// - Returns: フェードアウト適用済みファイルのURL
    func fadeOut(url: URL, duration: TimeInterval) async throws -> URL {
        isProcessing = true
        editProgress = 0.0

        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }

        let inputFile = try AVAudioFile(forReading: url)
        let processingFormat = inputFile.processingFormat
        let sampleRate = processingFormat.sampleRate
        let totalFrames = inputFile.length
        let fadeFrames = AVAudioFramePosition(duration * sampleRate)
        let fadeStartFrame = totalFrames - fadeFrames

        let outputURL = editDirectory.appendingPathComponent(
            "\(url.deletingPathExtension().lastPathComponent)_fadeout.m4a"
        )
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: processingFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputSettings)

        let bufferSize: AVAudioFrameCount = 4096
        var framesProcessed: AVAudioFramePosition = 0

        while framesProcessed < totalFrames {
            let framesToRead = min(bufferSize, AVAudioFrameCount(totalFrames - framesProcessed))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: framesToRead) else { break }

            try inputFile.read(into: buffer, frameCount: framesToRead)

            // フェードアウト区間のサンプルにゲインを適用
            if framesProcessed + AVAudioFramePosition(framesToRead) > fadeStartFrame {
                let offsetFromFadeStart = framesProcessed - fadeStartFrame
                applyFade(to: buffer, startFrame: max(0, offsetFromFadeStart), fadeLength: fadeFrames, isFadeIn: false)
            }

            try outputFile.write(from: buffer)

            framesProcessed += AVAudioFramePosition(framesToRead)
            let progress = Double(framesProcessed) / Double(totalFrames)
            await MainActor.run { self.editProgress = progress }
        }

        await MainActor.run { self.editProgress = 1.0 }
        return outputURL
    }

    // MARK: - ノーマライズ

    /// オーディオファイルの音量を正規化（ピーク値を0dBに）
    /// - Parameter url: 入力ファイルのURL
    /// - Returns: ノーマライズ済みファイルのURL
    func normalize(url: URL) async throws -> URL {
        isProcessing = true
        editProgress = 0.0

        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }

        // 第1パス: ピーク値を検出
        let inputFile = try AVAudioFile(forReading: url)
        let processingFormat = inputFile.processingFormat
        let sampleRate = processingFormat.sampleRate
        let totalFrames = inputFile.length
        let bufferSize: AVAudioFrameCount = 4096

        var peakLevel: Float = 0.0
        var framesProcessed: AVAudioFramePosition = 0

        while framesProcessed < totalFrames {
            let framesToRead = min(bufferSize, AVAudioFrameCount(totalFrames - framesProcessed))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: framesToRead) else { break }

            try inputFile.read(into: buffer, frameCount: framesToRead)

            // 各チャンネルのピーク値を検出
            if let channelData = buffer.floatChannelData {
                for ch in 0..<Int(processingFormat.channelCount) {
                    var channelPeak: Float = 0
                    vDSP_maxmgv(channelData[ch], 1, &channelPeak, vDSP_Length(framesToRead))
                    peakLevel = max(peakLevel, channelPeak)
                }
            }

            framesProcessed += AVAudioFramePosition(framesToRead)
            let progress = Double(framesProcessed) / Double(totalFrames) * 0.5
            await MainActor.run { self.editProgress = progress }
        }

        // ノーマライズゲインを計算
        guard peakLevel > 0 else {
            throw AudioEditError.silentFile
        }
        let normalizeGain = 1.0 / peakLevel

        // 第2パス: ゲインを適用して書き出し
        let inputFile2 = try AVAudioFile(forReading: url)
        let outputURL = editDirectory.appendingPathComponent(
            "\(url.deletingPathExtension().lastPathComponent)_normalized.m4a"
        )
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: processingFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputSettings)

        framesProcessed = 0
        while framesProcessed < totalFrames {
            let framesToRead = min(bufferSize, AVAudioFrameCount(totalFrames - framesProcessed))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: framesToRead) else { break }

            try inputFile2.read(into: buffer, frameCount: framesToRead)

            // ゲインを適用
            if let channelData = buffer.floatChannelData {
                for ch in 0..<Int(processingFormat.channelCount) {
                    var gain = normalizeGain
                    vDSP_vsmul(channelData[ch], 1, &gain, channelData[ch], 1, vDSP_Length(framesToRead))
                }
            }

            try outputFile.write(from: buffer)

            framesProcessed += AVAudioFramePosition(framesToRead)
            let progress = 0.5 + Double(framesProcessed) / Double(totalFrames) * 0.5
            await MainActor.run { self.editProgress = progress }
        }

        await MainActor.run { self.editProgress = 1.0 }
        return outputURL
    }

    // MARK: - マージ

    /// 複数のオーディオファイルを連結して1つのファイルにマージ
    /// - Parameter urls: 入力ファイルのURL配列
    /// - Returns: マージ済みファイルのURL
    func merge(urls: [URL]) async throws -> URL {
        guard !urls.isEmpty else {
            throw AudioEditError.noFilesToMerge
        }

        isProcessing = true
        editProgress = 0.0

        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }

        // 最初のファイルからフォーマット情報を取得
        let firstFile = try AVAudioFile(forReading: urls[0])
        let processingFormat = firstFile.processingFormat
        let sampleRate = processingFormat.sampleRate

        // 全ファイルの合計フレーム数を計算
        var totalFrames: AVAudioFramePosition = 0
        for url in urls {
            let file = try AVAudioFile(forReading: url)
            totalFrames += file.length
        }

        let outputURL = editDirectory.appendingPathComponent(
            "merged_\(Date().timeIntervalSince1970).m4a"
        )
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: processingFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputSettings)

        let bufferSize: AVAudioFrameCount = 4096
        var globalFramesProcessed: AVAudioFramePosition = 0

        // 各ファイルを順番にコピー
        for url in urls {
            let inputFile = try AVAudioFile(forReading: url)
            let fileLength = inputFile.length
            var fileFramesProcessed: AVAudioFramePosition = 0

            while fileFramesProcessed < fileLength {
                let framesToRead = min(bufferSize, AVAudioFrameCount(fileLength - fileFramesProcessed))
                guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: framesToRead) else { break }

                try inputFile.read(into: buffer, frameCount: framesToRead)
                try outputFile.write(from: buffer)

                fileFramesProcessed += AVAudioFramePosition(framesToRead)
                globalFramesProcessed += AVAudioFramePosition(framesToRead)

                let progress = Double(globalFramesProcessed) / Double(totalFrames)
                await MainActor.run { self.editProgress = progress }
            }
        }

        await MainActor.run { self.editProgress = 1.0 }
        return outputURL
    }

    // MARK: - フェード適用ヘルパー

    /// バッファにフェードゲインを適用
    /// - Parameters:
    ///   - buffer: 対象のPCMバッファ
    ///   - startFrame: フェード開始位置からのオフセット
    ///   - fadeLength: フェードの全長（フレーム数）
    ///   - isFadeIn: trueならフェードイン、falseならフェードアウト
    private func applyFade(to buffer: AVAudioPCMBuffer, startFrame: AVAudioFramePosition, fadeLength: AVAudioFramePosition, isFadeIn: Bool) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        for i in 0..<frameCount {
            let globalFrame = startFrame + AVAudioFramePosition(i)
            guard globalFrame >= 0 && globalFrame < fadeLength else { continue }

            // リニアフェードゲインを計算
            let fraction = Float(globalFrame) / Float(fadeLength)
            let gain: Float = isFadeIn ? fraction : (1.0 - fraction)

            for ch in 0..<channelCount {
                channelData[ch][i] *= gain
            }
        }
    }
}

// MARK: - オーディオ編集エラー

/// オーディオ編集操作のエラー定義
enum AudioEditError: LocalizedError {
    case invalidRange
    case silentFile
    case noFilesToMerge
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidRange: return "指定された範囲が無効です"
        case .silentFile: return "ファイルが無音です"
        case .noFilesToMerge: return "マージするファイルがありません"
        case .processingFailed: return "音声処理に失敗しました"
        }
    }
}
