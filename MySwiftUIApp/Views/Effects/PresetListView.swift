import SwiftUI

// MARK: - プリセット管理画面
/// ファクトリープリセットとユーザープリセットの一覧表示、適用、作成、削除

struct PresetListView: View {

    // MARK: - 状態管理

    @ObservedObject var effectsChain: EffectsChain

    /// ユーザー作成プリセット
    @State private var userPresets: [Preset] = []

    /// 新規プリセット作成アラートの表示フラグ
    @State private var showingNewPresetAlert: Bool = false

    /// 新規プリセットの名前入力
    @State private var newPresetName: String = ""

    /// 現在選択中のプリセットID
    @State private var selectedPresetId: UUID? = nil

    // MARK: - ボディ

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // ファクトリープリセットセクション
                factoryPresetsSection

                // ユーザープリセットセクション
                userPresetsSection

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("プリセット")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newPresetName = ""
                    showingNewPresetAlert = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(AppColors.primaryGreen)
                }
            }
        }
        .alert("新規プリセット", isPresented: $showingNewPresetAlert) {
            TextField("プリセット名", text: $newPresetName)
            Button("キャンセル", role: .cancel) {}
            Button("保存") {
                saveNewPreset()
            }
        } message: {
            Text("現在のエフェクト設定をプリセットとして保存します。")
        }
    }

    // MARK: - ファクトリープリセットセクション

    /// 編集不可の内蔵プリセット一覧
    private var factoryPresetsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // セクションヘッダー
            HStack {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
                Text("ファクトリープリセット")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.xs)

            ForEach(Preset.factoryPresets) { preset in
                presetRow(preset: preset, isFactory: true)
            }
        }
    }

    // MARK: - ユーザープリセットセクション

    /// ユーザー作成プリセットの一覧（スワイプ削除対応）
    private var userPresetsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // セクションヘッダー
            HStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
                Text("ユーザープリセット")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text("\(userPresets.count)件")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.xs)

            if userPresets.isEmpty {
                // プリセットなしの状態
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.textTertiary)

                    Text("ユーザープリセットはまだありません")
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textTertiary)

                    Text("右上の + ボタンで現在の設定を保存できます")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
                .cardStyle()
            } else {
                ForEach(userPresets) { preset in
                    presetRow(preset: preset, isFactory: false)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deletePreset(preset)
                            } label: {
                                Label("削除", systemImage: "trash.fill")
                            }
                        }
                }
            }
        }
    }

    // MARK: - プリセット行

    /// 個別プリセットの行表示
    private func presetRow(preset: Preset, isFactory: Bool) -> some View {
        let isSelected = selectedPresetId == preset.id

        return Button {
            withAnimation(AppAnimation.standard) {
                selectedPresetId = preset.id
                applyPreset(preset)
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primaryGreen.opacity(0.2) : AppColors.backgroundElevated)
                        .frame(width: 40, height: 40)

                    Image(systemName: preset.icon)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? AppColors.primaryGreen : AppColors.textSecondary)
                }

                // 情報
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(preset.name)
                        .font(AppTypography.body)
                        .foregroundColor(isSelected ? AppColors.primaryGreen : AppColors.textPrimary)

                    HStack(spacing: AppSpacing.xs) {
                        // ファクトリー/ユーザーバッジ
                        Text(isFactory ? "ファクトリー" : "ユーザー")
                            .font(AppTypography.micro)
                            .foregroundColor(isFactory ? AppColors.info : AppColors.primaryGreen)
                            .padding(.horizontal, AppSpacing.xs + 2)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isFactory ? AppColors.info.opacity(0.15) : AppColors.primaryGreen.opacity(0.15))
                            )
                    }
                }

                Spacer()

                // 選択インジケーター
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primaryGreen)
                }
            }
        }
        .buttonStyle(.plain)
        .cardStyle()
    }

    // MARK: - プリセット適用

    /// プリセットの設定をエフェクトチェーンに適用
    private func applyPreset(_ preset: Preset) {
        // エフェクト設定を適用
        let settings = preset.effectSettings

        // EQ設定を適用
        effectsChain.eqEffect.isEnabled = settings.eqSettings.isEnabled
        if let lowBand = settings.eqSettings.bands.first {
            effectsChain.eqEffect.lowGain = Float(lowBand.gain)
        }
        if settings.eqSettings.bands.count > 2 {
            effectsChain.eqEffect.midGain = Float(settings.eqSettings.bands[2].gain)
        }
        if let highBand = settings.eqSettings.bands.last {
            effectsChain.eqEffect.highGain = Float(highBand.gain)
        }

        // リバーブ設定
        effectsChain.reverbEffect.isEnabled = settings.reverbSettings.isEnabled
        effectsChain.reverbEffect.wetDryMix = Float(settings.reverbSettings.wetDryMix * 100)

        // ディレイ設定
        effectsChain.delayEffect.isEnabled = settings.delaySettings.isEnabled
        effectsChain.delayEffect.delayTime = settings.delaySettings.time
        effectsChain.delayEffect.feedback = Float(settings.delaySettings.feedback * 100)
        effectsChain.delayEffect.wetDryMix = Float(settings.delaySettings.wetDryMix * 100)

        // コンプレッサー設定
        effectsChain.compressorEffect.isEnabled = settings.compressorSettings.isEnabled
        effectsChain.compressorEffect.threshold = Float(settings.compressorSettings.threshold)

        // ディストーション設定
        effectsChain.distortionEffect.isEnabled = settings.distortionSettings.isEnabled
        effectsChain.distortionEffect.wetDryMix = Float(settings.distortionSettings.wetDryMix * 100)

        // ノイズゲート設定
        effectsChain.noiseGateEffect.isEnabled = settings.noiseGateSettings.isEnabled
        effectsChain.noiseGateEffect.threshold = Float(settings.noiseGateSettings.threshold)
    }

    // MARK: - 新規プリセット保存

    /// 現在のエフェクト設定を新しいユーザープリセットとして保存
    private func saveNewPreset() {
        guard !newPresetName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // 現在のエフェクト状態からPresetモデルを生成
        let settings = EffectChainSettings(
            eqSettings: EQSettings(
                isEnabled: effectsChain.eqEffect.isEnabled,
                bands: [
                    EQBand(frequency: Double(effectsChain.eqEffect.lowFrequency), gain: Double(effectsChain.eqEffect.lowGain)),
                    EQBand(frequency: Double(effectsChain.eqEffect.midFrequency), gain: Double(effectsChain.eqEffect.midGain)),
                    EQBand(frequency: Double(effectsChain.eqEffect.highFrequency), gain: Double(effectsChain.eqEffect.highGain))
                ]
            ),
            reverbSettings: ReverbSettings(
                isEnabled: effectsChain.reverbEffect.isEnabled,
                wetDryMix: Double(effectsChain.reverbEffect.wetDryMix / 100)
            ),
            delaySettings: DelaySettings(
                isEnabled: effectsChain.delayEffect.isEnabled,
                time: effectsChain.delayEffect.delayTime,
                feedback: Double(effectsChain.delayEffect.feedback / 100),
                wetDryMix: Double(effectsChain.delayEffect.wetDryMix / 100)
            ),
            compressorSettings: CompressorSettings(
                isEnabled: effectsChain.compressorEffect.isEnabled,
                threshold: Double(effectsChain.compressorEffect.threshold)
            ),
            distortionSettings: DistortionSettings(
                isEnabled: effectsChain.distortionEffect.isEnabled,
                wetDryMix: Double(effectsChain.distortionEffect.wetDryMix / 100)
            ),
            noiseGateSettings: NoiseGateSettings(
                isEnabled: effectsChain.noiseGateEffect.isEnabled,
                threshold: Double(effectsChain.noiseGateEffect.threshold)
            )
        )

        let newPreset = Preset(
            name: newPresetName.trimmingCharacters(in: .whitespaces),
            icon: "slider.horizontal.3",
            isFactory: false,
            effectSettings: settings
        )

        withAnimation(AppAnimation.standard) {
            userPresets.append(newPreset)
            selectedPresetId = newPreset.id
        }
    }

    // MARK: - プリセット削除

    /// ユーザープリセットを削除
    private func deletePreset(_ preset: Preset) {
        withAnimation(AppAnimation.standard) {
            userPresets.removeAll { $0.id == preset.id }
            if selectedPresetId == preset.id {
                selectedPresetId = nil
            }
        }
    }
}

// MARK: - プレビュー

#Preview {
    NavigationStack {
        PresetListView(effectsChain: EffectsChain())
    }
    .preferredColorScheme(.dark)
}
