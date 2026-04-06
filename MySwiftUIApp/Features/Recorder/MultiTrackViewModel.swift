import Foundation
import Observation

@Observable
@MainActor
final class MultiTrackViewModel {
    private let mixer: MultiTrackMixerService
    private let repository: RecordingRepository

    private(set) var tracks: [Track] = []
    private(set) var isPlaying = false
    private(set) var isOverdubbing = false
    private(set) var errorMessage: String?

    init(mixer: MultiTrackMixerService, repository: RecordingRepository) {
        self.mixer = mixer
        self.repository = repository
    }

    // MARK: - Track Management

    func addRecording(_ recording: Recording) {
        let track = Track(
            url: recording.url,
            name: "Track \(tracks.count + 1)"
        )
        tracks.append(track)
    }

    func removeTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
    }

    func toggleMute(for track: Track) {
        guard let idx = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[idx].isMuted.toggle()
        mixer.updateTrack(tracks[idx])
    }

    func toggleSolo(for track: Track) {
        guard let idx = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[idx].isSolo.toggle()
        mixer.updateTrack(tracks[idx])
    }

    func setVolume(_ volume: Float, for track: Track) {
        guard let idx = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[idx].volume = volume
        mixer.updateTrack(tracks[idx])
    }

    func setPan(_ pan: Float, for track: Track) {
        guard let idx = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[idx].pan = pan
        mixer.updateTrack(tracks[idx])
    }

    // MARK: - Transport

    func play() {
        do {
            try mixer.loadTracks(tracks)
            mixer.play()
            isPlaying = true
        } catch {
            errorMessage = "再生に失敗しました"
        }
    }

    func stop() {
        mixer.stop()
        isPlaying = false
    }

    func startOverdub() {
        do {
            try mixer.loadTracks(tracks)
            let url = try mixer.startOverdub()
            isOverdubbing = true

            // The new track will be added when overdub stops
            let newTrack = Track(url: url, name: "Track \(tracks.count + 1)")
            tracks.append(newTrack)
        } catch {
            errorMessage = "重ね録りの開始に失敗しました"
        }
    }

    func stopOverdub() {
        _ = mixer.stopOverdub()
        isOverdubbing = false
        isPlaying = false
    }

    func mixdown() async {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = dir.appendingPathComponent("mixdown_\(Int(Date().timeIntervalSince1970)).m4a")

        do {
            try await mixer.mixdown(tracks: tracks, to: outputURL)
        } catch {
            errorMessage = "ミックスダウンに失敗しました"
        }
    }

    func dismissError() { errorMessage = nil }
}
