import SwiftUI

@main
struct MySwiftUIAppApp: App {
    // MARK: - Composition Root

    // Core Audio
    private let recorder: AudioRecorderService = AVAudioRecorderService()
    private let levelMonitor: AudioLevelMonitor = AVAudioLevelMonitor()
    private let player: AudioPlayerService = AVAudioPlayerService()
    private let pitchDetector: PitchDetectorService = FFTPitchDetector()
    private let metronome: MetronomeService = AudioEngineMetronome()
    private let effects: AudioEffectsService = AVAudioEffectsProcessor()
    private let mixer: MultiTrackMixerService = AVMultiTrackMixer()
    private let waveformAnalyzer: WaveformAnalyzerService = AVWaveformAnalyzer()
    private let exporter: AudioExporterService = AVAudioExporter()
    private let spectrogram: SpectrogramService = AccelerateSpectrogram()

    // Motion
    private let motionControl: MotionControlService = CMMotionController()

    // Storage
    private let repository: RecordingRepository = FileSystemRecordingRepository()
    private let projectRepo: ProjectRepository = FileSystemProjectRepository()

    var body: some Scene {
        WindowGroup {
            ContentView(
                recorder: recorder,
                levelMonitor: levelMonitor,
                player: player,
                repository: repository,
                pitchDetector: pitchDetector,
                metronome: metronome,
                effects: effects,
                mixer: mixer,
                waveformAnalyzer: waveformAnalyzer,
                exporter: exporter,
                projectRepo: projectRepo,
                spectrogram: spectrogram,
                motionControl: motionControl
            )
        }
    }
}
