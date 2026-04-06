import SwiftUI

struct MultiTrackView: View {
    @Bindable var viewModel: MultiTrackViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.tracks.isEmpty {
                    ContentUnavailableView(
                        "トラックがありません",
                        systemImage: "square.stack.3d.up",
                        description: Text("録音一覧からトラックを追加してください")
                    )
                } else {
                    trackList
                }

                Divider()
                transportControls
            }
            .navigationTitle("マルチトラック")
            .alert("エラー", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Track List

    private var trackList: some View {
        List {
            ForEach(viewModel.tracks) { track in
                TrackRowView(
                    track: track,
                    onVolumeChange: { viewModel.setVolume($0, for: track) },
                    onPanChange: { viewModel.setPan($0, for: track) },
                    onMuteToggle: { viewModel.toggleMute(for: track) },
                    onSoloToggle: { viewModel.toggleSolo(for: track) }
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.removeTrack(viewModel.tracks[index])
                }
            }
        }
    }

    // MARK: - Transport

    private var transportControls: some View {
        HStack(spacing: 16) {
            // Overdub
            Button(action: {
                if viewModel.isOverdubbing {
                    viewModel.stopOverdub()
                } else {
                    viewModel.startOverdub()
                }
            }) {
                Label(
                    viewModel.isOverdubbing ? "停止" : "重ね録り",
                    systemImage: viewModel.isOverdubbing ? "stop.circle.fill" : "record.circle"
                )
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.isOverdubbing ? Color.red : Color.orange, in: RoundedRectangle(cornerRadius: 10))
            }

            // Play/Stop
            Button(action: {
                if viewModel.isPlaying {
                    viewModel.stop()
                } else {
                    viewModel.play()
                }
            }) {
                Label(
                    viewModel.isPlaying ? "停止" : "再生",
                    systemImage: viewModel.isPlaying ? "stop.fill" : "play.fill"
                )
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.isPlaying ? Color.gray : Color.blue, in: RoundedRectangle(cornerRadius: 10))
            }

            // Mixdown
            Button(action: {
                Task { await viewModel.mixdown() }
            }) {
                Label("ミックス", systemImage: "arrow.down.to.line")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .disabled(viewModel.tracks.isEmpty)
        }
        .padding()
    }
}

// MARK: - Track Row

struct TrackRowView: View {
    let track: Track
    let onVolumeChange: (Float) -> Void
    let onPanChange: (Float) -> Void
    let onMuteToggle: () -> Void
    let onSoloToggle: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(track.name)
                    .font(.subheadline.bold())

                Spacer()

                Button(action: onMuteToggle) {
                    Text("M")
                        .font(.caption.bold())
                        .foregroundStyle(track.isMuted ? .white : .secondary)
                        .frame(width: 28, height: 28)
                        .background(track.isMuted ? Color.red : Color.gray.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)

                Button(action: onSoloToggle) {
                    Text("S")
                        .font(.caption.bold())
                        .foregroundStyle(track.isSolo ? .white : .secondary)
                        .frame(width: 28, height: 28)
                        .background(track.isSolo ? Color.yellow : Color.gray.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)
            }

            // Volume
            HStack {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: .init(
                    get: { track.volume },
                    set: { onVolumeChange($0) }
                ), in: 0...1)
                .tint(.blue)
                Text(String(format: "%.0f%%", track.volume * 100))
                    .font(.caption2)
                    .frame(width: 35)
            }

            // Pan
            HStack {
                Text("L")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Slider(value: .init(
                    get: { track.pan },
                    set: { onPanChange($0) }
                ), in: -1...1)
                .tint(.green)
                Text("R")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
