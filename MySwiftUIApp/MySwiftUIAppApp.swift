import SwiftUI

@main
struct MySwiftUIAppApp: App {
    // Composition Root: 依存関係をここで1箇所だけ組み立てる
    private let recorder: AudioRecorderService = AVAudioRecorderService()
    private let levelMonitor: AudioLevelMonitor = AVAudioLevelMonitor()
    private let player: AudioPlayerService = AVAudioPlayerService()
    private let repository: RecordingRepository = FileSystemRecordingRepository()

    var body: some Scene {
        WindowGroup {
            ContentView(
                recorder: recorder,
                levelMonitor: levelMonitor,
                player: player,
                repository: repository
            )
        }
    }
}
