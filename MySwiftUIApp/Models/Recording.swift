import Foundation
import AVFoundation

// MARK: - 録音フォーマット列挙型

/// 対応する録音ファイルフォーマットを定義
enum RecordingFormat: String, Codable, CaseIterable {
    case m4a
    case wav
    case mp3

    /// 表示用の名前
    var displayName: String {
        switch self {
        case .m4a: return "AAC (M4A)"
        case .wav: return "WAV"
        case .mp3: return "MP3"
        }
    }

    /// ファイル拡張子
    var fileExtension: String {
        return rawValue
    }

    /// MIMEタイプ
    var mimeType: String {
        switch self {
        case .m4a: return "audio/mp4"
        case .wav: return "audio/wav"
        case .mp3: return "audio/mpeg"
        }
    }

    /// ファイル拡張子からフォーマットを判定する
    /// - Parameter extension: ファイル拡張子文字列
    /// - Returns: 対応するRecordingFormat、不明な場合はnil
    static func from(extension ext: String) -> RecordingFormat? {
        return RecordingFormat(rawValue: ext.lowercased())
    }
}

// MARK: - 録音データモデル

/// ギター録音の全メタデータを保持するモデル
/// AudioManagerとの互換性を維持しつつ、Spotify風UIに必要な情報を網羅する
struct Recording: Identifiable, Hashable, Codable {

    // MARK: - 基本プロパティ

    /// 一意識別子
    let id: UUID

    /// 録音ファイルのURL
    let url: URL

    /// ユーザーが編集可能なファイル名
    var fileName: String

    /// 録音作成日時
    let creationDate: Date

    /// 録音の長さ（秒）
    var duration: TimeInterval

    /// ファイルサイズ（バイト）
    var fileSize: Int64

    /// 録音フォーマット
    var format: RecordingFormat

    /// サンプルレート（Hz、例: 44100, 48000）
    var sampleRate: Double

    /// チャンネル数（1=モノラル, 2=ステレオ）
    var channels: Int

    // MARK: - ユーザー操作プロパティ

    /// お気に入りフラグ
    var isFavorite: Bool

    /// タグ一覧（ジャンルや楽器など）
    var tags: [String]

    /// 所属プレイリストID（オプション）
    var playlistId: UUID?

    /// ユーザーのメモ
    var notes: String

    /// 波形表示用のキャッシュデータ（サンプル値の配列）
    var waveformData: [Float]?

    // MARK: - 計算プロパティ

    /// 表示用のフォーマット済み再生時間（MM:SS）
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 表示用のフォーマット済みファイルサイズ（KB/MB）
    var formattedFileSize: String {
        if fileSize < 1024 {
            return "\(fileSize) B"
        } else if fileSize < 1024 * 1024 {
            let kb = Double(fileSize) / 1024.0
            return String(format: "%.1f KB", kb)
        } else {
            let mb = Double(fileSize) / (1024.0 * 1024.0)
            return String(format: "%.1f MB", mb)
        }
    }

    /// 表示用の名前（fileNameが空の場合はデフォルト名を返す）
    var displayName: String {
        if fileName.isEmpty {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "録音 \(formatter.string(from: creationDate))"
        }
        return fileName
    }

    /// 既存コードとの後方互換性を維持するための計算プロパティ
    var name: String {
        return displayName
    }

    // MARK: - イニシャライザ

    /// フルイニシャライザ：全プロパティを指定
    init(
        id: UUID = UUID(),
        url: URL,
        fileName: String = "",
        creationDate: Date = Date(),
        duration: TimeInterval = 0,
        fileSize: Int64 = 0,
        format: RecordingFormat = .m4a,
        sampleRate: Double = 44100,
        channels: Int = 1,
        isFavorite: Bool = false,
        tags: [String] = [],
        playlistId: UUID? = nil,
        notes: String = "",
        waveformData: [Float]? = nil
    ) {
        self.id = id
        self.url = url
        self.fileName = fileName
        self.creationDate = creationDate
        self.duration = duration
        self.fileSize = fileSize
        self.format = format
        self.sampleRate = sampleRate
        self.channels = channels
        self.isFavorite = isFavorite
        self.tags = tags
        self.playlistId = playlistId
        self.notes = notes
        self.waveformData = waveformData
    }

    /// 簡易イニシャライザ：URLと作成日のみ（既存コードとの互換性）
    /// ファイルからメタデータを自動取得する
    init(url: URL, creationDate: Date) {
        self.id = UUID()
        self.url = url
        self.fileName = ""
        self.creationDate = creationDate
        self.duration = Recording.loadDuration(from: url)
        self.fileSize = Recording.loadFileSize(from: url)
        self.format = RecordingFormat.from(extension: url.pathExtension) ?? .m4a
        self.sampleRate = 44100
        self.channels = 1
        self.isFavorite = false
        self.tags = []
        self.playlistId = nil
        self.notes = ""
        self.waveformData = nil

        // オーディオファイルからサンプルレートとチャンネル数を読み取る
        if let audioDetails = Recording.loadAudioDetails(from: url) {
            self.sampleRate = audioDetails.sampleRate
            self.channels = audioDetails.channels
        }
    }

    // MARK: - Hashable準拠（waveformDataを除外）

    static func == (lhs: Recording, rhs: Recording) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - 静的メソッド

    /// オーディオファイルから再生時間を取得する
    /// - Parameter url: オーディオファイルのURL
    /// - Returns: 再生時間（秒）。取得失敗時は0を返す
    static func loadDuration(from url: URL) -> TimeInterval {
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)

        // 無効な値をフィルタリング
        if durationInSeconds.isNaN || durationInSeconds.isInfinite || durationInSeconds < 0 {
            return 0
        }
        return durationInSeconds
    }

    /// オーディオファイルから波形データを生成する
    /// - Parameters:
    ///   - url: オーディオファイルのURL
    ///   - samples: 生成するサンプル数（UI表示の解像度）
    /// - Returns: 正規化された振幅値の配列（0.0〜1.0）。失敗時はnil
    static func generateWaveform(from url: URL, samples: Int = 100) -> [Float]? {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            return nil
        }

        let frameCount = AVAudioFrameCount(audioFile.length)
        guard frameCount > 0 else { return nil }

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: frameCount
        ) else {
            return nil
        }

        do {
            try audioFile.read(into: buffer)
        } catch {
            print("波形データの読み込みに失敗: \(error)")
            return nil
        }

        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }

        let totalFrames = Int(buffer.frameLength)
        let samplesPerBin = max(1, totalFrames / samples)
        var waveform: [Float] = []

        for i in 0..<samples {
            let start = i * samplesPerBin
            let end = min(start + samplesPerBin, totalFrames)
            guard start < totalFrames else { break }

            // 各ビンのRMS値を計算
            var sumOfSquares: Float = 0
            for j in start..<end {
                let sample = channelData[j]
                sumOfSquares += sample * sample
            }
            let rms = sqrt(sumOfSquares / Float(end - start))
            waveform.append(rms)
        }

        // 最大値で正規化（0.0〜1.0の範囲に収める）
        guard let maxValue = waveform.max(), maxValue > 0 else {
            return waveform
        }
        return waveform.map { $0 / maxValue }
    }

    /// ファイルサイズをバイト数で取得する
    /// - Parameter url: ファイルのURL
    /// - Returns: ファイルサイズ（バイト）。取得失敗時は0
    static func loadFileSize(from url: URL) -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return 0
        }
        return size
    }

    /// オーディオファイルからサンプルレートとチャンネル数を取得する
    /// - Parameter url: オーディオファイルのURL
    /// - Returns: (sampleRate, channels) のタプル。失敗時はnil
    static func loadAudioDetails(from url: URL) -> (sampleRate: Double, channels: Int)? {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            return nil
        }
        let format = audioFile.processingFormat
        return (sampleRate: format.sampleRate, channels: Int(format.channelCount))
    }
}
