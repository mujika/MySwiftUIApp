import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class RecordingListViewModel {
    // MARK: - Dependencies

    private let repository: RecordingRepository
    private let player: AudioPlayerService

    // MARK: - State

    private(set) var recordings: [Recording] = []
    private(set) var playingRecordingID: UUID?
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isPaused = false
    private(set) var errorMessage: String?

    var isEmpty: Bool { recordings.isEmpty }

    var playbackRate: Float {
        get { player.playbackRate }
        set { player.playbackRate = newValue }
    }

    // A-B Repeat
    private(set) var loopA: TimeInterval?
    private(set) var loopB: TimeInterval?
    var isLooping: Bool { loopA != nil || loopB != nil }

    private var progressTimer: Timer?

    static let playbackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    // MARK: - Init

    init(repository: RecordingRepository, player: AudioPlayerService) {
        self.repository = repository
        self.player = player

        player.onPlaybackFinished = { [weak self] in
            Task { @MainActor [weak self] in
                self?.onPlaybackEnded()
            }
        }
    }

    // MARK: - Actions

    func loadRecordings() {
        do {
            recordings = try repository.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "録音の読み込みに失敗しました"
        }
    }

    func delete(_ recording: Recording) {
        if playingRecordingID == recording.id { stopPlayback() }
        do {
            try repository.delete(recording)
            recordings.removeAll { $0.id == recording.id }
        } catch {
            errorMessage = "削除に失敗しました"
        }
    }

    func togglePlayback(for recording: Recording) {
        if playingRecordingID == recording.id {
            if isPaused {
                resumePlayback()
            } else {
                pausePlayback()
            }
        } else {
            play(recording)
        }
    }

    func stopPlayback() {
        player.stop()
        onPlaybackEnded()
    }

    func seek(to time: TimeInterval) {
        player.seek(to: time)
        currentTime = time
    }

    func isPlaying(_ recording: Recording) -> Bool {
        playingRecordingID == recording.id && !isPaused
    }

    func isCurrentRecording(_ recording: Recording) -> Bool {
        playingRecordingID == recording.id
    }

    // MARK: - A-B Repeat

    func setLoopPoint() {
        if loopA == nil {
            loopA = currentTime
            player.loopA = currentTime
        } else if loopB == nil {
            loopB = currentTime
            player.loopB = currentTime
        } else {
            clearLoop()
        }
    }

    func clearLoop() {
        loopA = nil
        loopB = nil
        player.loopA = nil
        player.loopB = nil
    }

    // MARK: - Share

    func shareItems(for recording: Recording) -> [Any] {
        [recording.url]
    }

    func dismissError() { errorMessage = nil }

    // MARK: - Private

    private func play(_ recording: Recording) {
        do {
            clearLoop()
            try player.play(url: recording.url)
            playingRecordingID = recording.id
            isPaused = false
            duration = player.duration
            startProgressTimer()
        } catch {
            errorMessage = "再生に失敗しました"
        }
    }

    private func pausePlayback() {
        player.pause()
        isPaused = true
    }

    private func resumePlayback() {
        player.resume()
        isPaused = false
    }

    private func onPlaybackEnded() {
        stopProgressTimer()
        playingRecordingID = nil
        isPaused = false
        currentTime = 0
        duration = 0
        clearLoop()
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.playingRecordingID != nil else { return }
                self.currentTime = self.player.currentTime
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
