import SwiftUI

// MARK: - プレイリスト詳細ビュー
/// プレイリスト内の録音一覧を表示・管理する画面
/// ドラッグ並べ替え、削除、編集機能を提供する

struct PlaylistDetailView: View {
    /// 表示するプレイリスト
    let playlist: Playlist

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager

    /// 編集シート表示フラグ
    @State private var showEditSheet: Bool = false

    /// 編集モード
    @State private var editMode: EditMode = .inactive

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // プレイリストヘッダー
                playlistHeader

                // 録音リスト
                if playlistRecordings.isEmpty {
                    emptyPlaylistView
                } else {
                    recordingList
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showEditSheet) {
            EditPlaylistSheet(playlist: currentPlaylist)
                .environmentObject(appState)
        }
    }

    // MARK: - プレイリストヘッダー

    /// プレイリスト名、アイコン、録音件数を表示するヘッダー
    private var playlistHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // カバーアイコン
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(Color(hex: currentPlaylist.coverColor))
                .frame(width: 140, height: 140)
                .overlay(
                    Image(systemName: currentPlaylist.icon)
                        .font(.system(size: 56))
                        .foregroundColor(.white.opacity(0.9))
                )
                .themeShadow(.medium)

            // プレイリスト名
            Text(currentPlaylist.name)
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)

            // 録音件数
            Text("\(playlistRecordings.count)曲")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)

            // シャッフル再生ボタン
            if !playlistRecordings.isEmpty {
                GradientButton(title: "シャッフル再生", icon: "shuffle") {
                    if let random = playlistRecordings.randomElement() {
                        playRecording(random)
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - 録音リスト

    /// プレイリスト内の録音リスト（ドラッグ並べ替え対応）
    private var recordingList: some View {
        List {
            ForEach(playlistRecordings) { recording in
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
                    // プレイリストから削除
                    Button(role: .destructive) {
                        appState.removeFromPlaylist(
                            recordingId: recording.id,
                            playlistId: playlist.id
                        )
                    } label: {
                        Label("削除", systemImage: "minus.circle")
                    }
                }
            }
            .onMove { source, destination in
                moveRecordings(from: source, to: destination)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - 空のプレイリスト

    /// プレイリストに録音がない場合の表示
    private var emptyPlaylistView: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)

            Text("このプレイリストは空です")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)

            Text("ライブラリから録音を追加しましょう")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - 計算プロパティ

    /// 最新のプレイリスト状態を取得する
    private var currentPlaylist: Playlist {
        appState.playlists.first { $0.id == playlist.id } ?? playlist
    }

    /// プレイリスト内の録音を取得する
    private var playlistRecordings: [Recording] {
        appState.recordingsForPlaylist(playlist.id)
    }

    // MARK: - アクション

    /// 録音を再生する
    private func playRecording(_ recording: Recording) {
        appState.currentRecording = recording
        audioPlayerManager.play(recording: recording)
    }

    /// 録音の順序を変更する
    private func moveRecordings(from source: IndexSet, to destination: Int) {
        guard let index = appState.playlists.firstIndex(where: { $0.id == playlist.id }) else {
            return
        }
        appState.playlists[index].moveRecordings(from: source, to: destination)
    }
}

// MARK: - プレイリスト編集シート

/// プレイリストの名前とカラーを変更するシート
struct EditPlaylistSheet: View {
    let playlist: Playlist
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColor: String = ""
    @State private var selectedIcon: String = ""

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
            .navigationTitle("プレイリストを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        guard !name.isEmpty else { return }
                        if let index = appState.playlists.firstIndex(where: { $0.id == playlist.id }) {
                            appState.playlists[index].name = name
                            appState.playlists[index].coverColor = selectedColor
                            appState.playlists[index].icon = selectedIcon
                        }
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryGreen)
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = playlist.name
                selectedColor = playlist.coverColor
                selectedIcon = playlist.icon
            }
        }
    }
}

// MARK: - プレビュー

#Preview {
    NavigationStack {
        PlaylistDetailView(
            playlist: Playlist(name: "練習曲", coverColor: "#4A90D9", icon: "guitars")
        )
        .environmentObject(AppState())
        .environmentObject(AudioPlayerManager())
    }
    .preferredColorScheme(.dark)
}
