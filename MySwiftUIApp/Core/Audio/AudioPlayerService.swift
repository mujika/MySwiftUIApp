import AVFoundation
import Foundation

// MARK: - Protocol

protocol AudioPlayerService: AnyObject {
    var isPlaying: Bool { get }
    var onPlaybackFinished: (() -> Void)? { get set }
    func play(url: URL) throws
    func stop()
}

// MARK: - Implementation

final class AVAudioPlayerService: NSObject, AudioPlayerService, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    var onPlaybackFinished: (() -> Void)?

    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    func play(url: URL) throws {
        stop()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        player = try AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        onPlaybackFinished?()
    }
}
