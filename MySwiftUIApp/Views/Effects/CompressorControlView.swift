import SwiftUI

// MARK: - コンプレッサーコントロール画面
/// スレッショルド、ヘッドルーム、アタック、リリース、ゲインのスライダーとメーター

struct CompressorControlView: View {

    // MARK: - 状態管理

    @ObservedObject var compressorEffect: CompressorEffect

    // MARK: - ボディ

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // 有効/無効トグル
            enableToggle

            // ゲインリダクションメーター（視覚インジケーター）
            gainReductionMeter

            // スレッショルド
            parameterSlider(
                title: "スレッショルド",
                value: $compressorEffect.threshold,
                range: -40...0,
                step: 0.5,
                unit: "dB",
                format: "%.1f"
            )

            // ヘッドルーム（レシオ相当）
            parameterSlider(
                title: "ヘッドルーム",
                value: $compressorEffect.headRoom,
                range: 0.1...40,
                step: 0.5,
                unit: "dB",
                format: "%.1f"
            )

            // アタック
            parameterSlider(
                title: "アタック",
                value: $compressorEffect.attackTime,
                range: 0.001...0.2,
                step: 0.001,
                unit: "s",
                format: "%.3f"
            )

            // リリース
            parameterSlider(
                title: "リリース",
                value: $compressorEffect.releaseTime,
                range: 0.01...3.0,
                step: 0.01,
                unit: "s",
                format: "%.2f"
            )

            // マスターゲイン
            parameterSlider(
                title: "ゲイン",
                value: $compressorEffect.masterGain,
                range: -40...40,
                step: 0.5,
                unit: "dB",
                format: "%+.1f"
            )

            // リセットボタン
            resetButton
        }
    }

    // MARK: - 有効/無効トグル

    /// コンプレッサーのオン/オフ切り替え
    private var enableToggle: some View {
        HStack {
            Text("コンプレッサー")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Toggle("", isOn: $compressorEffect.isEnabled)
                .tint(AppColors.primaryGreen)
                .labelsHidden()
        }
    }

    // MARK: - ゲインリダクションメーター

    /// スレッショルドとヘッドルームの関係を視覚的に表示するインジケーター
    private var gainReductionMeter: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("コンプレッション概要")
                .font(AppTypography.micro)
                .foregroundColor(AppColors.textTertiary)

            GeometryReader { geometry in
                let width = geometry.size.width
                // スレッショルド位置を計算（-40〜0dBを0〜1に正規化）
                let thresholdNormalized = CGFloat((compressorEffect.threshold + 40) / 40)
                let thresholdX = width * thresholdNormalized

                ZStack(alignment: .leading) {
                    // 背景バー
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(AppColors.backgroundElevated)
                        .frame(height: 24)

                    // スレッショルド以下のゾーン（信号通過）
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(AppColors.primaryGreen.opacity(0.3))
                        .frame(width: max(0, thresholdX), height: 24)

                    // スレッショルド以上のゾーン（圧縮対象）
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: max(0, thresholdX))
                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                            .fill(AppColors.warning.opacity(0.3))
                            .frame(height: 24)
                    }

                    // スレッショルドマーカー
                    Rectangle()
                        .fill(AppColors.warning)
                        .frame(width: 2, height: 32)
                        .position(x: max(1, thresholdX), y: 12)
                }
            }
            .frame(height: 24)

            HStack {
                Text("-40 dB")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Text("0 dB")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    // MARK: - 汎用パラメータスライダー

    /// 各パラメータの共通スライダー
    private func parameterSlider(
        title: String,
        value: Binding<Float>,
        range: ClosedRange<Float>,
        step: Float,
        unit: String,
        format: String
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(String(format: "\(format) \(unit)", value.wrappedValue))
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.warning)
            }

            Slider(
                value: value,
                in: range,
                step: step
            )
            .tint(AppColors.warning)
        }
    }

    // MARK: - リセットボタン

    /// パラメータをデフォルトに戻す
    private var resetButton: some View {
        Button {
            withAnimation(AppAnimation.standard) {
                compressorEffect.reset()
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12))
                Text("リセット")
                    .font(AppTypography.caption)
            }
            .foregroundColor(AppColors.textSecondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - プレビュー

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        CompressorControlView(compressorEffect: CompressorEffect())
            .padding()
    }
    .preferredColorScheme(.dark)
}
