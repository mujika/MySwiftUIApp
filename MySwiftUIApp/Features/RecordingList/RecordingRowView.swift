import SwiftUI

struct RecordingRowView: View {
    let recording: Recording
    let isPlaying: Bool
    let isCurrent: Bool
    let onTogglePlayback: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            playButton
            recordingInfo
            Spacer()
            actionButtons
        }
        .padding(.vertical, 4)
        .listRowBackground(isCurrent ? Color.blue.opacity(0.06) : nil)
    }

    // MARK: - Subviews

    private var playButton: some View {
        Button(action: onTogglePlayback) {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.title)
                .foregroundStyle(isPlaying ? .orange : .blue)
        }
        .buttonStyle(.plain)
    }

    private var recordingInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recording.displayName)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 8) {
                Label(recording.formattedDuration, systemImage: "clock")
                Label(recording.formattedFileSize, systemImage: "doc")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}
