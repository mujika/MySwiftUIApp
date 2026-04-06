import Foundation

struct Project: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date
    var recordingFileNames: [String]  // File names in project folder

    init(id: UUID = UUID(), name: String, tags: [String] = [],
         createdAt: Date = Date(), updatedAt: Date = Date(), recordingFileNames: [String] = []) {
        self.id = id
        self.name = name
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.recordingFileNames = recordingFileNames
    }
}
