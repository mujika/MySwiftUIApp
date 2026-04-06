import SwiftUI

// MARK: - ディレイコントロール画面
/// ディレイタイム、フィードバック、ウェット/ドライスライダーとエコー可視化

struct DelayControlView: View {

    // MARK: - 状態管理

    @ObservedObject var delayEffect: DelayEffect

    /// タップテンポ用のタイムスタンプ記録
    @State private var tapTimestamps: [Date] = []

    // MARK: - ボディ

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // 有効/無効トグル
            enableToggle

            // エコー可視化
            echoVisualization

            // ディレイタイムスライダー
            delayTimeSlider

            // フィードバックスライダー
            feedbackSlider

            // ウェット/ドライスライダー
            wetDrySlider

            // タップテンポボタン
            tapTempoButton

            // リセットボタン
            resetButton
        }
    }

    // MARK: - 有効/無効トグル

    /// ディレイのオン/オフ切り替え
    private var enableToggle: some View {
        HStack {
            Text("ディレイ")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Toggle("", isOn: $delayEffect.isEnabled)
                .tint(AppColors.primaryGreen)
                .labelsHidden()
        }
    }

    // MARK: - エコー可視化

    /// フェードしていくバーでエコーの繰り返しを表現
    private var echoVisualization: some View {
        let echoCount = 6
        let feedbackRatio = max(0, delayEffect.feedback) / 100.0
        let mixRatio = delayEffect.wetDryMix / 100.0

        return HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            ForEach(0..<echoCount, id: \.self) { index in
                let decay = pow(feedbackRatio, Float(index))
                let height = max(0.05, CGFloat(decay * mixRatio))

                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .fill(Color(hex: "50C8E8").opacity(Double(decay) * 0.8 + 0.2))
                    .frame(height: 50 * height)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 50)
        .padding(.vertical, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.backgroundElevated)
        )
        .animation(AppAnimation.standard, value: delayEffect.feedback)
        .animation(AppAnimation.standard, value: delayEffect.wetDryMix)
    }

    // MARK: - ディレイタイムスライダー

    /// ディレイタイムの調整（0.01〜2.0秒）
    private var delayTimeSlider: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("ディレイタイム")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(delayTimeDisplay)
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "50C8E8"))
            }

            Slider(
                value: Binding(
                    get: { Float(delayEffect.delayTime) },
                    set: { delayEffect.delayTime = TimeInterval($0) }
                ),
                in: 0.01...2.0,
                step: 0.01
            )
            .tint(Color(hex: "50C8E8"))
        }
    }

    /// ディレイタイムの表示文字列（ms/s切り替え）
    private var delayTimeDisplay: String {
        if delayEffect.delayTime < 1.0 {
            return String(format: "%.0f ms", delayEffect.delayTime * 1000)
        } else {
            return String(format: "%.2f s", delayEffect.delayTime)
        }
    }

    // MARK: - フィードバックスライダー

    /// フィードバック量の調整（0〜100%）
    private var feedbackSlider: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("フィードバック")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(String(format: "%.0f%%", delayEffect.feedback))
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "50C8E8"))
            }

            Slider(value: $delayEffect.feedback, in: 0...100, step: 1)
                .tint(Color(hex: "50C8E8"))
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
                Text(String(format: "%.0f%%", delayEffect.wetDryMix))
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "50C8E8"))
            }

            Slider(value: $delayEffect.wetDryMix, in: 0...100, step: 1)
                .tint(Color(hex: "50C8E8"))

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

    // MARK: - タップテンポボタン

    /// タップ間隔からディレイタイムを算出
    private var tapTempoButton: some View {
        Button {
            recordTap()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 16))
                Text("タップでディレイタイムを設定")
                    .font(AppTypography.caption)
            }
            .foregroundColor(Color(hex: "50C8E8"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(Color(hex: "50C8E8").opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// タップを記録してディレイタイムを計算
    private func recordTap() {
        let now = Date()

        // 2秒以上空いたらリセット
        if let last = tapTimestamps.last, now.timeIntervalSince(last) > 2.0 {
            tapTimestamps.removeAll()
        }

        tapTimestamps.append(now)

        // 直近4回を保持
        if tapTimestamps.count > 4 {
            tapTimestamps.removeFirst()
        }

        // 最低2回のタップで計算
        guard tapTimestamps.count >= 2 else { return }

        var totalInterval: TimeInterval = 0
        for i in 1..<tapTimestamps.count {
            totalInterval += tapTimestamps[i].timeIntervalSince(tapTimestamps[i - 1])
        }
        let average = totalInterval / Double(tapTimestamps.count - 1)

        // 有効範囲内にクランプ
        let clampedTime = max(0.01, min(2.0, average))
        delayEffect.delayTime = clampedTime
    }

    // MARK: - リセットボタン

    /// パラメータをデフォルトに戻す
    private var resetButton: some View {
        Button {
            withAnimation(AppAnimation.standard) {
                delayEffect.reset()
                tapTimestamps.removeAll()
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
        DelayControlView(delayEffect: DelayEffect())
            .padding()
    }
    .preferredColorScheme(.dark)
}
