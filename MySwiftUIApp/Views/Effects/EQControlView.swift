import SwiftUI

// MARK: - 3バンドEQコントロール画面
/// ロー/ミッド/ハイの3バンドスライダーと簡易EQカーブ表示

struct EQControlView: View {

    // MARK: - 状態管理

    @ObservedObject var eqEffect: EQEffect

    // MARK: - バンド定義

    /// 各バンドの表示情報
    private struct BandInfo {
        let label: String
        let color: Color
        let frequency: String
    }

    /// 3バンドの表示情報
    private var bands: [BandInfo] {
        [
            BandInfo(label: "Low", color: AppColors.info, frequency: String(format: "%.0f Hz", eqEffect.lowFrequency)),
            BandInfo(label: "Mid", color: AppColors.primaryGreen, frequency: String(format: "%.0f Hz", eqEffect.midFrequency)),
            BandInfo(label: "High", color: AppColors.warning, frequency: String(format: "%.0f Hz", eqEffect.highFrequency))
        ]
    }

    // MARK: - ボディ

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // 簡易EQカーブ
            eqCurveView
                .frame(height: 80)

            // 3バンドスライダー
            HStack(alignment: .top, spacing: AppSpacing.md) {
                // ローバンド
                bandSlider(
                    label: "Low",
                    color: AppColors.info,
                    value: $eqEffect.lowGain,
                    frequency: String(format: "%.0f Hz", eqEffect.lowFrequency)
                )

                // ミッドバンド
                bandSlider(
                    label: "Mid",
                    color: AppColors.primaryGreen,
                    value: $eqEffect.midGain,
                    frequency: String(format: "%.0f Hz", eqEffect.midFrequency)
                )

                // ハイバンド
                bandSlider(
                    label: "High",
                    color: AppColors.warning,
                    value: $eqEffect.highGain,
                    frequency: String(format: "%.0f Hz", eqEffect.highFrequency)
                )
            }

            // リセットボタン
            resetButton
        }
    }

    // MARK: - 簡易EQカーブ

    /// 3ポイントのEQカーブをライングラフで表示
    private var eqCurveView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let midY = height / 2

            // 各バンドのゲイン値を高さに変換（-12〜+12dB → 上下）
            let scale = midY / 14.0 // 少し余白を持たせる
            let lowY = midY - CGFloat(eqEffect.lowGain) * scale
            let midEQY = midY - CGFloat(eqEffect.midGain) * scale
            let highY = midY - CGFloat(eqEffect.highGain) * scale

            ZStack {
                // 背景グリッド
                // ゼロライン
                Path { path in
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: width, y: midY))
                }
                .stroke(AppColors.border, lineWidth: 1)

                // +6dBライン
                Path { path in
                    let y = midY - 6 * scale
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(AppColors.border.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))

                // -6dBライン
                Path { path in
                    let y = midY + 6 * scale
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(AppColors.border.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))

                // EQカーブ
                Path { path in
                    path.move(to: CGPoint(x: 0, y: lowY))
                    // ベジエ曲線でスムーズに接続
                    let cp1 = CGPoint(x: width * 0.25, y: lowY)
                    let cp2 = CGPoint(x: width * 0.25, y: midEQY)
                    let midPoint = CGPoint(x: width * 0.5, y: midEQY)
                    path.addCurve(to: midPoint, control1: cp1, control2: cp2)

                    let cp3 = CGPoint(x: width * 0.75, y: midEQY)
                    let cp4 = CGPoint(x: width * 0.75, y: highY)
                    let endPoint = CGPoint(x: width, y: highY)
                    path.addCurve(to: endPoint, control1: cp3, control2: cp4)
                }
                .stroke(
                    LinearGradient(
                        colors: [AppColors.info, AppColors.primaryGreen, AppColors.warning],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )

                // 各バンドのドット
                Circle()
                    .fill(AppColors.info)
                    .frame(width: 8, height: 8)
                    .position(x: width * 0.05, y: lowY)

                Circle()
                    .fill(AppColors.primaryGreen)
                    .frame(width: 8, height: 8)
                    .position(x: width * 0.5, y: midEQY)

                Circle()
                    .fill(AppColors.warning)
                    .frame(width: 8, height: 8)
                    .position(x: width * 0.95, y: highY)

                // dBラベル
                Text("+12")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
                    .position(x: width - 16, y: midY - 12 * scale)

                Text("-12")
                    .font(AppTypography.micro)
                    .foregroundColor(AppColors.textTertiary)
                    .position(x: width - 16, y: midY + 12 * scale)
            }
            .animation(AppAnimation.standard, value: eqEffect.lowGain)
            .animation(AppAnimation.standard, value: eqEffect.midGain)
            .animation(AppAnimation.standard, value: eqEffect.highGain)
        }
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.backgroundElevated)
        )
    }

    // MARK: - バンドスライダー

    /// 個別バンドの垂直スライダー
    private func bandSlider(label: String, color: Color, value: Binding<Float>, frequency: String) -> some View {
        VStack(spacing: AppSpacing.sm) {
            // ゲイン表示
            Text(String(format: "%+.1f dB", value.wrappedValue))
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)

            // スライダー
            Slider(value: value, in: -12...12, step: 0.5)
                .tint(color)

            // バンド名
            Text(label)
                .font(AppTypography.callout)
                .fontWeight(.semibold)
                .foregroundColor(color)

            // 周波数
            Text(frequency)
                .font(AppTypography.micro)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - リセットボタン

    /// 全バンドをフラットにリセット
    private var resetButton: some View {
        Button {
            withAnimation(AppAnimation.standard) {
                eqEffect.reset()
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
        EQControlView(eqEffect: EQEffect())
            .padding()
    }
    .preferredColorScheme(.dark)
}
