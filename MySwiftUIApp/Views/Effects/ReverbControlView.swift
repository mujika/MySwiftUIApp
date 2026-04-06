import SwiftUI

// MARK: - リバーブコントロール画面
/// ウェット/ドライスライダーとリバーブプリセットグリッドを提供

struct ReverbControlView: View {

    // MARK: - 状態管理

    @ObservedObject var reverbEffect: ReverbEffect

    // MARK: - ボディ

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // 有効/無効トグル
            enableToggle

            // ウェット/ドライスライダー
            wetDrySlider

            // プリセットグリッド
            presetGrid

            // リセットボタン
            resetButton
        }
    }

    // MARK: - 有効/無効トグル

    /// リバーブのオン/オフ切り替え
    private var enableToggle: some View {
        HStack {
            Text("リバーブ")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Toggle("", isOn: $reverbEffect.isEnabled)
                .tint(AppColors.primaryGreen)
                .labelsHidden()
        }
    }

    // MARK: - ウェット/ドライスライダー

    /// ミックス量の調整スライダー（0〜100%）
    private var wetDrySlider: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Wet/Dry")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(String(format: "%.0f%%", reverbEffect.wetDryMix))
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "A855F7"))
            }

            Slider(value: $reverbEffect.wetDryMix, in: 0...100, step: 1)
                .tint(Color(hex: "A855F7"))

            HStack {
                Text("Dry")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Text("Wet")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    // MARK: - プリセットグリッド

    /// リバーブタイプの選択グリッド
    private var presetGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("空間タイプ")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: AppSpacing.sm
            ) {
                ForEach(ReverbEffectPreset.allCases) { preset in
                    let isSelected = reverbEffect.reverbPreset == preset

                    Button {
                        withAnimation(AppAnimation.standard) {
                            reverbEffect.reverbPreset = preset
                        }
                    } label: {
                        Text(preset.displayName)
                            .font(AppTypography.caption)
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundColor(isSelected ? AppColors.background : AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .fill(isSelected ? Color(hex: "A855F7") : AppColors.backgroundElevated)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - リセットボタン

    /// パラメータをデフォルトに戻す
    private var resetButton: some View {
        Button {
            withAnimation(AppAnimation.standard) {
                reverbEffect.reset()
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
        ReverbControlView(reverbEffect: ReverbEffect())
            .padding()
    }
    .preferredColorScheme(.dark)
}
