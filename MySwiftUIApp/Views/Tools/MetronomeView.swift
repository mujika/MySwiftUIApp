import SwiftUI

// MARK: - メトロノーム画面
/// BPM表示、拍子インジケーター、タップテンポ機能を備えたメトロノームUI

struct MetronomeView: View {

    // MARK: - 状態管理

    @StateObject private var metronome = Metronome()

    /// スライダー用のBPM値（Double）
    @State private var sliderBPM: Double = 120.0

    /// ビートパルスアニメーション用
    @State private var beatPulse: Bool = false

    // MARK: - テンポプリセット定義

    /// よく使うテンポの名前とBPM値
    private let tempoPresets: [(name: String, bpm: Int)] = [
        ("Largo", 60),
        ("Andante", 80),
        ("Moderato", 100),
        ("Allegro", 120),
        ("Vivace", 140),
        ("Presto", 180)
    ]

    // MARK: - ボディ

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // BPM表示
                bpmDisplay
                    .padding(.top, AppSpacing.lg)

                // BPMスライダー
                bpmSlider

                // ビートインジケーター
                beatIndicator

                // 拍子記号セレクター
                timeSignaturePicker

                // サブディビジョンセレクター
                subdivisionPicker

                // 開始/停止ボタン
                controlButtons

                // テンポプリセットボタン
                tempoPresetButtons

                // タップテンポボタン
                tapTempoButton

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("メトロノーム")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: metronome.currentBeat) { _, _ in
            // ビートが変わる度にパルスアニメーション
            withAnimation(AppAnimation.fast) {
                beatPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(AppAnimation.fast) {
                    beatPulse = false
                }
            }
        }
    }

    // MARK: - BPM表示

    /// 大きなBPM数値表示
    private var bpmDisplay: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("\(metronome.bpm)")
                .font(AppTypography.timer)
                .foregroundColor(AppColors.textPrimary)
                .contentTransition(.numericText())
                .animation(AppAnimation.fast, value: metronome.bpm)

            Text("BPM")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - BPMスライダー

    /// カスタムスタイルのBPMスライダー（40〜240）
    private var bpmSlider: some View {
        VStack(spacing: AppSpacing.sm) {
            Slider(value: $sliderBPM, in: 40...240, step: 1) {
                Text("BPM")
            }
            .tint(AppColors.primaryGreen)
            .onChange(of: sliderBPM) { _, newValue in
                metronome.setBPM(Int(newValue))
            }
            .onChange(of: metronome.bpm) { _, newValue in
                sliderBPM = Double(newValue)
            }

            // スケールマーキング
            HStack {
                ForEach([40, 80, 120, 160, 200, 240], id: \.self) { mark in
                    Text("\(mark)")
                        .font(AppTypography.micro)
                        .foregroundColor(AppColors.textTertiary)
                    if mark != 240 {
                        Spacer()
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - ビートインジケーター

    /// 拍子に応じた丸いビートインジケーター
    private var beatIndicator: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(1...metronome.timeSignature.beats, id: \.self) { beat in
                let isCurrent = metronome.isPlaying && metronome.currentBeat == beat
                let isAccent = beat == 1

                Circle()
                    .fill(isCurrent ? AppColors.primaryGreen : AppColors.backgroundCard)
                    .frame(
                        width: isAccent ? 40 : 32,
                        height: isAccent ? 40 : 32
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isCurrent ? AppColors.primaryGreen : AppColors.border,
                                lineWidth: isCurrent ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isCurrent ? AppColors.primaryGreen.opacity(0.5) : .clear,
                        radius: isCurrent ? 8 : 0
                    )
                    .scaleEffect(isCurrent && beatPulse ? 1.2 : 1.0)
                    .overlay(
                        Text("\(beat)")
                            .font(AppTypography.caption)
                            .foregroundColor(isCurrent ? AppColors.background : AppColors.textSecondary)
                    )
            }
        }
        .cardStyle()
    }

    // MARK: - 拍子記号セレクター

    /// セグメントコントロール風の拍子記号ピッカー
    private var timeSignaturePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("拍子記号")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(TimeSignature.common, id: \.displayName) { ts in
                        let isSelected = metronome.timeSignature == ts

                        Button {
                            withAnimation(AppAnimation.standard) {
                                metronome.timeSignature = ts
                            }
                        } label: {
                            Text(ts.displayName)
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

    // MARK: - サブディビジョンセレクター

    /// 1〜4のサブディビジョン選択
    private var subdivisionPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("サブディビジョン")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: AppSpacing.sm) {
                ForEach(1...4, id: \.self) { sub in
                    let isSelected = metronome.subdivisions == sub
                    let labels = ["♩", "♪♪", "三連", "♬"]

                    Button {
                        withAnimation(AppAnimation.standard) {
                            metronome.subdivisions = sub
                        }
                    } label: {
                        VStack(spacing: AppSpacing.xs) {
                            Text(labels[sub - 1])
                                .font(AppTypography.body)
                            Text("\(sub)")
                                .font(AppTypography.micro)
                        }
                        .foregroundColor(isSelected ? AppColors.background : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .fill(isSelected ? AppColors.primaryGreen : AppColors.backgroundCard)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - コントロールボタン

    /// 開始/停止ボタン
    private var controlButtons: some View {
        GradientButton(
            title: metronome.isPlaying ? "停止" : "スタート",
            icon: metronome.isPlaying ? "stop.fill" : "play.fill",
            colors: metronome.isPlaying
                ? [AppColors.recordingRed, AppColors.recordingRedDark]
                : AppColors.greenGradient
        ) {
            if metronome.isPlaying {
                metronome.stop()
            } else {
                metronome.start()
            }
        }
    }

    // MARK: - テンポプリセットボタン

    /// 一般的なテンポのクイック選択ボタン
    private var tempoPresetButtons: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("テンポプリセット")
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
                ForEach(tempoPresets, id: \.bpm) { preset in
                    let isSelected = metronome.bpm == preset.bpm

                    Button {
                        withAnimation(AppAnimation.standard) {
                            metronome.setBPM(preset.bpm)
                            sliderBPM = Double(preset.bpm)
                        }
                    } label: {
                        VStack(spacing: AppSpacing.xs) {
                            Text(preset.name)
                                .font(AppTypography.caption)
                                .foregroundColor(isSelected ? AppColors.primaryGreen : AppColors.textPrimary)
                            Text("\(preset.bpm)")
                                .font(AppTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(isSelected ? AppColors.primaryGreen : AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .fill(isSelected ? AppColors.primaryGreen.opacity(0.15) : AppColors.backgroundElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .stroke(isSelected ? AppColors.primaryGreen.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - タップテンポボタン

    /// タップしてBPMを検出する大きなボタン
    private var tapTempoButton: some View {
        Button {
            metronome.tapTempo()
            sliderBPM = Double(metronome.bpm)
        } label: {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.primaryGreen)

                Text("タップテンポ")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textPrimary)

                Text("3回以上タップしてください")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(AppColors.backgroundCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.bottom, AppSpacing.lg)
    }
}

// MARK: - プレビュー

#Preview {
    NavigationStack {
        MetronomeView()
    }
    .preferredColorScheme(.dark)
}
