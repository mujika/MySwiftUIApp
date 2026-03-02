import Foundation

/// 録音データのドメインモデル
struct Recording: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let createdAt: Date
    let duration: TimeInterval
    let fileSize: Int64

    var displayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: createdAt)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}
