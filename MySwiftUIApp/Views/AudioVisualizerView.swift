import SwiftUI

// MARK: - オーディオビジュアライザービュー
/// ダークテーマのプレミアムな音声レベル表示コンポーネント
/// バーモードとウェーブフォームモードの2種類の描画方式をサポート

struct AudioVisualizerView: View {
    /// 単一の音声レベル値（0〜1）
    let audioLevel: Float

    /// リアルタイム波形サンプル配列（オプション）
    var waveformSamples: [Float] = []

    /// 表示モード
    var mode: VisualizerMode = .bars

    /// バーの数
    var barCount: Int = 30

    var body: some View {
        switch mode {
        case .bars:
            barsView
        case .waveform:
            waveformView
        }
    }

    // MARK: - バーモード

    /// レベルメーターバーを横に並べて表示する
    private var barsView: some View {
        GeometryReader { geometry in
            let barWidth: CGFloat = max(2, (geometry.size.width - CGFloat(barCount - 1) * 2) / CGFloat(barCount))
            let barSpacing: CGFloat = 2

            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: barWidth / 2)
                        .fill(barGradient(for: index))
                        .frame(
                            width: barWidth,
                            height: barHeight(
                                for: index,
                                maxHeight: geometry.size.height,
                                samples: waveformSamples
                            )
                        )
                        .animation(AppAnimation.visualizer, value: audioLevel)
                        .animation(AppAnimation.visualizer, value: waveformSamples.count)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .background(AppColors.background)
    }

    // MARK: - ウェーブフォームモード

    /// 連続的なウェーブフォームラインを描画する
    private var waveformView: some View {
        GeometryReader { geometry in
            let samples = effectiveSamples(for: Int(geometry.size.width / 3))
            let midY = geometry.size.height / 2

            ZStack {
                // 背景ライン
                Path { path in
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
                }
                .stroke(AppColors.textTertiary.opacity(0.2), lineWidth: 1)

                // ウェーブフォーム
                Path { path in
                    guard !samples.isEmpty else { return }

                    let stepX = geometry.size.width / CGFloat(samples.count - 1)

                    path.move(to: CGPoint(x: 0, y: midY))

                    for (index, sample) in samples.enumerated() {
                        let x = CGFloat(index) * stepX
                        let amplitude = CGFloat(abs(sample)) * (geometry.size.height / 2) * 0.8
                        let y = midY - amplitude

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            // ベジェ曲線で滑らかに接続
                            let prevX = CGFloat(index - 1) * stepX
                            let controlX = (prevX + x) / 2
                            path.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: controlX, y: path.currentPoint?.y ?? midY),
                                control2: CGPoint(x: controlX, y: y)
                            )
                        }
                    }
                }
                .stroke(
                    LinearGradient.visualizer,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .animation(AppAnimation.visualizer, value: audioLevel)

                // ミラーウェーブフォーム（下側の反射）
                Path { path in
                    guard !samples.isEmpty else { return }

                    let stepX = geometry.size.width / CGFloat(samples.count - 1)

                    for (index, sample) in samples.enumerated() {
                        let x = CGFloat(index) * stepX
                        let amplitude = CGFloat(abs(sample)) * (geometry.size.height / 2) * 0.4
                        let y = midY + amplitude

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            let prevX = CGFloat(index - 1) * stepX
                            let controlX = (prevX + x) / 2
                            path.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: controlX, y: path.currentPoint?.y ?? midY),
                                control2: CGPoint(x: controlX, y: y)
                            )
                        }
                    }
                }
                .stroke(
                    LinearGradient.visualizer.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
                .animation(AppAnimation.visualizer, value: audioLevel)
            }
        }
        .background(AppColors.background)
    }

    // MARK: - ヘルパー

    /// バーの高さを計算する
    private func barHeight(for index: Int, maxHeight: CGFloat, samples: [Float]) -> CGFloat {
        let minHeight: CGFloat = 3

        // 波形サンプルがある場合はそれを使用
        if !samples.isEmpty {
            let sampleIndex = Int(Float(index) / Float(barCount) * Float(samples.count))
            let clampedIndex = min(sampleIndex, samples.count - 1)
            let sampleValue = abs(samples[max(0, clampedIndex)])
            return max(minHeight, maxHeight * CGFloat(sampleValue) * 0.9)
        }

        // 単一のaudioLevelからバーを生成
        let normalizedIndex = Float(index) / Float(barCount - 1)
        let center: Float = 0.5
        let distance = abs(normalizedIndex - center)
        let bellCurve = exp(-distance * distance * 8.0) // ガウス分布風の形状

        let height = CGFloat(audioLevel * bellCurve * 0.8 + Float.random(in: 0...0.05))
        return max(minHeight, maxHeight * height)
    }

    /// バーのグラデーションカラーを返す
    private func barGradient(for index: Int) -> LinearGradient {
        let progress = CGFloat(index) / CGFloat(barCount - 1)

        // ビジュアライザーグラデーションの色を位置に応じて使用
        let colors = AppColors.visualizerGradient
        let colorIndex = min(Int(progress * CGFloat(colors.count - 1)), colors.count - 2)
        let fraction = progress * CGFloat(colors.count - 1) - CGFloat(colorIndex)

        return LinearGradient(
            gradient: Gradient(colors: [
                colors[colorIndex].opacity(Double(1.0 - fraction * 0.3)),
                colors[min(colorIndex + 1, colors.count - 1)]
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
    }

    /// 有効なサンプルデータを返す（波形サンプルがない場合は生成）
    private func effectiveSamples(for count: Int) -> [Float] {
        if !waveformSamples.isEmpty {
            // リサンプリング
            return resample(waveformSamples, to: count)
        }

        // 単一レベルからサンプルを生成
        return (0..<count).map { i in
            let phase = Float(i) / Float(count) * Float.pi * 4
            return audioLevel * sin(phase) * 0.5
        }
    }

    /// 配列を指定数にリサンプリングする
    private func resample(_ data: [Float], to count: Int) -> [Float] {
        guard !data.isEmpty, count > 0 else { return [] }
        return (0..<count).map { index in
            let sourceIndex = Float(index) / Float(count) * Float(data.count)
            let lower = Int(sourceIndex)
            let upper = min(lower + 1, data.count - 1)
            let fraction = sourceIndex - Float(lower)
            return data[max(0, lower)] * (1 - fraction) + data[min(upper, data.count - 1)] * fraction
        }
    }
}

// MARK: - ビジュアライザーモード

/// オーディオビジュアライザーの描画モード
enum VisualizerMode {
    /// バーグラフ表示（レベルメーター風）
    case bars
    /// 波形ライン表示（連続的なカーブ）
    case waveform
}

// MARK: - プレビュー

#Preview("バーモード") {
    VStack(spacing: AppSpacing.lg) {
        AudioVisualizerView(audioLevel: 0.3, mode: .bars)
            .frame(height: 60)

        AudioVisualizerView(audioLevel: 0.7, mode: .bars)
            .frame(height: 60)

        AudioVisualizerView(audioLevel: 1.0, mode: .bars)
            .frame(height: 60)
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("ウェーブフォームモード") {
    VStack(spacing: AppSpacing.lg) {
        AudioVisualizerView(
            audioLevel: 0.5,
            waveformSamples: (0..<100).map { Float(sin(Double($0) / 10.0) * 0.5) },
            mode: .waveform
        )
        .frame(height: 80)

        AudioVisualizerView(
            audioLevel: 0.8,
            mode: .waveform
        )
        .frame(height: 80)
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
