import SwiftUI

struct ProjectListView: View {
    @Bindable var viewModel: ProjectListViewModel
    @State private var isShowingNewProject = false
    @State private var newProjectName = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty && viewModel.searchText.isEmpty {
                    ContentUnavailableView(
                        "プロジェクトがありません",
                        systemImage: "folder",
                        description: Text("新しいプロジェクトを作成して録音を整理しましょう")
                    )
                } else if viewModel.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                } else {
                    projectList
                }
            }
            .navigationTitle("プロジェクト")
            .searchable(text: $viewModel.searchText, prompt: "プロジェクト名・タグで検索")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isShowingNewProject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear { viewModel.loadProjects() }
            .alert("新しいプロジェクト", isPresented: $isShowingNewProject) {
                TextField("プロジェクト名", text: $newProjectName)
                Button("作成") {
                    if !newProjectName.isEmpty {
                        viewModel.createProject(name: newProjectName)
                        newProjectName = ""
                    }
                }
                Button("キャンセル", role: .cancel) { newProjectName = "" }
            }
            .alert("エラー", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var projectList: some View {
        List {
            ForEach(viewModel.filteredProjects) { project in
                ProjectRow(project: project)
            }
            .onDelete { indexSet in
                for i in indexSet {
                    viewModel.deleteProject(viewModel.filteredProjects[i])
                }
            }
        }
    }
}

// MARK: - Project Row

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                Text(project.name)
                    .font(.headline)
            }

            HStack(spacing: 12) {
                Label("\(project.recordingFileNames.count)件", systemImage: "waveform")
                Label(formattedDate, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !project.tags.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(project.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: project.updatedAt)
    }
}

// MARK: - Simple Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
