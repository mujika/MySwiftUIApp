import SwiftUI

// MARK: - エフェクトチェーン管理画面
/// エフェクトの順序変更、個別有効/無効、パラメータ編集を提供するメイン画面

struct EffectsChainView: View {

    // MARK: - 状態管理

    @ObservedObject var effectsChain: EffectsChain

    /// 展開中のエフェクトタイプ
    @State private var expandedEffect: EffectType? = nil

    // MARK: - ボディ

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // プリセットセレクター
                presetSelector

                // バイパスオールトグル
                bypassAllToggle

                // エフェクトリスト
                effectsList

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("エフェクト")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - プリセットセレクター

    /// 水平スクロールのプリセットピル
    private var presetSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("プリセット")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(EffectsPreset.allCases) { preset in
                        let isSelected = effectsChain.currentPreset == preset

                        Button {
                            withAnimation(AppAnimation.standard) {
                                effectsChain.applyPreset(preset)
                            }
                        } label: {
                            Text(preset.displayName)
                                .font(AppTypography.callout)
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundColor(isSelected ? AppColors.background : AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? AppColors.primaryGreen : AppColors.backgroundCard)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - バイパスオールトグル

    /// チェーン全体の有効/無効トグル
    private var bypassAllToggle: some View {
        HStack {
            Image(systemName: "power")
                .font(.system(size: 18))
                .foregroundColor(effectsChain.isChainEnabled ? AppColors.primaryGreen : AppColors.textTertiary)

            Text("エフェクトチェーン")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Toggle("", isOn: $effectsChain.isChainEnabled)
                .tint(AppColors.primaryGreen)
                .labelsHidden()
        }
        .cardStyle()
    }

    // MARK: - エフェクトリスト

    /// 各エフェクトの行と展開可能なコントロール
    private var effectsList: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(effectsChain.effectOrder) { effectType in
                effectRow(for: effectType)
            }
        }
    }

    /// 個別エフェクトの行表示
    private func effectRow(for type: EffectType) -> some View {
        let effect = effectsChain.effect(for: type)
        let isExpanded = expandedEffect == type

        return VStack(spacing: 0) {
            // ヘッダー行
            Button {
                withAnimation(AppAnimation.standard) {
                    expandedEffect = isExpanded ? nil : type
                }
            } label: {
                HStack(spacing: AppSpacing.md) {
                    // アイコン
                    Image(systemName: type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(effect.isEnabled ? colorForEffect(type) : AppColors.textTertiary)
                        .frame(width: 24)

                    // 名前
                    Text(type.displayName)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    // 有効/無効トグル
                    Toggle("", isOn: Binding(
                        get: { effect.isEnabled },
                        set: { effect.isEnabled = $0 }
                    ))
                    .tint(AppColors.primaryGreen)
                    .labelsHidden()

                    // 展開シェブロン
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(AppAnimation.standard, value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            // 展開コンテンツ（パラメータコントロール）
            if isExpanded {
                Divider()
                    .background(AppColors.separator)
                    .padding(.vertical, AppSpacing.sm)

                expandedControlView(for: type)
            }
        }
        .cardStyle()
    }

    /// エフェクトタイプに応じた色を返す
    private func colorForEffect(_ type: EffectType) -> Color {
        switch type {
        case .eq: return AppColors.info
        case .compressor: return AppColors.warning
        case .distortion: return AppColors.error
        case .delay: return Color(hex: "50C8E8")
        case .reverb: return Color(hex: "A855F7")
        case .noiseGate: return AppColors.textSecondary
        }
    }

    // MARK: - 展開コントロールビュー

    /// エフェクトタイプに応じた詳細コントロールを返す
    @ViewBuilder
    private func expandedControlView(for type: EffectType) -> some View {
        switch type {
        case .eq:
            EQControlView(eqEffect: effectsChain.eqEffect)
        case .compressor:
            CompressorControlView(compressorEffect: effectsChain.compressorEffect)
        case .distortion:
            DistortionControlView(distortionEffect: effectsChain.distortionEffect)
        case .delay:
            DelayControlView(delayEffect: effectsChain.delayEffect)
        case .reverb:
            ReverbControlView(reverbEffect: effectsChain.reverbEffect)
        case .noiseGate:
            NoiseGateControlView(noiseGateEffect: effectsChain.noiseGateEffect)
        }
    }
}

// MARK: - プレビュー

#Preview {
    NavigationStack {
        EffectsChainView(effectsChain: EffectsChain())
    }
    .preferredColorScheme(.dark)
}
