import Foundation
import AVFoundation
import SwiftUI

@MainActor
class AudioPlayerManager: NSObject, ObservableObject {
    @Published var playingRecording: Recording?
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    
    func playRecording(_ recording: Recording) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            playingRecording = recording
            isPlaying = true
        } catch {
            print("再生に失敗: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingRecording = nil
        isPlaying = false
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.playingRecording = nil
            self.audioPlayer = nil
            self.isPlaying = false
        }
    }
}
