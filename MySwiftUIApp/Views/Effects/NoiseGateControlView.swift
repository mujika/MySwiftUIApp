import SwiftUI

// MARK: - ノイズゲートコントロール画面
/// スレッショルドスライダーとゲート開閉状態の可視化

struct NoiseGateControlView: View {

    // MARK: - 状態管理

    @ObservedObject var noiseGateEffect: NoiseGateEffect

    // MARK: - ボディ

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // 有効/無効トグル
            enableToggle

            // ゲートステータスインジケーター
            gateStatusIndicator

            // リアルタイムレベルインジケーター
            levelIndicator

            // スレッショルドスライダー
            thresholdSlider

            // リセットボタン
            resetButton
        }
    }

    // MARK: - 有効/無効トグル

    /// ノイズゲートのオン/オフ切り替え
    private var enableToggle: some View {
        HStack {
            Text("ノイズゲート")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Toggle("", isOn: $noiseGateEffect.isEnabled)
                .tint(AppColors.primaryGreen)
                .labelsHidden()
        }
    }

    // MARK: - ゲートステータスインジケーター

    /// ゲートの開閉状態を視覚的に表示
    private var gateStatusIndicator: some View {
        HStack(spacing: AppSpacing.md) {
            // ゲートアイコン
            ZStack {
                Circle()
                    .fill(noiseGateEffect.isEnabled ? AppColors.primaryGreen.opacity(0.15) : AppColors.backgroundCard)
                    .frame(width: 48, height: 48)

                Image(systemName: noiseGateEffect.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(noiseGateEffect.isEnabled ? AppColors.primaryGreen : AppColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(noiseGateEffect.isEnabled ? "ゲート有効" : "ゲート無効")
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(noiseGateEffect.isEnabled ? AppColors.primaryGreen : AppColors.textTertiary)

                Text("スレッショルド以下の信号をカット")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()
        }
    }

    // MARK: - レベルインジケーター

    /// スレッショルド位置を示す水平バー
    private var levelIndicator: some View {
        VStack(spacing: AppSpacing.xs) {
            GeometryReader { geometry in
                let width = geometry.size.width
                // スレッショルド位置を計算（-60〜0dBを0〜1に正規化）
                let thresholdNormalized = CGFloat((noiseGateEffect.threshold + 60) / 60)
                let thresholdX = width * thresholdNormalized

                ZStack(alignment: .leading) {
                    // 背景バー（全範囲）
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(AppColors.backgroundElevated)
                        .frame(height: 20)

                    // ゲート閉鎖ゾーン（スレッショルド以下、ミュートされる領域）
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(AppColors.error.opacity(0.2))
                        .frame(width: max(0, thresholdX), height: 20)

                    // ゲート開放ゾーン（スレッショルド以上、通過する領域）
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: max(0, thresholdX))
                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                            .fill(AppColors.primaryGreen.opacity(0.2))
                            .frame(height: 20)
                    }

                    // スレッショルドマーカー
                    Rectangle()
                        .fill(AppColors.warning)
                        .frame(width: 2, height: 28)
                        .position(x: max(1, min(width - 1, thresholdX)), y: 10)

                    // ラベル
                    Text("カット")
                        .font(AppTypography.micro)
                        .foregroundColor(AppColors.error.opacity(0.8))
                        .position(x: max(20, thresholdX / 2), y: 10)

                    if thresholdX < width - 30 {
                        Text("通過")
                            .font(AppTypography.micro)
                            .foregroundColor(AppColors.primaryGreen.opacity(0.8))
                            .position(x: min(width - 20, thresholdX + (width - thresholdX) / 2), y: 10)
                    }
                }
                .animation(AppAnimation.standard, value: noiseGateEffect.threshold)
            }
            .frame(height: 28)

            HStack {
                Text("-60 dB")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Text("0 dB")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    // MARK: - スレッショルドスライダー

    /// スレッショルドの調整（-60〜0 dB）
    private var thresholdSlider: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("スレッショルド")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(String(format: "%.0f dB", noiseGateEffect.threshold))
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            }

            Slider(value: $noiseGateEffect.threshold, in: -60...0, step: 1)
                .tint(AppColors.primaryGreen)
        }
    }

    // MARK: - リセットボタン

    /// パラメータをデフォルトに戻す
    private var resetButton: some View {
        Button {
            withAnimation(AppAnimation.standard) {
                noiseGateEffect.reset()
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
        NoiseGateControlView(noiseGateEffect: NoiseGateEffect())
            .padding()
    }
    .preferredColorScheme(.dark)
}
