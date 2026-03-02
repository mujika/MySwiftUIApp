import AVFoundation
import Foundation

// MARK: - Protocol

protocol RecordingRepository {
    func fetchAll() throws -> [Recording]
    func delete(_ recording: Recording) throws
}

// MARK: - Implementation

struct FileSystemRecordingRepository: RecordingRepository {
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func fetchAll() throws -> [Recording] {
        let files = try fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        )

        return files
            .filter { $0.pathExtension == "m4a" }
            .compactMap { url -> Recording? in
                guard let attrs = try? fileManager.attributesOfItem(atPath: url.path) else {
                    return nil
                }
                let createdAt = (attrs[.creationDate] as? Date) ?? Date()
                let fileSize = (attrs[.size] as? Int64) ?? 0
                let duration = Self.audioDuration(of: url)

                return Recording(
                    id: UUID(),
                    url: url,
                    createdAt: createdAt,
                    duration: duration,
                    fileSize: fileSize
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func delete(_ recording: Recording) throws {
        try fileManager.removeItem(at: recording.url)
    }

    private static func audioDuration(of url: URL) -> TimeInterval {
        let asset = AVURLAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
}
