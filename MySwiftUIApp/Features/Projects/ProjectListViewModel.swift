import Foundation
import Observation

@Observable
@MainActor
final class ProjectListViewModel {
    private let projectRepo: ProjectRepository

    private(set) var projects: [Project] = []
    private(set) var errorMessage: String?
    var searchText = ""

    var filteredProjects: [Project] {
        guard !searchText.isEmpty else { return projects }
        let query = searchText.lowercased()
        return projects.filter {
            $0.name.lowercased().contains(query) ||
            $0.tags.contains { $0.lowercased().contains(query) }
        }
    }

    var isEmpty: Bool { filteredProjects.isEmpty }

    init(projectRepo: ProjectRepository) {
        self.projectRepo = projectRepo
    }

    func loadProjects() {
        do {
            projects = try projectRepo.fetchAll()
        } catch {
            errorMessage = "プロジェクトの読み込みに失敗しました"
        }
    }

    func createProject(name: String, tags: [String] = []) {
        let project = Project(name: name, tags: tags)
        do {
            try projectRepo.save(project)
            loadProjects()
        } catch {
            errorMessage = "プロジェクトの作成に失敗しました"
        }
    }

    func deleteProject(_ project: Project) {
        do {
            try projectRepo.delete(project)
            projects.removeAll { $0.id == project.id }
        } catch {
            errorMessage = "削除に失敗しました"
        }
    }

    func renameProject(_ project: Project, newName: String) {
        var updated = project
        updated.name = newName
        updated.updatedAt = Date()
        do {
            try projectRepo.save(updated)
            loadProjects()
        } catch {
            errorMessage = "名前の変更に失敗しました"
        }
    }

    func updateTags(_ project: Project, tags: [String]) {
        var updated = project
        updated.tags = tags
        updated.updatedAt = Date()
        do {
            try projectRepo.save(updated)
            loadProjects()
        } catch {
            errorMessage = "タグの更新に失敗しました"
        }
    }

    func addRecording(_ recording: Recording, to project: Project) {
        do {
            try projectRepo.addRecording(recording, to: project)
            loadProjects()
        } catch {
            errorMessage = "録音の追加に失敗しました"
        }
    }

    func dismissError() { errorMessage = nil }
}
