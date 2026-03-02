import SwiftUI

struct RecorderView: View {
    @Bindable var viewModel: RecorderViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            statusSection
            timerSection
            recordButton
            AudioVisualizerView(level: viewModel.audioLevel)
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
                .fill(viewModel.isRecording ? Color.red : Color.gray)
                .frame(width: 12, height: 12)

            Text(viewModel.isRecording ? "録音中" : "待機中")
                .font(.headline)
                .foregroundStyle(viewModel.isRecording ? .red : .secondary)
        }
    }

    private var timerSection: some View {
        Text(viewModel.formattedDuration)
            .font(.system(size: 48, weight: .light, design: .monospaced))
            .foregroundStyle(viewModel.isRecording ? .primary : .secondary)
    }

    private var recordButton: some View {
        Button(action: { viewModel.toggleRecording() }) {
            Circle()
                .fill(viewModel.isRecording ? Color.red : Color.blue)
                .frame(width: 80, height: 80)
                .overlay {
                    if viewModel.isRecording {
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

    @ViewBuilder
    private var permissionWarning: some View {
        if !viewModel.hasPermission {
            Label("マイクの使用許可が必要です", systemImage: "mic.slash")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}
