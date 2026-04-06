import SwiftUI

// MARK: - ホームビュー
/// Spotify風のホーム画面。時間帯に応じた挨拶、最近の録音、
/// お気に入り、プレイリスト、クイックアクションを表示する

struct HomeView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var appState: AppState

    /// 設定画面表示フラグ
    @State private var showSettings: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // 挨拶ヘッダー
                    greetingHeader
                        .padding(.top, AppSpacing.md)

                    // クイックアクション
                    quickActionsSection

                    // 最近の録音がない場合は空の状態を表示
                    if appState.allRecordings.isEmpty {
                        emptyStateView
                    } else {
                        // 最近の録音セクション
                        recentRecordingsSection

                        // お気に入りセクション
                        if !appState.favoriteRecordings.isEmpty {
                            favoritesSection
                        }

                        // プレイリストセクション
                        if !appState.playlists.isEmpty {
                            playlistsSection
                        }
                    }

                    // タブバー分の余白
                    Spacer(minLength: AppSpacing.xxl)
                }
            }
            .refreshable {
                // 録音データを再読み込み
                appState.loadAllRecordings()
            }
            .background(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - 挨拶ヘッダー

    /// 時間帯に応じた挨拶メッセージを表示する
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(greetingText)
                .font(AppTypography.largeTitle)
                .foregroundColor(AppColors.textPrimary)

            if !appState.allRecordings.isEmpty {
                Text("\(appState.allRecordings.count)件の録音")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    /// 時間帯による挨拶文を返す
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "おはよう"
        case 12..<17:
            return "こんにちは"
        default:
            return "こんばんは"
        }
    }

    // MARK: - クイックアクション

    /// 新規録音・チューナー・メトロノームへのショートカットカード
    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                QuickActionCard(
                    title: "新規録音",
                    icon: "mic.fill",
                    color: AppColors.primaryGreen
                ) {
                    // 録音タブへの遷移は親ビューのタブで制御
                }

                QuickActionCard(
                    title: "チューナー",
                    icon: "tuningfork",
                    color: AppColors.info
                ) {
                    // チューナー画面遷移
                }

                QuickActionCard(
                    title: "メトロノーム",
                    icon: "metronome.fill",
                    color: AppColors.warning
                ) {
                    // メトロノーム画面遷移
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - 最近の録音

    /// 最近の録音をサムネイルカードで横スクロール表示する
    private var recentRecordingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                title: "最近の録音",
                showSeeAll: appState.recentRecordings.count > 4,
                onSeeAllTap: {
                    // ライブラリへ遷移
                }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(appState.recentRecordings) { recording in
                        RecordingThumbnail(
                            title: recording.displayName,
                            duration: recording.formattedDuration,
                            date: formatRelativeDate(recording.creationDate),
                            waveformData: (recording.waveformData ?? []).map { CGFloat($0) },
                            isPlaying: audioPlayerManager.currentRecording?.id == recording.id
                        ) {
                            playRecording(recording)
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    // MARK: - お気に入り

    /// お気に入り録音をサムネイルカードで横スクロール表示する
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                title: "お気に入り",
                showSeeAll: appState.favoriteRecordings.count > 4,
                onSeeAllTap: {
                    // ライブラリのお気に入りフィルタへ遷移
                }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(appState.favoriteRecordings) { recording in
                        RecordingThumbnail(
                            title: recording.displayName,
                            duration: recording.formattedDuration,
                            date: formatRelativeDate(recording.creationDate),
                            waveformData: (recording.waveformData ?? []).map { CGFloat($0) },
                            isPlaying: audioPlayerManager.currentRecording?.id == recording.id
                        ) {
                            playRecording(recording)
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    // MARK: - プレイリスト

    /// プレイリストを横スクロールのカードで表示する
    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "プレイリスト")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(appState.playlists) { playlist in
                        PlaylistCard(playlist: playlist)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    // MARK: - 空の状態

    /// 録音がない場合に表示するイラスト付きメッセージ
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer(minLength: AppSpacing.xxl)

            // マイクイラスト
            ZStack {
                Circle()
                    .fill(AppColors.backgroundCard)
                    .frame(width: 120, height: 120)

                Image(systemName: "mic.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.primaryGreen.opacity(0.6))
            }

            VStack(spacing: AppSpacing.sm) {
                Text("まだ録音がありません")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Text("マイクボタンを押して\n最初の録音を始めましょう")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            GradientButton(title: "録音を開始", icon: "mic.fill") {
                // 録音タブに遷移
            }

            Spacer(minLength: AppSpacing.xxl)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - ヘルパー

    /// 録音を再生する（AppStateの現在録音を更新してプレイヤーを開始）
    private func playRecording(_ recording: Recording) {
        appState.currentRecording = recording
        audioPlayerManager.play(recording: recording)
    }

    /// 日付を相対的な文字列にフォーマットする
    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

// MARK: - クイックアクションカード

/// ホーム画面のショートカットカードコンポーネント
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
            .background(AppColors.backgroundCard)
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - プレイリストカード

/// ホーム画面に表示するプレイリストカード
struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // カバーアイコン
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(Color(hex: playlist.coverColor).opacity(0.8))
                .frame(width: 140, height: 140)
                .overlay(
                    Image(systemName: playlist.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.9))
                )

            // プレイリスト名
            Text(playlist.name)
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)

            // 録音件数
            Text("\(playlist.recordingCount)曲")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(width: 140)
    }
}

// MARK: - プレビュー

#Preview {
    HomeView()
        .environmentObject(AudioManager())
        .environmentObject(AudioPlayerManager())
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
