import SwiftUI

struct ContentView: View {
    @State private var recorderVM: RecorderViewModel
    @State private var listVM: RecordingListViewModel

    init(
        recorder: AudioRecorderService,
        levelMonitor: AudioLevelMonitor,
        player: AudioPlayerService,
        repository: RecordingRepository
    ) {
        _recorderVM = State(initialValue: RecorderViewModel(
            recorder: recorder,
            levelMonitor: levelMonitor,
            repository: repository
        ))
        _listVM = State(initialValue: RecordingListViewModel(
            repository: repository,
            player: player
        ))
    }

    var body: some View {
        TabView {
            Tab("録音", systemImage: "mic.fill") {
                RecorderView(viewModel: recorderVM)
            }

            Tab("録音一覧", systemImage: "list.bullet") {
                RecordingListView(viewModel: listVM)
            }
        }
        .onChange(of: recorderVM.isRecording) { _, isRecording in
            if !isRecording {
                listVM.loadRecordings()
            }
        }
    }
}
