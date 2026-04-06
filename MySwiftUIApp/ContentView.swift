import SwiftUI

struct ContentView: View {
    // MARK: - Dependencies (injected)

    private let recorder: AudioRecorderService
    private let levelMonitor: AudioLevelMonitor
    private let player: AudioPlayerService
    private let repository: RecordingRepository
    private let pitchDetector: PitchDetectorService
    private let metronome: MetronomeService
    private let effects: AudioEffectsService
    private let mixer: MultiTrackMixerService
    private let waveformAnalyzer: WaveformAnalyzerService
    private let exporter: AudioExporterService
    private let projectRepo: ProjectRepository

    // MARK: - ViewModels

    @State private var recorderVM: RecorderViewModel
    @State private var listVM: RecordingListViewModel
    @State private var tunerVM: TunerViewModel
    @State private var metronomeVM: MetronomeViewModel
    @State private var effectsVM: EffectsViewModel
    @State private var multiTrackVM: MultiTrackViewModel
    @State private var projectVM: ProjectListViewModel

    init(
        recorder: AudioRecorderService,
        levelMonitor: AudioLevelMonitor,
        player: AudioPlayerService,
        repository: RecordingRepository,
        pitchDetector: PitchDetectorService,
        metronome: MetronomeService,
        effects: AudioEffectsService,
        mixer: MultiTrackMixerService,
        waveformAnalyzer: WaveformAnalyzerService,
        exporter: AudioExporterService,
        projectRepo: ProjectRepository
    ) {
        self.recorder = recorder
        self.levelMonitor = levelMonitor
        self.player = player
        self.repository = repository
        self.pitchDetector = pitchDetector
        self.metronome = metronome
        self.effects = effects
        self.mixer = mixer
        self.waveformAnalyzer = waveformAnalyzer
        self.exporter = exporter
        self.projectRepo = projectRepo

        _recorderVM = State(initialValue: RecorderViewModel(
            recorder: recorder, levelMonitor: levelMonitor, repository: repository
        ))
        _listVM = State(initialValue: RecordingListViewModel(
            repository: repository, player: player
        ))
        _tunerVM = State(initialValue: TunerViewModel(pitchDetector: pitchDetector))
        _metronomeVM = State(initialValue: MetronomeViewModel(metronome: metronome))
        _effectsVM = State(initialValue: EffectsViewModel(effects: effects, repository: repository))
        _multiTrackVM = State(initialValue: MultiTrackViewModel(mixer: mixer, repository: repository))
        _projectVM = State(initialValue: ProjectListViewModel(projectRepo: projectRepo))
    }

    var body: some View {
        TabView {
            Tab("録音", systemImage: "mic.fill") {
                RecorderView(viewModel: recorderVM)
            }

            Tab("録音一覧", systemImage: "list.bullet") {
                RecordingListView(viewModel: listVM)
            }

            Tab("チューナー", systemImage: "tuningfork") {
                TunerView(viewModel: tunerVM)
            }

            Tab("メトロノーム", systemImage: "metronome") {
                MetronomeView(viewModel: metronomeVM)
            }

            Tab("エフェクト", systemImage: "wand.and.stars") {
                EffectsView(viewModel: effectsVM)
            }

            Tab("トラック", systemImage: "square.stack.3d.up") {
                MultiTrackView(viewModel: multiTrackVM)
            }

            Tab("プロジェクト", systemImage: "folder") {
                ProjectListView(viewModel: projectVM)
            }
        }
        .onChange(of: recorderVM.isRecording) { _, isRecording in
            if !isRecording {
                listVM.loadRecordings()
            }
        }
    }
}
