import SwiftUI

struct TunerView: View {
    @Bindable var viewModel: TunerViewModel

    var body: some View {
        VStack(spacing: 24) {
            noteDisplay
            centsGauge
            frequencyLabel
            stringIndicators
            Spacer()
            toggleButton
        }
        .padding()
        .alert("エラー", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var noteDisplay: some View {
        VStack(spacing: 4) {
            Text(viewModel.currentNote?.displayName ?? "--")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(noteColor)
                .animation(.easeOut(duration: 0.15), value: viewModel.currentNote?.name)

            Text(viewModel.isActive ? (viewModel.currentNote != nil ? tuningStatus : "音を鳴らしてください") : "タップして開始")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }

    private var centsGauge: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let width = geo.size.width
                let center = width / 2
                let offset = CGFloat(viewModel.centsOff / 50) * center

                ZStack {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Center mark
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 3, height: 20)
                        .position(x: center, y: geo.size.height / 2)

                    // Indicator needle
                    if viewModel.currentNote != nil {
                        Circle()
                            .fill(noteColor)
                            .frame(width: 16, height: 16)
                            .shadow(color: noteColor.opacity(0.5), radius: 4)
                            .position(x: center + offset, y: geo.size.height / 2)
                            .animation(.easeOut(duration: 0.1), value: viewModel.centsOff)
                    }
                }
            }
            .frame(height: 24)

            HStack {
                Text("♭").foregroundStyle(.secondary)
                Spacer()
                Text("♯").foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.horizontal)
    }

    private var frequencyLabel: some View {
        Text(viewModel.frequency > 0 ? String(format: "%.1f Hz", viewModel.frequency) : "-- Hz")
            .font(.system(size: 18, design: .monospaced))
            .foregroundStyle(.secondary)
    }

    private var stringIndicators: some View {
        HStack(spacing: 12) {
            ForEach(GuitarString.allCases, id: \.rawValue) { string in
                let isClosest = viewModel.closestString == string
                VStack(spacing: 4) {
                    Text("\(string.stringNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(string.name)
                        .font(.system(size: 14, weight: isClosest ? .bold : .regular, design: .monospaced))
                        .foregroundStyle(isClosest ? stringColor(for: string) : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isClosest ? stringColor(for: string).opacity(0.15) : Color.gray.opacity(0.1))
                                .stroke(isClosest ? stringColor(for: string) : .clear, lineWidth: 1.5)
                        }

                    Text(String(format: "%.0f", string.frequency))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private var toggleButton: some View {
        Button(action: { viewModel.toggle() }) {
            Label(
                viewModel.isActive ? "停止" : "チューナー開始",
                systemImage: viewModel.isActive ? "stop.fill" : "tuningfork"
            )
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isActive ? Color.red : Color.blue, in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.bottom, 20)
    }

    // MARK: - Helpers

    private var noteColor: Color {
        guard let note = viewModel.currentNote else { return .secondary }
        if note.isInTune { return .green }
        if abs(note.centsOff) < 15 { return .yellow }
        return .red
    }

    private var tuningStatus: String {
        guard let note = viewModel.currentNote else { return "" }
        if note.isInTune { return "チューニング完了 ✓" }
        return note.centsOff > 0 ? "高い ↑" : "低い ↓"
    }

    private func stringColor(for string: GuitarString) -> Color {
        guard let closest = viewModel.closestString, closest == string else { return .secondary }
        return noteColor
    }
}
