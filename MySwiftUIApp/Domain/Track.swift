import Foundation

struct Track: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let name: String
    let createdAt: Date
    var volume: Float     // 0..1
    var pan: Float        // -1 (L) .. +1 (R)
    var isMuted: Bool
    var isSolo: Bool

    init(id: UUID = UUID(), url: URL, name: String, createdAt: Date = Date(),
         volume: Float = 0.8, pan: Float = 0, isMuted: Bool = false, isSolo: Bool = false) {
        self.id = id
        self.url = url
        self.name = name
        self.createdAt = createdAt
        self.volume = volume
        self.pan = pan
        self.isMuted = isMuted
        self.isSolo = isSolo
    }
}
