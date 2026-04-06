import SwiftUI

// MARK: - チューナー画面
/// FFTベースのピッチ検出を表示するギターチューナーインターフェース
/// 円形プログレス、セントインジケーター、弦参照ボタンを提供

struct TunerView: View {

    // MARK: - 状態管理

    @StateObject private var tuner = Tuner()

    /// チューナーの動作状態（エンジン未接続のため手動トグル用）
    @State private var isRunning: Bool = false

    // MARK: - ボディ

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // 円形チューニングインジケーター
                tuningCircle
                    .padding(.top, AppSpacing.lg)

                // セントオフセットバー
                centsIndicator

                // チューニングステータステキスト
                tuningStatusText

                // ギター弦リファレンスボタン
                guitarStringsReference

                // 開始/停止ボタン
                startStopButton

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("チューナー")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - 円形チューニングインジケーター

    /// 検出精度を示す円形プログレスビュー
    private var tuningCircle: some View {
        let progress = tuningProgress
        let ringColor = tuningRingColor

        return CircularProgressView(
            progress: progress,
            label: tuner.detectedNote,
            subLabel: String(format: "%.1f Hz", tuner.detectedFrequency),
            lineWidth: 10,
            progressColor: ringColor,
            size: 200
        )
    }

    /// チューニング精度に基づくプログレス値（0〜1）
    private var tuningProgress: CGFloat {
        guard tuner.detectedFrequency > 0 else { return 0 }
        // セントオフセットが0に近いほど1.0に近づく
        let normalizedOffset = abs(tuner.centsOffset) / 50.0
        return CGFloat(max(0, 1.0 - normalizedOffset))
    }

    /// セントオフセットに応じたリング色
    private var tuningRingColor: Color {
        let absCents = abs(tuner.centsOffset)
        if tuner.detectedFrequency <= 0 {
            return AppColors.textTertiary
        } else if absCents <= 5 {
            return AppColors.primaryGreen
        } else if absCents <= 15 {
            return AppColors.warning
        } else {
            return AppColors.error
        }
    }

    // MARK: - セントインジケーター

    /// 水平バーによるセントオフセット表示（-50〜+50）
    private var centsIndicator: some View {
        VStack(spacing: AppSpacing.sm) {
            // セント数値表示
            Text(String(format: "%+.0f セント", tuner.centsOffset))
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)

            // バー本体
            GeometryReader { geometry in
                let barWidth = geometry.size.width
                let centerX = barWidth / 2
                // セントオフセットをピクセル位置に変換
                let offset = CGFloat(tuner.centsOffset / 50.0) * (barWidth / 2)
                let markerX = centerX + offset

                ZStack(alignment: .leading) {
                    // 背景バー
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(AppColors.backgroundCard)
                        .frame(height: 12)

                    // 中央グリーンゾーン（±5セント）
                    let greenWidth = barWidth * (10.0 / 100.0)
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(AppColors.primaryGreen.opacity(0.3))
                        .frame(width: greenWidth, height: 12)
                        .position(x: centerX, y: 6)

                    // 中央マーカー線
                    Rectangle()
                        .fill(AppColors.textTertiary)
                        .frame(width: 2, height: 20)
                        .position(x: centerX, y: 6)

                    // 検出位置マーカー
                    if tuner.detectedFrequency > 0 {
                        Circle()
                            .fill(tuningRingColor)
                            .frame(width: 16, height: 16)
                            .shadow(color: tuningRingColor.opacity(0.5), radius: 4)
                            .position(x: max(8, min(barWidth - 8, markerX)), y: 6)
                            .animation(AppAnimation.standard, value: tuner.centsOffset)
                    }
                }
            }
            .frame(height: 20)

            // スケールラベル
            HStack {
                Text("-50")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Text("0")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Text("+50")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .cardStyle()
    }

    // MARK: - チューニングステータステキスト

    /// 現在のチューニング状態をテキストで表示
    private var tuningStatusText: some View {
        Group {
            if tuner.detectedFrequency <= 0 {
                Text("音を鳴らしてください")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textTertiary)
            } else if tuner.isInTune {
                Text("チューニング完了")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.primaryGreen)
            } else if tuner.centsOffset > 0 {
                Text("高すぎます ↓")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.warning)
            } else {
                Text("低すぎます ↑")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.warning)
            }
        }
    }

    // MARK: - ギター弦リファレンスボタン

    /// 標準チューニングの6弦ボタン
    private var guitarStringsReference: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("標準チューニング")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: AppSpacing.sm) {
                ForEach(Tuner.guitarStrings, id: \.name) { guitarString in
                    let isClosest = isClosestString(guitarString.name)
                    stringButton(name: guitarString.name, frequency: guitarString.frequency, isHighlighted: isClosest)
                }
            }
        }
        .cardStyle()
    }

    /// 指定弦が検出中の弦に最も近いかどうか
    private func isClosestString(_ name: String) -> Bool {
        guard let closest = tuner.closestGuitarString() else { return false }
        return closest.name == name
    }

    /// 各弦のボタン
    private func stringButton(name: String, frequency: Float, isHighlighted: Bool) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(name)
                .font(AppTypography.callout)
                .fontWeight(isHighlighted ? .bold : .regular)
                .foregroundColor(isHighlighted ? AppColors.primaryGreen : AppColors.textPrimary)

            Text(String(format: "%.0f", frequency))
                .font(AppTypography.micro)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(isHighlighted ? AppColors.primaryGreen.opacity(0.15) : AppColors.backgroundElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(isHighlighted ? AppColors.primaryGreen.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - 開始/停止ボタン

    /// チューナーの動作をトグルするボタン
    private var startStopButton: some View {
        GradientButton(
            title: isRunning ? "停止" : "チューナー開始",
            icon: isRunning ? "stop.fill" : "tuningfork",
            colors: isRunning ? [AppColors.recordingRed, AppColors.recordingRedDark] : AppColors.greenGradient
        ) {
            isRunning.toggle()
            if isRunning {
                // 実際のアプリではAudioEngineを渡してstart()を呼ぶ
                tuner.isActive = true
            } else {
                tuner.stop()
            }
        }
        .padding(.top, AppSpacing.sm)
    }
}

// MARK: - プレビュー

#Preview {
    NavigationStack {
        TunerView()
    }
    .preferredColorScheme(.dark)
}
