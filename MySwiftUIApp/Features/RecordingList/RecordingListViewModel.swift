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
    private(set) var errorMessage: String?

    var isEmpty: Bool { recordings.isEmpty }

    // MARK: - Init

    init(repository: RecordingRepository, player: AudioPlayerService) {
        self.repository = repository
        self.player = player

        player.onPlaybackFinished = { [weak self] in
            Task { @MainActor [weak self] in
                self?.playingRecordingID = nil
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
        do {
            try repository.delete(recording)
            recordings.removeAll { $0.id == recording.id }
        } catch {
            errorMessage = "削除に失敗しました"
        }
    }

    func togglePlayback(for recording: Recording) {
        if playingRecordingID == recording.id {
            stopPlayback()
        } else {
            play(recording)
        }
    }

    func isPlaying(_ recording: Recording) -> Bool {
        playingRecordingID == recording.id
    }

    func shareItems(for recording: Recording) -> [Any] {
        [recording.url]
    }

    func dismissError() {
        errorMessage = nil
    }

    // MARK: - Private

    private func play(_ recording: Recording) {
        do {
            try player.play(url: recording.url)
            playingRecordingID = recording.id
        } catch {
            errorMessage = "再生に失敗しました"
        }
    }

    private func stopPlayback() {
        player.stop()
        playingRecordingID = nil
    }
}
