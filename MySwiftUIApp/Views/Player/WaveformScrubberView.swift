import SwiftUI

// MARK: - 波形スクラバービュー
/// オーディオ波形をベースにしたカスタムシークスライダー
/// 再生済み部分をグリーン、未再生部分をグレーで描画し、ドラッグでシーク可能
struct WaveformScrubberView: View {

    // MARK: - プロパティ

    /// 波形データ（0.0〜1.0の振幅値配列）
    let waveformData: [Float]

    /// 再生進捗（0.0〜1.0）
    let progress: Double

    /// 現在の再生位置（秒）
    let currentTime: TimeInterval

    /// オーディオの全長（秒）
    let duration: TimeInterval

    /// シーク完了時のコールバック
    let onSeek: (TimeInterval) -> Void

    // MARK: - 内部状態

    /// ドラッグ中フラグ
    @State private var isDragging: Bool = false

    /// ドラッグ中の仮進捗値
    @State private var dragProgress: Double = 0.0

    /// 波形バーの最小高さ
    private let minBarHeight: CGFloat = 2

    /// 波形バーの幅
    private let barWidth: CGFloat = 2.5

    /// 波形バーの間隔
    private let barSpacing: CGFloat = 1.5

    // MARK: - 計算プロパティ

    /// 表示に使用する実効進捗値
    private var effectiveProgress: Double {
        isDragging ? dragProgress : progress
    }

    /// ドラッグ中に表示するツールチップの時間テキスト
    private var dragTimeText: String {
        let time = dragProgress * duration
        return formatTime(time)
    }

    // MARK: - ボディ

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // 波形スクラバー本体
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let height = geometry.size.height

                ZStack(alignment: .leading) {
                    // 波形バーを描画
                    waveformBars(in: geometry)

                    // プレイヘッド（現在位置の縦線）
                    playheadLine(totalWidth: totalWidth, height: height)

                    // ドラッグ中のツールチップ
                    if isDragging {
                        dragTooltip(totalWidth: totalWidth)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDragChanged(value: value, totalWidth: totalWidth)
                        }
                        .onEnded { value in
                            handleDragEnded(value: value, totalWidth: totalWidth)
                        }
                )
            }
            .frame(height: 48)

            // 時間ラベル
            timeLabels
        }
    }

    // MARK: - 波形バー描画

    /// 波形のバーを描画する
    @ViewBuilder
    private func waveformBars(in geometry: GeometryProxy) -> some View {
        let totalWidth = geometry.size.width
        let height = geometry.size.height
        let barCount = Int(totalWidth / (barWidth + barSpacing))
        let samples = resampleWaveform(to: barCount)

        HStack(alignment: .center, spacing: barSpacing) {
            ForEach(0..<samples.count, id: \.self) { index in
                let normalizedIndex = Double(index) / Double(max(samples.count - 1, 1))
                let isPlayed = normalizedIndex <= effectiveProgress
                let amplitude = CGFloat(samples[index])

                RoundedRectangle(cornerRadius: 1)
                    .fill(isPlayed ? AppColors.primaryGreen : AppColors.textTertiary.opacity(0.5))
                    .frame(
                        width: barWidth,
                        height: max(minBarHeight, height * 0.8 * amplitude)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - プレイヘッド

    /// 現在の再生位置を示す縦線
    private func playheadLine(totalWidth: CGFloat, height: CGFloat) -> some View {
        let xPosition = totalWidth * effectiveProgress

        return Rectangle()
            .fill(AppColors.textPrimary)
            .frame(width: 2, height: height)
            .offset(x: xPosition)
            .shadow(color: AppColors.textPrimary.opacity(0.5), radius: 4)
            .animation(isDragging ? nil : AppAnimation.fast, value: effectiveProgress)
    }

    // MARK: - ドラッグツールチップ

    /// ドラッグ中に表示する時間ツールチップ
    private func dragTooltip(totalWidth: CGFloat) -> some View {
        let xPosition = totalWidth * dragProgress
        let clampedX = min(max(xPosition, 30), totalWidth - 30)

        return VStack(spacing: 0) {
            Text(dragTimeText)
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule()
                        .fill(AppColors.backgroundCard)
                )
            // 三角形のインジケーター
            Triangle()
                .fill(AppColors.backgroundCard)
                .frame(width: 8, height: 4)
        }
        .position(x: clampedX, y: -12)
        .transition(.opacity)
    }

    // MARK: - 時間ラベル

    /// 左右の時間表示（経過時間 / 残り時間）
    private var timeLabels: some View {
        HStack {
            Text(formatTime(isDragging ? dragProgress * duration : currentTime))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .monospacedDigit()

            Spacer()

            Text("-\(formatTime(duration - (isDragging ? dragProgress * duration : currentTime)))")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .monospacedDigit()
        }
    }

    // MARK: - ジェスチャーハンドラー

    /// ドラッグ開始・移動の処理
    private func handleDragChanged(value: DragGesture.Value, totalWidth: CGFloat) {
        if !isDragging {
            withAnimation(AppAnimation.fast) {
                isDragging = true
            }
        }
        let newProgress = max(0, min(1, Double(value.location.x / totalWidth)))
        dragProgress = newProgress
    }

    /// ドラッグ終了の処理
    private func handleDragEnded(value: DragGesture.Value, totalWidth: CGFloat) {
        let finalProgress = max(0, min(1, Double(value.location.x / totalWidth)))
        let seekTime = finalProgress * duration
        onSeek(seekTime)

        withAnimation(AppAnimation.fast) {
            isDragging = false
        }
    }

    // MARK: - ユーティリティ

    /// 波形データを指定数にリサンプリングする
    private func resampleWaveform(to count: Int) -> [Float] {
        guard !waveformData.isEmpty, count > 0 else {
            // プレースホルダー波形を生成
            return (0..<count).map { i in
                let normalized = Float(i) / Float(max(count - 1, 1))
                return 0.15 + 0.6 * abs(sin(normalized * .pi * 4))
            }
        }

        return (0..<count).map { index in
            let sourceIndex = Float(index) / Float(count) * Float(waveformData.count)
            let lower = Int(sourceIndex)
            let upper = min(lower + 1, waveformData.count - 1)
            let fraction = sourceIndex - Float(lower)
            return waveformData[lower] * (1 - fraction) + waveformData[upper] * fraction
        }
    }

    /// TimeIntervalをMM:SS形式にフォーマットする
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 三角形シェイプ（ツールチップ用）
/// ドラッグツールチップの下部に表示する三角形インジケーター
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - プレビュー
#Preview("WaveformScrubber") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        WaveformScrubberView(
            waveformData: (0..<100).map { i in
                Float(0.2 + 0.6 * abs(sin(Float(i) / 100.0 * .pi * 5)))
            },
            progress: 0.4,
            currentTime: 82,
            duration: 204,
            onSeek: { time in
                print("シーク先: \(time)秒")
            }
        )
        .padding(.horizontal, AppSpacing.md)
    }
    .preferredColorScheme(.dark)
}
