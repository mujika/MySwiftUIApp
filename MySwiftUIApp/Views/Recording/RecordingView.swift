import SwiftUI

// MARK: - メイン録音画面
/// 録音タブに表示されるメイン画面
/// ノーマル/ループ/マルチトラックの3モードをセグメントピッカーで切り替え可能
/// 各モードに応じたサブビューをアニメーション付きで表示する

struct RecordingView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var appState: AppState

    // MARK: - 録音モード定義

    /// 録音モードの列挙型
    enum RecordingMode: String, CaseIterable, Identifiable {
        case normal = "ノーマル"
        case loop = "ループ"
        case multiTrack = "マルチトラック"

        var id: String { rawValue }

        /// モードに対応するアイコン
        var icon: String {
            switch self {
            case .normal: return "mic.fill"
            case .loop: return "repeat"
            case .multiTrack: return "slider.horizontal.3"
            }
        }
    }

    // MARK: - 状態プロパティ

    /// 現在選択中の録音モード
    @State private var selectedMode: RecordingMode = .normal

    /// モード切替アニメーション用のネームスペース
    @Namespace private var modeAnimation

    var body: some View {
        ZStack {
            // ダーク背景
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダータイトル
                headerSection
                    .padding(.top, AppSpacing.sm)

                // モード切替セグメントピッカー
                modePickerSection
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.md)

                // モードに応じたコンテンツ
                contentSection
            }
        }
    }

    // MARK: - ヘッダーセクション

    /// 画面上部のタイトル表示
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("録音")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)

                Text(selectedMode.rawValue)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // 選択モードのアイコン
            Image(systemName: selectedMode.icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primaryGreen)
                .padding(AppSpacing.sm)
                .background(AppColors.backgroundCard)
                .clipShape(Circle())
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - モードピッカーセクション

    /// カスタムセグメントピッカー（Spotify風ダークスタイル）
    private var modePickerSection: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(RecordingMode.allCases) { mode in
                Button {
                    withAnimation(AppAnimation.spring) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))

                        Text(mode.rawValue)
                            .font(AppTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(
                        selectedMode == mode
                            ? AppColors.background
                            : AppColors.textSecondary
                    )
                    .padding(.horizontal, AppSpacing.sm + AppSpacing.xs)
                    .padding(.vertical, AppSpacing.sm)
                    .background {
                        if selectedMode == mode {
                            Capsule()
                                .fill(AppColors.primaryGreen)
                                .matchedGeometryEffect(id: "modeIndicator", in: modeAnimation)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.xs)
        .background(AppColors.backgroundCard)
        .clipShape(Capsule())
    }

    // MARK: - コンテンツセクション

    /// 選択モードに応じたビューを表示
    private var contentSection: some View {
        TabView(selection: $selectedMode) {
            // ノーマル録音モード
            RecordingControlsView()
                .tag(RecordingMode.normal)

            // ループ録音モード
            LoopRecorderView()
                .tag(RecordingMode.loop)

            // マルチトラックモード
            MultiTrackView()
                .tag(RecordingMode.multiTrack)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(AppAnimation.spring, value: selectedMode)
    }
}

// MARK: - プレビュー

#Preview {
    RecordingView()
        .environmentObject(AudioManager())
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
