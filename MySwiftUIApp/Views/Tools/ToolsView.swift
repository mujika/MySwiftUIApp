import SwiftUI

// MARK: - ツールタブのメイン画面
/// チューナー、メトロノーム、エフェクト、プリセットへのナビゲーショングリッドを提供

struct ToolsView: View {

    // MARK: - ツールアイテム定義

    /// グリッドに表示するツール項目
    private struct ToolItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let destination: ToolDestination
    }

    /// ナビゲーション先の種別
    enum ToolDestination {
        case tuner
        case metronome
        case effectsChain
        case presets
    }

    /// ツール一覧データ
    private let tools: [ToolItem] = [
        ToolItem(title: "チューナー", icon: "tuningfork", destination: .tuner),
        ToolItem(title: "メトロノーム", icon: "metronome", destination: .metronome),
        ToolItem(title: "エフェクト", icon: "slider.horizontal.3", destination: .effectsChain),
        ToolItem(title: "プリセット", icon: "star.fill", destination: .presets)
    ]

    /// グリッドのカラム定義（2列）
    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    // MARK: - 依存オブジェクト

    /// エフェクトチェーン（親から注入）
    @ObservedObject var effectsChain: EffectsChain

    // MARK: - ボディ

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // タイトル
                    Text("ツール")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)

                    // ツールグリッド
                    LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                        ForEach(tools) { tool in
                            NavigationLink {
                                destinationView(for: tool.destination)
                            } label: {
                                toolCard(title: tool.title, icon: tool.icon)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)

                    Spacer()
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - ツールカード

    /// 各ツールのカード表示
    private func toolCard(title: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(AppColors.primaryGreen)

            Text(title)
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .cardStyle()
    }

    // MARK: - ナビゲーション先の生成

    /// ツール種別に対応するビューを返す
    @ViewBuilder
    private func destinationView(for destination: ToolDestination) -> some View {
        switch destination {
        case .tuner:
            TunerView()
        case .metronome:
            MetronomeView()
        case .effectsChain:
            EffectsChainView(effectsChain: effectsChain)
        case .presets:
            PresetListView(effectsChain: effectsChain)
        }
    }
}

// MARK: - プレビュー

#Preview {
    ToolsView(effectsChain: EffectsChain())
        .preferredColorScheme(.dark)
}
