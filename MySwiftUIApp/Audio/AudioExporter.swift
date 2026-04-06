import Foundation
import AVFoundation

// MARK: - オーディオ品質設定

/// エクスポート時のオーディオ品質
enum AudioQuality: String, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case lossless

    var id: String { rawValue }

    /// 日本語表示名
    var displayName: String {
        switch self {
        case .low: return "低品質 (64kbps)"
        case .medium: return "中品質 (128kbps)"
        case .high: return "高品質 (256kbps)"
        case .lossless: return "ロスレス"
        }
    }

    /// 対応するビットレート
    var bitRate: Int {
        switch self {
        case .low: return 64000
        case .medium: return 128000
        case .high: return 256000
        case .lossless: return 320000
        }
    }

    /// エンコーダー品質
    var encoderQuality: AVAudioQuality {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .lossless: return .max
        }
    }
}

// MARK: - オーディオエクスポーター
/// 録音ファイルを各種フォーマットにエクスポートするクラス
/// WAV、M4A、MP3形式に対応し、品質選択とプログレス追跡が可能
@MainActor
final class AudioExporter: ObservableObject {

    // MARK: - 公開プロパティ

    /// エクスポート進捗（0〜1）
    @Published var exportProgress: Double = 0.0

    /// エクスポート中か
    @Published var isExporting: Bool = false

    // MARK: - エクスポートディレクトリ

    /// エクスポート先のディレクトリ
    private var exportDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportDir = documents.appendingPathComponent("Exports", isDirectory: true)
        try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        return exportDir
    }

    // MARK: - WAVエクスポート

    /// 指定URLのオーディオファイルをWAV形式にエクスポート
    /// - Parameter url: 入力オーディオファイルのURL
    /// - Returns: エクスポートされたWAVファイルのURL
    func exportToWAV(from url: URL) async throws -> URL {
        isExporting = true
        exportProgress = 0.0

        defer {
            Task { @MainActor in
                self.isExporting = false
            }
        }

        let inputFile = try AVAudioFile(forReading: url)
        let processingFormat = inputFile.processingFormat
        let totalFrames = inputFile.length

        // WAV出力ファイルの設定
        let outputURL = exportDirectory.appendingPathComponent(
            "\(url.deletingPathExtension().lastPathComponent)_export.wav"
        )

        let wavSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: processingFormat.sampleRate,
            AVNumberOfChannelsKey: processingFormat.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        let outputFile = try AVAudioFile(forWriting: outputURL, settings: wavSettings)
        let bufferSize: AVAudioFrameCount = 4096

        // バッファ単位でコピー
        var framesRead: AVAudioFramePosition = 0
        while framesRead < totalFrames {
            let framesToRead = min(bufferSize, AVAudioFrameCount(totalFrames - framesRead))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: framesToRead) else { break }

            try inputFile.read(into: buffer, frameCount: framesToRead)
            try outputFile.write(from: buffer)

            framesRead += AVAudioFramePosition(framesToRead)

            // 進捗を更新
            let progress = Double(framesRead) / Double(totalFrames)
            await MainActor.run {
                self.exportProgress = progress
            }
        }

        await MainActor.run {
            self.exportProgress = 1.0
        }
        return outputURL
    }

    // MARK: - M4Aエクスポート

    /// 指定URLのオーディオファイルをM4A形式にエクスポート
    /// - Parameters:
    ///   - url: 入力オーディオファイルのURL
    ///   - quality: 出力品質
    /// - Returns: エクスポートされたM4AファイルのURL
    func exportToM4A(from url: URL, quality: AudioQuality = .high) async throws -> URL {
        isExporting = true
        exportProgress = 0.0

        defer {
            Task { @MainActor in
                self.isExporting = false
            }
        }

        let inputFile = try AVAudioFile(forReading: url)
        let processingFormat = inputFile.processingFormat
        let totalFrames = inputFile.length

        let outputURL = exportDirectory.appendingPathComponent(
            "\(url.deletingPathExtension().lastPathComponent)_export.m4a"
        )

        let m4aSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: processingFormat.sampleRate,
            AVNumberOfChannelsKey: processingFormat.channelCount,
            AVEncoderAudioQualityKey: quality.encoderQuality.rawValue,
            AVEncoderBitRateKey: quality.bitRate
        ]

        let outputFile = try AVAudioFile(forWriting: outputURL, settings: m4aSettings)
        let bufferSize: AVAudioFrameCount = 4096

        var framesRead: AVAudioFramePosition = 0
        while framesRead < totalFrames {
            let framesToRead = min(bufferSize, AVAudioFrameCount(totalFrames - framesRead))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: framesToRead) else { break }

            try inputFile.read(into: buffer, frameCount: framesToRead)
            try outputFile.write(from: buffer)

            framesRead += AVAudioFramePosition(framesToRead)

            let progress = Double(framesRead) / Double(totalFrames)
            await MainActor.run {
                self.exportProgress = progress
            }
        }

        await MainActor.run {
            self.exportProgress = 1.0
        }
        return outputURL
    }

    // MARK: - MP3エクスポート（AVAssetExportSession使用）

    /// 指定URLのオーディオファイルをMP3互換形式にエクスポート
    /// iOSではMP3エンコードが直接サポートされないため、M4Aで代替し
    /// AVAssetExportSessionで最大互換性のフォーマットに変換
    /// - Parameter url: 入力オーディオファイルのURL
    /// - Returns: エクスポートされたファイルのURL
    func exportToMP3(from url: URL) async throws -> URL {
        isExporting = true
        exportProgress = 0.0

        defer {
            Task { @MainActor in
                self.isExporting = false
            }
        }

        let asset = AVAsset(url: url)
        let outputURL = exportDirectory.appendingPathComponent(
            "\(url.deletingPathExtension().lastPathComponent)_export.m4a"
        )

        // 既存ファイルがあれば削除
        try? FileManager.default.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw AudioExportError.exportSessionCreationFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        // 進捗を監視
        let progressTask = Task {
            while !Task.isCancelled {
                let progress = Double(exportSession.progress)
                await MainActor.run {
                    self.exportProgress = progress
                }
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒ごとに更新
            }
        }

        // エクスポートを実行
        await exportSession.export()
        progressTask.cancel()

        switch exportSession.status {
        case .completed:
            await MainActor.run {
                self.exportProgress = 1.0
            }
            return outputURL
        case .failed:
            throw exportSession.error ?? AudioExportError.exportFailed
        case .cancelled:
            throw AudioExportError.exportCancelled
        default:
            throw AudioExportError.exportFailed
        }
    }
}

// MARK: - エクスポートエラー

/// オーディオエクスポートのエラー定義
enum AudioExportError: LocalizedError {
    case exportSessionCreationFailed
    case exportFailed
    case exportCancelled
    case invalidInputFile

    var errorDescription: String? {
        switch self {
        case .exportSessionCreationFailed: return "エクスポートセッションの作成に失敗しました"
        case .exportFailed: return "エクスポートに失敗しました"
        case .exportCancelled: return "エクスポートがキャンセルされました"
        case .invalidInputFile: return "入力ファイルが無効です"
        }
    }
}
