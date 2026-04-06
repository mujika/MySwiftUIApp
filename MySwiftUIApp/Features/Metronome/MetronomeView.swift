import SwiftUI

struct MetronomeView: View {
    @Bindable var viewModel: MetronomeViewModel
    @State private var tapTimes: [Date] = []

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            beatIndicators
            bpmDisplay
            bpmControls
            timeSignaturePicker
            Spacer()
            bottomButtons
        }
        .padding()
    }

    // MARK: - Subviews

    private var beatIndicators: some View {
        HStack(spacing: 10) {
            ForEach(1...viewModel.beatsInBar, id: \.self) { beat in
                Circle()
                    .fill(beatColor(for: beat))
                    .frame(width: beat == 1 ? 28 : 22, height: beat == 1 ? 28 : 22)
                    .shadow(color: viewModel.currentBeat == beat ? beatColor(for: beat).opacity(0.6) : .clear, radius: 6)
                    .animation(.easeOut(duration: 0.08), value: viewModel.currentBeat)
            }
        }
    }

    private var bpmDisplay: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.bpm)")
                .font(.system(size: 80, weight: .thin, design: .rounded))
                .contentTransition(.numericText())

            Text("BPM")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var bpmControls: some View {
        HStack(spacing: 24) {
            Button { viewModel.decrementBPM(by: 5) } label: {
                Image(systemName: "minus.circle")
                    .font(.title)
            }

            Slider(value: .init(
                get: { Double(viewModel.bpm) },
                set: { viewModel.bpm = Int($0) }
            ), in: 30...300, step: 1)
            .tint(.blue)

            Button { viewModel.incrementBPM(by: 5) } label: {
                Image(systemName: "plus.circle")
                    .font(.title)
            }
        }
        .padding(.horizontal)
    }

    private var timeSignaturePicker: some View {
        HStack(spacing: 12) {
            Text("拍子:")
                .foregroundStyle(.secondary)

            ForEach(MetronomeViewModel.availableSignatures, id: \.display) { sig in
                Button(sig.display) {
                    viewModel.timeSignature = sig
                }
                .font(.subheadline.weight(viewModel.timeSignature == sig ? .bold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    if viewModel.timeSignature == sig {
                        Capsule().fill(Color.blue.opacity(0.15))
                    } else {
                        Capsule().fill(Color.gray.opacity(0.1))
                    }
                }
            }
        }
    }

    private var bottomButtons: some View {
        HStack(spacing: 16) {
            Button(action: { viewModel.tapTempo(tapTimes: &tapTimes) }) {
                Label("タップ", systemImage: "hand.tap")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            }

            Button(action: { viewModel.toggle() }) {
                Label(
                    viewModel.isPlaying ? "停止" : "開始",
                    systemImage: viewModel.isPlaying ? "stop.fill" : "play.fill"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isPlaying ? Color.red : Color.blue, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Helpers

    private func beatColor(for beat: Int) -> Color {
        guard viewModel.isPlaying else { return .gray.opacity(0.3) }
        if viewModel.currentBeat == beat {
            return beat == 1 ? .red : .blue
        }
        return .gray.opacity(0.3)
    }
}
