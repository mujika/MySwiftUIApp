import SwiftUI

// MARK: - ディストーションコントロール画面
/// ディストーションタイプセレクター、ゲインスライダー、歪みカーブプレビュー

struct DistortionControlView: View {

    // MARK: - 状態管理

    @ObservedObject var distortionEffect: DistortionEffect

    // MARK: - ボディ

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // 有効/無効トグル
            enableToggle

            // ディストーションカーブプレビュー
            distortionCurvePreview

            // タイプセレクター
            typeSelector

            // プリゲインスライダー
            preGainSlider

            // ウェット/ドライスライダー
            wetDrySlider

            // リセットボタン
            resetButton
        }
    }

    // MARK: - 有効/無効トグル

    /// ディストーションのオン/オフ切り替え
    private var enableToggle: some View {
        HStack {
            Text("ディストーション")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Toggle("", isOn: $distortionEffect.isEnabled)
                .tint(AppColors.primaryGreen)
                .labelsHidden()
        }
    }

    // MARK: - ディストーションカーブプレビュー

    /// 歪み量を示すカーブの視覚表現
    private var distortionCurvePreview: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let midY = height / 2
            // ウェット/ドライで歪みの強さを表現
            let driveAmount = CGFloat(distortionEffect.wetDryMix / 100.0)

            ZStack {
                // 背景グリッド
                Path { path in
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: width, y: midY))
                }
                .stroke(AppColors.border, lineWidth: 0.5)

                Path { path in
                    path.move(to: CGPoint(x: width / 2, y: 0))
                    path.addLine(to: CGPoint(x: width / 2, y: height))
                }
                .stroke(AppColors.border, lineWidth: 0.5)

                // リニアライン（歪みなしの参考線）
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: width, y: 0))
                }
                .stroke(AppColors.textTertiary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                // 歪みカーブ
                Path { path in
                    let steps = 50
                    for i in 0...steps {
                        let x = CGFloat(i) / CGFloat(steps)
                        let inputValue = x * 2.0 - 1.0 // -1〜+1

                        // ソフトクリッピング関数
                        let clippedValue: CGFloat
                        if driveAmount < 0.01 {
                            clippedValue = inputValue // リニア
                        } else {
                            // tanhベースのソフトクリッピング
                            let drive = 1.0 + driveAmount * 10.0
                            clippedValue = tanh(inputValue * drive) / tanh(drive)
                        }

                        let screenX = x * width
                        let screenY = midY - clippedValue * midY * 0.9

                        if i == 0 {
                            path.move(to: CGPoint(x: screenX, y: screenY))
                        } else {
                            path.addLine(to: CGPoint(x: screenX, y: screenY))
                        }
                    }
                }
                .stroke(AppColors.error, lineWidth: 2)
            }
            .animation(AppAnimation.standard, value: distortionEffect.wetDryMix)
        }
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.backgroundElevated)
        )
    }

    // MARK: - タイプセレクター

    /// 5種類のディストーションプリセット
    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("ディストーションタイプ")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(DistortionPreset.allCases) { preset in
                        let isSelected = distortionEffect.distortionPreset == preset

                        Button {
                            withAnimation(AppAnimation.standard) {
                                distortionEffect.distortionPreset = preset
                            }
                        } label: {
                            Text(preset.displayName)
                                .font(AppTypography.caption)
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundColor(isSelected ? AppColors.background : AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? AppColors.error : AppColors.backgroundElevated)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - プリゲインスライダー

    /// プリゲインの調整（-80〜20 dB）
    private var preGainSlider: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("プリゲイン")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(String(format: "%+.1f dB", distortionEffect.preGain))
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.error)
            }

            Slider(value: $distortionEffect.preGain, in: -80...20, step: 1)
                .tint(AppColors.error)
        }
    }

    // MARK: - ウェット/ドライスライダー

    /// ミックス量の調整（0〜100%）
    private var wetDrySlider: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Wet/Dry")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(String(format: "%.0f%%", distortionEffect.wetDryMix))
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.error)
            }

            Slider(value: $distortionEffect.wetDryMix, in: 0...100, step: 1)
                .tint(AppColors.error)

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

    // MARK: - リセットボタン

    /// パラメータをデフォルトに戻す
    private var resetButton: some View {
        Button {
            withAnimation(AppAnimation.standard) {
                distortionEffect.reset()
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
        DistortionControlView(distortionEffect: DistortionEffect())
            .padding()
    }
    .preferredColorScheme(.dark)
}
