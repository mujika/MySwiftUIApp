import SwiftUI

struct PlaybackControlsView: View {
    @Bindable var viewModel: RecordingListViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Seek slider
            VStack(spacing: 4) {
                Slider(value: .init(
                    get: { viewModel.currentTime },
                    set: { viewModel.seek(to: $0) }
                ), in: 0...max(viewModel.duration, 0.01))
                .tint(.blue)

                HStack {
                    Text(formatTime(viewModel.currentTime))
                    Spacer()
                    Text(formatTime(viewModel.duration))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            // Transport controls
            HStack(spacing: 20) {
                // Rewind 5s
                Button { viewModel.seek(to: max(0, viewModel.currentTime - 5)) } label: {
                    Image(systemName: "gobackward.5")
                        .font(.title3)
                }

                // Stop
                Button { viewModel.stopPlayback() } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }

                // Forward 5s
                Button { viewModel.seek(to: min(viewModel.duration, viewModel.currentTime + 5)) } label: {
                    Image(systemName: "goforward.5")
                        .font(.title3)
                }
            }

            // Speed + A-B Repeat
            HStack(spacing: 16) {
                // Playback speed
                Menu {
                    ForEach(RecordingListViewModel.playbackRates, id: \.self) { rate in
                        Button(String(format: "%.2gx", rate)) {
                            viewModel.playbackRate = rate
                        }
                    }
                } label: {
                    Text(String(format: "%.2gx", viewModel.playbackRate))
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                }

                // A-B Repeat
                Button(action: { viewModel.setLoopPoint() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                        Text(loopLabel)
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(viewModel.isLooping ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1), in: Capsule())
                    .foregroundStyle(viewModel.isLooping ? .orange : .secondary)
                }

                if viewModel.isLooping {
                    Button("リセット") {
                        viewModel.clearLoop()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Helpers

    private var loopLabel: String {
        if let a = viewModel.loopA, viewModel.loopB == nil {
            return "A: \(formatTime(a))"
        }
        if let a = viewModel.loopA, let b = viewModel.loopB {
            return "A: \(formatTime(a)) → B: \(formatTime(b))"
        }
        return "A-B"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }
}
