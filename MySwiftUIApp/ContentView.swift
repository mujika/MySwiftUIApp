import SwiftUI

// MARK: - メインコンテンツビュー
/// アプリ全体のコンテナ。SpotifyTabBarによる4タブ構成と
/// ミニプレイヤーバーを管理するルートビュー

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var audioPlayerManager = AudioPlayerManager()
    @StateObject private var appState = AppState()

    /// 現在選択中のタブ
    @State private var selectedTab: SpotifyTabBar.Tab = .home

    /// フルスクリーンプレイヤー表示フラグ
    @State private var showFullPlayer: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // メイン背景
            AppColors.background
                .ignoresSafeArea()

            // タブコンテンツ
            VStack(spacing: 0) {
                // 選択中のタブに応じたビューを表示
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer(minLength: 0)
            }
            // タブバー＋ミニプレイヤー分のパディングを確保
            .padding(.bottom, miniPlayerAndTabBarHeight)

            // タブバー（ミニプレイヤー内蔵）
            VStack(spacing: 0) {
                Spacer()
                SpotifyTabBar(
                    selectedTab: $selectedTab,
                    showMiniPlayer: appState.currentRecording != nil,
                    onMiniPlayerTap: {
                        showFullPlayer = true
                    }
                )
                .overlay(alignment: .top) {
                    // カスタムミニプレイヤー（録音選択時のみ表示）
                    if let recording = appState.currentRecording {
                        miniPlayerBar(for: recording)
                            .offset(y: -56)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .environmentObject(audioManager)
        .environmentObject(audioPlayerManager)
        .environmentObject(appState)
        .task {
            // マイク使用許可をリクエスト
            await audioManager.requestPermission()
        }
        .onChange(of: audioPlayerManager.isPlaying) { _, newValue in
            // プレイヤーの再生状態をAppStateに反映
            appState.isPlaying = newValue
        }
        .onChange(of: audioPlayerManager.currentTime) { _, newValue in
            appState.currentPlaybackTime = newValue
        }
        .onChange(of: audioPlayerManager.duration) { _, newValue in
            appState.currentPlaybackDuration = newValue
        }
        .onChange(of: audioPlayerManager.currentRecording) { _, newValue in
            // AudioPlayerManagerの現在録音をAppStateに同期
            if newValue == nil {
                appState.currentRecording = nil
                appState.isPlaying = false
            }
        }
        .sheet(isPresented: $showFullPlayer) {
            if let recording = appState.currentRecording {
                FullPlayerView(recording: recording)
                    .environmentObject(audioPlayerManager)
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - タブコンテンツ切り替え

    /// 選択中のタブに対応するビューを返す
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView()
                .transition(.opacity)
        case .record:
            RecordingControlsView()
                .transition(.opacity)
        case .tools:
            ToolsView(effectsChain: audioManager.effectsChain)
                .transition(.opacity)
        case .library:
            LibraryView()
                .transition(.opacity)
        }
    }

    // MARK: - ミニプレイヤーバー

    /// 録音再生中に表示されるミニプレイヤー
    private func miniPlayerBar(for recording: Recording) -> some View {
        Button {
            showFullPlayer = true
        } label: {
            VStack(spacing: 0) {
                // 再生プログレスバー
                GeometryReader { geometry in
                    Rectangle()
                        .fill(AppColors.primaryGreen)
                        .frame(
                            width: geometry.size.width * appState.playbackProgress,
                            height: 2
                        )
                }
                .frame(height: 2)

                HStack(spacing: AppSpacing.sm) {
                    // 波形サムネイル
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(AppColors.backgroundCard)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "waveform")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.primaryGreen)
                        )

                    // 録音情報
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recording.displayName)
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)

                        Text(formatPlaybackTime(appState.currentPlaybackTime, total: appState.currentPlaybackDuration))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    // 再生/一時停止ボタン
                    Button {
                        if appState.isPlaying {
                            audioPlayerManager.pause()
                        } else {
                            audioPlayerManager.play(recording: recording)
                        }
                    } label: {
                        Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, AppSpacing.xs)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
            }
            .background(AppColors.backgroundElevated)
        }
        .buttonStyle(.plain)
    }

    // MARK: - ヘルパー

    /// ミニプレイヤーとタブバーの合計高さ
    private var miniPlayerAndTabBarHeight: CGFloat {
        let tabBarHeight: CGFloat = 80
        let miniPlayerHeight: CGFloat = appState.currentRecording != nil ? 56 : 0
        return tabBarHeight + miniPlayerHeight
    }

    /// 再生時間をフォーマットする
    private func formatPlaybackTime(_ current: TimeInterval, total: TimeInterval) -> String {
        let currentMinutes = Int(current) / 60
        let currentSeconds = Int(current) % 60
        let totalMinutes = Int(total) / 60
        let totalSeconds = Int(total) % 60
        return String(format: "%d:%02d / %d:%02d", currentMinutes, currentSeconds, totalMinutes, totalSeconds)
    }
}

// MARK: - フルスクリーンプレイヤービュー
/// 録音の詳細再生画面（シート表示）

struct FullPlayerView: View {
    let recording: Recording
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                // ドラッグハンドル
                Capsule()
                    .fill(AppColors.textTertiary)
                    .frame(width: 40, height: 5)
                    .padding(.top, AppSpacing.sm)

                Spacer()

                // 大きな波形サムネイル
                RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                    .fill(AppColors.backgroundCard)
                    .frame(width: 280, height: 280)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 80))
                            .foregroundColor(AppColors.primaryGreen.opacity(0.6))
                    )
                    .themeShadow(.strong)

                // 録音名
                VStack(spacing: AppSpacing.xs) {
                    Text(recording.displayName)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    Text(recording.formattedDuration)
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textSecondary)
                }

                // プログレスバー
                VStack(spacing: AppSpacing.xs) {
                    Slider(
                        value: Binding(
                            get: { appState.playbackProgress },
                            set: { newValue in
                                let seekTime = newValue * appState.currentPlaybackDuration
                                audioPlayerManager.seek(to: seekTime)
                            }
                        ),
                        in: 0...1
                    )
                    .tint(AppColors.primaryGreen)

                    HStack {
                        Text(formatTime(appState.currentPlaybackTime))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(formatTime(appState.currentPlaybackDuration))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)

                // 再生コントロール
                HStack(spacing: AppSpacing.xxl) {
                    // 10秒巻き戻し
                    Button {
                        let newTime = max(0, appState.currentPlaybackTime - 10)
                        audioPlayerManager.seek(to: newTime)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.textPrimary)
                    }

                    // 再生/一時停止
                    Button {
                        if appState.isPlaying {
                            audioPlayerManager.pause()
                        } else {
                            audioPlayerManager.play(recording: recording)
                        }
                    } label: {
                        Image(systemName: appState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(AppColors.textPrimary)
                    }

                    // 10秒早送り
                    Button {
                        let newTime = min(appState.currentPlaybackDuration, appState.currentPlaybackTime + 10)
                        audioPlayerManager.seek(to: newTime)
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                // 再生速度選択
                HStack(spacing: AppSpacing.md) {
                    ForEach(AudioPlayerManager.availableRates, id: \.self) { rate in
                        Button {
                            audioPlayerManager.setRate(rate)
                        } label: {
                            Text(rate == 1.0 ? "1x" : String(format: "%.1fx", rate))
                                .font(AppTypography.caption)
                                .fontWeight(audioPlayerManager.playbackRate == rate ? .bold : .regular)
                                .foregroundColor(
                                    audioPlayerManager.playbackRate == rate
                                        ? AppColors.primaryGreen
                                        : AppColors.textTertiary
                                )
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(
                                    Capsule()
                                        .fill(
                                            audioPlayerManager.playbackRate == rate
                                                ? AppColors.primaryGreen.opacity(0.15)
                                                : Color.clear
                                        )
                                )
                        }
                    }
                }

                Spacer()
            }
        }
        .presentationDragIndicator(.hidden)
    }

    /// 秒数を「M:SS」にフォーマットする
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - プレビュー

#Preview {
    ContentView()
}
