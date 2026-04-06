import AVFoundation
import Foundation

// MARK: - Protocol

protocol AudioPlayerService: AnyObject {
    var isPlaying: Bool { get }
    var isPaused: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var playbackRate: Float { get set }
    var onPlaybackFinished: (() -> Void)? { get set }

    // A-B Repeat
    var loopA: TimeInterval? { get set }
    var loopB: TimeInterval? { get set }

    func play(url: URL) throws
    func pause()
    func resume()
    func stop()
    func seek(to time: TimeInterval)
}

// MARK: - Implementation

final class AVAudioPlayerService: NSObject, AudioPlayerService, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var loopTimer: Timer?

    var onPlaybackFinished: (() -> Void)?
    var loopA: TimeInterval?
    var loopB: TimeInterval?

    var isPlaying: Bool { player?.isPlaying ?? false }
    var isPaused: Bool { player != nil && !isPlaying }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }
    var duration: TimeInterval { player?.duration ?? 0 }

    var playbackRate: Float = 1.0 {
        didSet {
            player?.rate = playbackRate
        }
    }

    func play(url: URL) throws {
        stop()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        player = try AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.enableRate = true
        player?.rate = playbackRate
        player?.play()

        startLoopMonitor()
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func stop() {
        stopLoopMonitor()
        player?.stop()
        player = nil
        loopA = nil
        loopB = nil
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = max(0, min(time, duration))
    }

    // MARK: - A-B Loop Monitor

    private func startLoopMonitor() {
        loopTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            if let b = self.loopB, player.currentTime >= b {
                player.currentTime = self.loopA ?? 0
            }
        }
    }

    private func stopLoopMonitor() {
        loopTimer?.invalidate()
        loopTimer = nil
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        stopLoopMonitor()
        onPlaybackFinished?()
    }
}
