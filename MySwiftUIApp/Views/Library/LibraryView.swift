import SwiftUI

// MARK: - ライブラリビュー
/// Spotify風の録音ライブラリ画面。検索、フィルタリング、
/// ソート、スワイプアクション、コンテキストメニューを提供する

struct LibraryView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var appState: AppState

    /// 検索テキスト
    @State private var searchText: String = ""

    /// 選択中のフィルタ
    @State private var selectedFilter: LibraryFilter = .all

    /// ソート順
    @State private var sortOrder: LibrarySortOrder = .dateDesc

    /// ソートメニュー表示フラグ
    @State private var showSortMenu: Bool = false

    /// プレイリスト作成シート表示フラグ
    @State private var showCreatePlaylist: Bool = false

    /// リネームダイアログ用
    @State private var recordingToRename: Recording?
    @State private var renameText: String = ""
    @State private var showRenameDialog: Bool = false

    /// プレイリスト追加ダイアログ用
    @State private var recordingForPlaylist: Recording?
    @State private var showPlaylistPicker: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 検索バー
                    searchBar

                    // フィルタチップ
                    filterChips

                    // 録音リスト
                    if filteredAndSortedRecordings.isEmpty {
                        emptyFilterView
                    } else {
                        recordingList
                    }
                }
            }
            .navigationTitle("ライブラリ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // ソートボタン
                    Menu {
                        ForEach(LibrarySortOrder.allCases, id: \.self) { order in
                            Button {
                                withAnimation(AppAnimation.standard) {
                                    sortOrder = order
                                }
                            } label: {
                                Label(
                                    order.displayName,
                                    systemImage: sortOrder == order ? "checkmark" : order.iconName
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    // プレイリスト作成ボタン
                    Button {
                        showCreatePlaylist = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showCreatePlaylist) {
                CreatePlaylistSheet()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showPlaylistPicker) {
                PlaylistPickerSheet(recording: recordingForPlaylist)
                    .environmentObject(appState)
            }
            .alert("録音の名前を変更", isPresented: $showRenameDialog) {
                TextField("新しい名前", text: $renameText)
                Button("キャンセル", role: .cancel) {}
                Button("変更") {
                    if let recording = recordingToRename,
                       let index = appState.allRecordings.firstIndex(where: { $0.id == recording.id }) {
                        appState.allRecordings[index].fileName = renameText
                    }
                }
            }
        }
    }

    // MARK: - 検索バー

    /// 録音名・タグで検索するバー
    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textTertiary)

            TextField("録音を検索...", text: $searchText)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
        .background(AppColors.backgroundInput)
        .cornerRadius(AppCornerRadius.medium)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - フィルタチップ

    /// 「すべて」「お気に入り」「プレイリスト」のセグメントフィルタ
    private var filterChips: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(LibraryFilter.allCases, id: \.self) { filter in
                FilterChip(
                    title: filter.displayName,
                    isSelected: selectedFilter == filter
                ) {
                    withAnimation(AppAnimation.standard) {
                        selectedFilter = filter
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - 録音リスト

    /// フィルタ・ソート済みの録音リスト
    private var recordingList: some View {
        List {
            // プレイリスト表示（プレイリストフィルタ選択時）
            if selectedFilter == .playlists {
                ForEach(appState.playlists) { playlist in
                    NavigationLink {
                        PlaylistDetailView(playlist: playlist)
                            .environmentObject(appState)
                            .environmentObject(audioPlayerManager)
                    } label: {
                        PlaylistRow(playlist: playlist)
                    }
                    .listRowBackground(AppColors.backgroundElevated)
                }
            } else {
                // 録音リスト
                ForEach(filteredAndSortedRecordings) { recording in
                    LibraryRecordingRow(
                        recording: recording,
                        isPlaying: audioPlayerManager.currentRecording?.id == recording.id
                    )
                    .listRowBackground(AppColors.backgroundElevated)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        playRecording(recording)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        // 削除
                        Button(role: .destructive) {
                            deleteRecording(recording)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                        // プレイリストに追加
                        Button {
                            recordingForPlaylist = recording
                            showPlaylistPicker = true
                        } label: {
                            Label("追加", systemImage: "text.badge.plus")
                        }
                        .tint(AppColors.info)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        // お気に入り切り替え
                        Button {
                            appState.toggleFavorite(for: recording)
                        } label: {
                            Label(
                                recording.isFavorite ? "解除" : "お気に入り",
                                systemImage: recording.isFavorite ? "heart.slash" : "heart.fill"
                            )
                        }
                        .tint(AppColors.recordingRed)
                    }
                    .contextMenu {
                        // リネーム
                        Button {
                            recordingToRename = recording
                            renameText = recording.displayName
                            showRenameDialog = true
                        } label: {
                            Label("名前を変更", systemImage: "pencil")
                        }

                        // お気に入り
                        Button {
                            appState.toggleFavorite(for: recording)
                        } label: {
                            Label(
                                recording.isFavorite ? "お気に入りを解除" : "お気に入りに追加",
                                systemImage: recording.isFavorite ? "heart.slash" : "heart"
                            )
                        }

                        // プレイリストに追加
                        Button {
                            recordingForPlaylist = recording
                            showPlaylistPicker = true
                        } label: {
                            Label("プレイリストに追加", systemImage: "text.badge.plus")
                        }

                        // 共有
                        ShareLink(item: recording.url) {
                            Label("共有", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        // 削除
                        Button(role: .destructive) {
                            deleteRecording(recording)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - 空のフィルタ状態

    /// フィルタ結果が空の場合の表示
    private var emptyFilterView: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)

            Text(selectedFilter == .favorites ? "お気に入りの録音がありません" : "該当する録音がありません")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)

            Text(selectedFilter == .favorites
                 ? "録音を長押しして、お気に入りに追加しましょう"
                 : "検索条件を変えてみてください")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - 計算プロパティ

    /// フィルタとソートを適用した録音一覧
    private var filteredAndSortedRecordings: [Recording] {
        var recordings: [Recording]

        // フィルタ適用
        switch selectedFilter {
        case .all:
            recordings = appState.allRecordings
        case .favorites:
            recordings = appState.favoriteRecordings
        case .playlists:
            return [] // プレイリストモードでは録音リストは非表示
        }

        // 検索テキストでフィルタ
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            recordings = recordings.filter { recording in
                recording.displayName.lowercased().contains(query) ||
                recording.tags.contains { $0.lowercased().contains(query) }
            }
        }

        // ソート適用
        switch sortOrder {
        case .dateDesc:
            recordings.sort { $0.creationDate > $1.creationDate }
        case .dateAsc:
            recordings.sort { $0.creationDate < $1.creationDate }
        case .nameAsc:
            recordings.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        case .nameDesc:
            recordings.sort { $0.displayName.localizedCompare($1.displayName) == .orderedDescending }
        case .durationDesc:
            recordings.sort { $0.duration > $1.duration }
        }

        return recordings
    }

    // MARK: - アクション

    /// 録音を再生する
    private func playRecording(_ recording: Recording) {
        appState.currentRecording = recording
        audioPlayerManager.play(recording: recording)
    }

    /// 録音を削除する
    private func deleteRecording(_ recording: Recording) {
        audioManager.deleteRecording(recording)
        appState.loadAllRecordings()
    }
}

// MARK: - ライブラリフィルタ列挙型

enum LibraryFilter: CaseIterable {
    case all
    case favorites
    case playlists

    var displayName: String {
        switch self {
        case .all: return "すべて"
        case .favorites: return "お気に入り"
        case .playlists: return "プレイリスト"
        }
    }
}

// MARK: - ライブラリソート順列挙型

enum LibrarySortOrder: CaseIterable {
    case dateDesc
    case dateAsc
    case nameAsc
    case nameDesc
    case durationDesc

    var displayName: String {
        switch self {
        case .dateDesc: return "新しい順"
        case .dateAsc: return "古い順"
        case .nameAsc: return "名前 (A→Z)"
        case .nameDesc: return "名前 (Z→A)"
        case .durationDesc: return "長い順"
        }
    }

    var iconName: String {
        switch self {
        case .dateDesc: return "calendar.badge.clock"
        case .dateAsc: return "calendar"
        case .nameAsc: return "textformat.abc"
        case .nameDesc: return "textformat.abc"
        case .durationDesc: return "timer"
        }
    }
}

// MARK: - フィルタチップコンポーネント

/// セグメントフィルタ用の小さなピル型ボタン
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
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

// MARK: - 録音リスト行コンポーネント

/// ライブラリリストの録音行
struct LibraryRecordingRow: View {
    let recording: Recording
    var isPlaying: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 波形ミニサムネイル
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .fill(isPlaying ? AppColors.primaryGreen.opacity(0.2) : AppColors.backgroundCard)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: isPlaying ? "waveform" : "music.note")
                        .font(.system(size: 18))
                        .foregroundColor(isPlaying ? AppColors.primaryGreen : AppColors.textTertiary)
                )

            // 録音情報
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(recording.displayName)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(isPlaying ? AppColors.primaryGreen : AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xs) {
                    Text(recording.formattedDuration)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text("・")
                        .foregroundColor(AppColors.textTertiary)

                    Text(formatDate(recording.creationDate))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            Spacer()

            // お気に入りアイコン
            if recording.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.recordingRed)
            }

            // 再生中インジケーター
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.primaryGreen)
                    .symbolEffect(.pulse)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    /// 日付をフォーマットする
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - プレイリスト行コンポーネント

/// ライブラリリストのプレイリスト行
struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // カバー
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .fill(Color(hex: playlist.coverColor))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: playlist.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )

            // プレイリスト情報
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(playlist.name)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                Text("\(playlist.recordingCount)曲")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - プレイリスト作成シート

/// 新しいプレイリストを作成するシート
struct CreatePlaylistSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColor: String = Playlist.availableColors[0]
    @State private var selectedIcon: String = "music.note.list"

    /// 利用可能なアイコン一覧
    private let availableIcons = [
        "music.note.list", "guitars", "pianokeys", "mic.fill",
        "headphones", "waveform", "speaker.wave.2.fill", "star.fill"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    // プレビュー
                    RoundedRectangle(cornerRadius: AppCornerRadius.large)
                        .fill(Color(hex: selectedColor))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: selectedIcon)
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                        )
                        .padding(.top, AppSpacing.lg)

                    // 名前入力
                    TextField("プレイリスト名", text: $name)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(AppColors.backgroundInput)
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.horizontal, AppSpacing.lg)

                    // カラー選択
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("カラー")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.lg)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.sm) {
                                ForEach(Playlist.availableColors, id: \.self) { color in
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                        }
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }

                    // アイコン選択
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("アイコン")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.lg)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.md) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(
                                            selectedIcon == icon
                                                ? AppColors.primaryGreen
                                                : AppColors.textTertiary
                                        )
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedIcon == icon
                                                ? AppColors.primaryGreen.opacity(0.15)
                                                : AppColors.backgroundCard
                                        )
                                        .cornerRadius(AppCornerRadius.medium)
                                        .onTapGesture {
                                            selectedIcon = icon
                                        }
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("新規プレイリスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("作成") {
                        guard !name.isEmpty else { return }
                        appState.createPlaylist(
                            name: name,
                            coverColor: selectedColor,
                            icon: selectedIcon
                        )
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryGreen)
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - プレイリスト選択シート

/// 録音をプレイリストに追加するためのシート
struct PlaylistPickerSheet: View {
    let recording: Recording?
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if appState.playlists.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textTertiary)

                        Text("プレイリストがありません")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textSecondary)

                        Text("先にプレイリストを作成してください")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textTertiary)
                    }
                } else {
                    List {
                        ForEach(appState.playlists) { playlist in
                            Button {
                                if let recording = recording {
                                    appState.addToPlaylist(
                                        recordingId: recording.id,
                                        playlistId: playlist.id
                                    )
                                }
                                dismiss()
                            } label: {
                                PlaylistRow(playlist: playlist)
                            }
                            .listRowBackground(AppColors.backgroundElevated)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("プレイリストに追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

// MARK: - プレビュー

#Preview {
    LibraryView()
        .environmentObject(AudioManager())
        .environmentObject(AudioPlayerManager())
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
