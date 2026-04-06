import AVFoundation
import Foundation

// MARK: - Protocol

enum ExportFormat: String, CaseIterable {
    case m4a = "M4A (AAC)"
    case wav = "WAV"
    case aiff = "AIFF"

    var fileExtension: String {
        switch self {
        case .m4a: return "m4a"
        case .wav: return "wav"
        case .aiff: return "aiff"
        }
    }

    var formatID: AudioFormatID {
        switch self {
        case .m4a: return kAudioFormatMPEG4AAC
        case .wav: return kAudioFormatLinearPCM
        case .aiff: return kAudioFormatLinearPCM
        }
    }
}

enum ExportQuality: String, CaseIterable {
    case low = "低品質"
    case medium = "標準"
    case high = "高品質"
    case max = "最高品質"

    var sampleRate: Double {
        switch self {
        case .low: return 22050
        case .medium: return 44100
        case .high: return 44100
        case .max: return 48000
        }
    }

    var bitDepth: Int {
        switch self {
        case .low: return 16
        case .medium: return 16
        case .high: return 24
        case .max: return 32
        }
    }
}

protocol AudioExporterService {
    func export(inputURL: URL, format: ExportFormat, quality: ExportQuality) async throws -> URL
}

// MARK: - Implementation

struct AVAudioExporter: AudioExporterService {
    func export(inputURL: URL, format: ExportFormat, quality: ExportQuality) async throws -> URL {
        let inputFile = try AVAudioFile(forReading: inputURL)
        let processingFormat = inputFile.processingFormat

        let outputDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let baseName = inputURL.deletingPathExtension().lastPathComponent
        let outputURL = outputDir.appendingPathComponent("\(baseName)_export.\(format.fileExtension)")

        var settings: [String: Any] = [
            AVSampleRateKey: quality.sampleRate,
            AVNumberOfChannelsKey: Int(processingFormat.channelCount),
        ]

        switch format {
        case .m4a:
            settings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC)
            settings[AVEncoderAudioQualityKey] = AVAudioQuality.high.rawValue
        case .wav, .aiff:
            settings[AVFormatIDKey] = Int(kAudioFormatLinearPCM)
            settings[AVLinearPCMBitDepthKey] = quality.bitDepth
            settings[AVLinearPCMIsFloatKey] = quality.bitDepth == 32
            settings[AVLinearPCMIsBigEndianKey] = format == .aiff
        }

        let outputFile = try AVAudioFile(forWriting: outputURL, settings: settings)

        let frameCount = AVAudioFrameCount(inputFile.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: frameCount) else {
            throw AudioError.recordingFailed(underlying: NSError(domain: "Export", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "バッファの作成に失敗"]))
        }
        try inputFile.read(into: buffer)
        try outputFile.write(from: buffer)

        return outputURL
    }
}
