import SwiftUI

struct RecorderView: View {
    @Bindable var viewModel: RecorderViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            statusSection
            timerSection
            recordButtons
            AudioVisualizerView(level: viewModel.audioLevel)
            gainAndMonitoring
            permissionWarning

            Spacer()
        }
        .padding()
        .task {
            await viewModel.requestPermission()
        }
        .alert(
            "エラー",
            isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.dismissError() } }
            ),
            presenting: viewModel.error
        ) { _ in
            Button("OK") { viewModel.dismissError() }
        } message: { error in
            Text(error.errorDescription ?? "不明なエラー")
        }
    }

    // MARK: - Subviews

    private var statusSection: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            Text(statusText)
                .font(.headline)
                .foregroundStyle(statusColor)
        }
    }

    private var timerSection: some View {
        Text(viewModel.formattedDuration)
            .font(.system(size: 48, weight: .light, design: .monospaced))
            .foregroundStyle(viewModel.isRecording ? .primary : .secondary)
    }

    private var recordButtons: some View {
        HStack(spacing: 24) {
            // Pause/Resume button (only during recording)
            if viewModel.isRecording || viewModel.isPaused {
                Button(action: { viewModel.togglePause() }) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.orange, in: Circle())
                }
            }

            // Main Record/Stop button
            Button(action: { viewModel.toggleRecording() }) {
                Circle()
                    .fill(viewModel.isRecording || viewModel.isPaused ? Color.red : Color.blue)
                    .frame(width: 80, height: 80)
                    .overlay {
                        if viewModel.isRecording || viewModel.isPaused {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 28, height: 28)
                        } else {
                            Circle()
                                .fill(.white)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .shadow(color: viewModel.isRecording ? .red.opacity(0.4) : .blue.opacity(0.3), radius: 8)
            }
            .disabled(!viewModel.hasPermission)
        }
    }

    private var gainAndMonitoring: some View {
        VStack(spacing: 12) {
            // Input Gain
            HStack {
                Image(systemName: "speaker.wave.1")
                    .foregroundStyle(.secondary)
                Slider(value: .init(
                    get: { viewModel.inputGain },
                    set: { viewModel.inputGain = $0 }
                ), in: 0...1, step: 0.05)
                .tint(.blue)
                Image(systemName: "speaker.wave.3")
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f%%", viewModel.inputGain * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 40)
            }

            // Monitoring toggle
            Toggle(isOn: .init(
                get: { viewModel.isMonitoring },
                set: { viewModel.isMonitoring = $0 }
            )) {
                Label("モニタリング", systemImage: "headphones")
                    .font(.subheadline)
            }
            .tint(.blue)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var permissionWarning: some View {
        if !viewModel.hasPermission {
            Label("マイクの使用許可が必要です", systemImage: "mic.slash")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        if viewModel.isRecording { return .red }
        if viewModel.isPaused { return .orange }
        return .gray
    }

    private var statusText: String {
        if viewModel.isRecording { return "録音中" }
        if viewModel.isPaused { return "一時停止中" }
        return "待機中"
    }
}
