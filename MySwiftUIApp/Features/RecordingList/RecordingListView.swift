import SwiftUI

struct RecordingListView: View {
    @Bindable var viewModel: RecordingListViewModel
    @State private var shareItems: [Any] = []
    @State private var isShowingShare = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    emptyState
                } else {
                    recordingList
                }
            }
            .navigationTitle("録音一覧")
        }
        .onAppear {
            viewModel.loadRecordings()
        }
        .sheet(isPresented: $isShowingShare) {
            ShareSheet(items: shareItems)
        }
        .alert(
            "エラー",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView(
            "録音がありません",
            systemImage: "waveform",
            description: Text("録音タブで録音を開始してください")
        )
    }

    private var recordingList: some View {
        List {
            ForEach(viewModel.recordings) { recording in
                RecordingRowView(
                    recording: recording,
                    isPlaying: viewModel.isPlaying(recording),
                    onTogglePlayback: { viewModel.togglePlayback(for: recording) },
                    onShare: {
                        shareItems = viewModel.shareItems(for: recording)
                        isShowingShare = true
                    },
                    onDelete: { viewModel.delete(recording) }
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.delete(viewModel.recordings[index])
                }
            }
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
