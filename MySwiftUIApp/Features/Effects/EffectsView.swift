import SwiftUI

struct EffectsView: View {
    @Bindable var viewModel: EffectsViewModel

    var body: some View {
        NavigationStack {
            List {
                eqSection
                compressorSection
                distortionSection
                reverbSection
                delaySection
                resetSection
            }
            .navigationTitle("エフェクト")
            .overlay {
                if viewModel.isProcessing {
                    ProgressView("エフェクト適用中...")
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
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

    // MARK: - Sections

    private var eqSection: some View {
        Section {
            Toggle("EQ", isOn: $viewModel.eqEnabled)
                .tint(.blue)

            if viewModel.eqEnabled {
                EQSlider(label: "Low (200Hz)", value: $viewModel.eqLow)
                EQSlider(label: "Mid (1kHz)", value: $viewModel.eqMid)
                EQSlider(label: "High (4kHz)", value: $viewModel.eqHigh)
            }
        } header: {
            Label("イコライザー", systemImage: "slider.horizontal.3")
        }
    }

    private var compressorSection: some View {
        Section {
            Toggle("コンプレッサー", isOn: $viewModel.compressorEnabled)
                .tint(.blue)

            if viewModel.compressorEnabled {
                VStack(alignment: .leading) {
                    Text("Threshold: \(Int(viewModel.compThreshold)) dB")
                        .font(.caption)
                    Slider(value: $viewModel.compThreshold, in: -60...0, step: 1)
                        .tint(.purple)
                }
            }
        } header: {
            Label("コンプレッサー", systemImage: "waveform.badge.minus")
        }
    }

    private var distortionSection: some View {
        Section {
            Toggle("ディストーション", isOn: $viewModel.distortionEnabled)
                .tint(.blue)

            if viewModel.distortionEnabled {
                VStack(alignment: .leading) {
                    Text("Mix: \(Int(viewModel.distortionWetDry))%")
                        .font(.caption)
                    Slider(value: $viewModel.distortionWetDry, in: 0...100, step: 1)
                        .tint(.red)
                }
                VStack(alignment: .leading) {
                    Text("Pre-Gain: \(Int(viewModel.distortionPreGain)) dB")
                        .font(.caption)
                    Slider(value: $viewModel.distortionPreGain, in: -80...20, step: 1)
                        .tint(.red)
                }
            }
        } header: {
            Label("ディストーション", systemImage: "bolt.fill")
        }
    }

    private var reverbSection: some View {
        Section {
            Toggle("リバーブ", isOn: $viewModel.reverbEnabled)
                .tint(.blue)

            if viewModel.reverbEnabled {
                VStack(alignment: .leading) {
                    Text("Mix: \(Int(viewModel.reverbWetDry))%")
                        .font(.caption)
                    Slider(value: $viewModel.reverbWetDry, in: 0...100, step: 1)
                        .tint(.cyan)
                }

                Picker("プリセット", selection: $viewModel.reverbPresetIndex) {
                    ForEach(0..<ReverbSettings.presets.count, id: \.self) { i in
                        Text(ReverbSettings.presets[i].name).tag(i)
                    }
                }
            }
        } header: {
            Label("リバーブ", systemImage: "waveform.path")
        }
    }

    private var delaySection: some View {
        Section {
            Toggle("ディレイ", isOn: $viewModel.delayEnabled)
                .tint(.blue)

            if viewModel.delayEnabled {
                VStack(alignment: .leading) {
                    Text("Mix: \(Int(viewModel.delayWetDry))%")
                        .font(.caption)
                    Slider(value: $viewModel.delayWetDry, in: 0...100, step: 1)
                        .tint(.teal)
                }
                VStack(alignment: .leading) {
                    Text(String(format: "Time: %.2fs", viewModel.delayTime))
                        .font(.caption)
                    Slider(value: $viewModel.delayTime, in: 0.01...2.0, step: 0.01)
                        .tint(.teal)
                }
                VStack(alignment: .leading) {
                    Text("Feedback: \(Int(viewModel.delayFeedback))%")
                        .font(.caption)
                    Slider(value: $viewModel.delayFeedback, in: 0...100, step: 1)
                        .tint(.teal)
                }
            }
        } header: {
            Label("ディレイ", systemImage: "repeat.1")
        }
    }

    private var resetSection: some View {
        Section {
            Button("すべてリセット", role: .destructive) {
                viewModel.resetAll()
            }
        }
    }
}

// MARK: - EQ Slider Component

private struct EQSlider: View {
    let label: String
    @Binding var value: Float

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label): \(value > 0 ? "+" : "")\(Int(value)) dB")
                .font(.caption)
            Slider(value: $value, in: -12...12, step: 0.5)
                .tint(.green)
        }
    }
}
