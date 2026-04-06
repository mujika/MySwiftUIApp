import Foundation

// MARK: - Protocol

protocol ProjectRepository {
    func fetchAll() throws -> [Project]
    func save(_ project: Project) throws
    func delete(_ project: Project) throws
    func addRecording(_ recording: Recording, to project: Project) throws
    func removeRecording(fileName: String, from project: Project) throws
}

// MARK: - Implementation

struct FileSystemProjectRepository: ProjectRepository {
    private let fileManager = FileManager.default

    private var projectsDirectory: URL {
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Projects", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func fetchAll() throws -> [Project] {
        let dirs = try fileManager.contentsOfDirectory(
            at: projectsDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ).filter { $0.hasDirectoryPath }

        return dirs.compactMap { dir -> Project? in
            let metaURL = dir.appendingPathComponent("project.json")
            guard let data = try? Data(contentsOf: metaURL),
                  let project = try? JSONDecoder().decode(Project.self, from: data) else {
                return nil
            }
            return project
        }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ project: Project) throws {
        let dir = projectsDirectory.appendingPathComponent(project.id.uuidString, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        let data = try JSONEncoder().encode(project)
        try data.write(to: dir.appendingPathComponent("project.json"))
    }

    func delete(_ project: Project) throws {
        let dir = projectsDirectory.appendingPathComponent(project.id.uuidString)
        try fileManager.removeItem(at: dir)
    }

    func addRecording(_ recording: Recording, to project: Project) throws {
        let dir = projectsDirectory.appendingPathComponent(project.id.uuidString, isDirectory: true)
        let destURL = dir.appendingPathComponent(recording.url.lastPathComponent)
        try fileManager.copyItem(at: recording.url, to: destURL)

        var updated = project
        updated.recordingFileNames.append(recording.url.lastPathComponent)
        updated.updatedAt = Date()
        try save(updated)
    }

    func removeRecording(fileName: String, from project: Project) throws {
        let dir = projectsDirectory.appendingPathComponent(project.id.uuidString)
        let fileURL = dir.appendingPathComponent(fileName)
        try fileManager.removeItem(at: fileURL)

        var updated = project
        updated.recordingFileNames.removeAll { $0 == fileName }
        updated.updatedAt = Date()
        try save(updated)
    }
}
