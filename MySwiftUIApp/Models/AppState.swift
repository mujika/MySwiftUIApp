import Foundation
import AVFoundation
import SwiftUI

// MARK: - アプリ全体の状態管理

/// グローバルなアプリ状態を管理するObservableObject
/// 録音、プレイリスト、プリセット、再生状態を一元管理する
@MainActor
class AppState: ObservableObject {

    // MARK: - 再生状態

    /// 現在選択中の録音（再生対象）
    @Published var currentRecording: Recording?

    /// 再生中かどうか
    @Published var isPlaying: Bool = false

    /// 現在の再生位置（秒）
    @Published var currentPlaybackTime: TimeInterval = 0

    /// 現在再生中の録音の長さ（秒）
    @Published var currentPlaybackDuration: TimeInterval = 0

    /// 再生進捗（0.0〜1.0）
    var playbackProgress: Double {
        guard currentPlaybackDuration > 0 else { return 0 }
        return min(1.0, currentPlaybackTime / currentPlaybackDuration)
    }

    // MARK: - プリセット・エフェクト

    /// 現在選択中のエフェクトプリセット
    @Published var currentPreset: Preset

    // MARK: - データコレクション

    /// プレイリスト一覧
    @Published var playlists: [Playlist] = []

    /// 全録音データ
    @Published var allRecordings: [Recording] = []

    /// 検索クエリ
    @Published var searchQuery: String = ""

    // MARK: - 計算プロパティ

    /// 最近の録音（最大10件、日付降順）
    var recentRecordings: [Recording] {
        return Array(
            allRecordings
                .sorted { $0.creationDate > $1.creationDate }
                .prefix(10)
        )
    }

    /// お気に入りの録音
    var favoriteRecordings: [Recording] {
        return allRecordings.filter { $0.isFavorite }
    }

    /// 検索結果（searchQueryが空の場合は全録音を返す）
    var filteredRecordings: [Recording] {
        guard !searchQuery.isEmpty else { return allRecordings }
        let query = searchQuery.lowercased()
        return allRecordings.filter { recording in
            recording.displayName.lowercased().contains(query) ||
            recording.notes.lowercased().contains(query) ||
            recording.tags.contains { $0.lowercased().contains(query) }
        }
    }

    // MARK: - 永続化用のファイルパス

    /// プレイリストデータの保存先
    private var playlistsFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("playlists.json")
    }

    /// 録音メタデータの保存先（お気に入り、タグ等）
    private var recordingMetadataFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("recording_metadata.json")
    }

    /// ユーザープリセットの保存先
    private var userPresetsFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("user_presets.json")
    }

    // MARK: - イニシャライザ

    init() {
        // デフォルトプリセットはCleanで初期化
        self.currentPreset = Preset.cleanPreset
        loadPlaylists()
        loadAllRecordings()
        loadRecordingMetadata()
    }

    // MARK: - 録音管理

    /// ドキュメントディレクトリから全録音ファイルを読み込む
    func loadAllRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )

            // 対応する拡張子のファイルのみフィルタリング
            let supportedExtensions = RecordingFormat.allCases.map { $0.fileExtension }
            let audioFiles = files.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }

            allRecordings = audioFiles.compactMap { url in
                guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                      let creationDate = attributes[.creationDate] as? Date else {
                    return nil
                }
                return Recording(url: url, creationDate: creationDate)
            }
            .sorted { $0.creationDate > $1.creationDate }

        } catch {
            print("録音ファイルの読み込みに失敗: \(error)")
        }
    }

    /// 録音を検索する
    /// - Parameter query: 検索文字列
    func searchRecordings(query: String) {
        searchQuery = query
    }

    // MARK: - お気に入り管理

    /// 録音のお気に入りを切り替える
    /// - Parameter recording: 対象の録音
    func toggleFavorite(for recording: Recording) {
        guard let index = allRecordings.firstIndex(where: { $0.id == recording.id }) else {
            return
        }
        allRecordings[index].isFavorite.toggle()
        saveRecordingMetadata()
    }

    // MARK: - プレイリスト管理

    /// 新しいプレイリストを作成する
    /// - Parameters:
    ///   - name: プレイリスト名
    ///   - description: 説明文（省略可能）
    ///   - coverColor: カバーカラーのHEXコード（省略可能）
    ///   - icon: SF Symbol名（省略可能）
    /// - Returns: 作成されたプレイリスト
    @discardableResult
    func createPlaylist(
        name: String,
        description: String = "",
        coverColor: String = "#4A90D9",
        icon: String = "music.note.list"
    ) -> Playlist {
        let playlist = Playlist(
            name: name,
            description: description,
            coverColor: coverColor,
            icon: icon
        )
        playlists.append(playlist)
        savePlaylists()
        return playlist
    }

    /// プレイリストを削除する
    /// - Parameter playlistId: 削除するプレイリストのID
    func deletePlaylist(_ playlistId: UUID) {
        playlists.removeAll { $0.id == playlistId }
        savePlaylists()
    }

    /// 録音をプレイリストに追加する
    /// - Parameters:
    ///   - recordingId: 追加する録音のID
    ///   - playlistId: 追加先プレイリストのID
    func addToPlaylist(recordingId: UUID, playlistId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else {
            return
        }
        playlists[index].addRecording(recordingId)

        // 録音にもプレイリストIDを紐付ける
        if let recordingIndex = allRecordings.firstIndex(where: { $0.id == recordingId }) {
            allRecordings[recordingIndex].playlistId = playlistId
        }

        savePlaylists()
        saveRecordingMetadata()
    }

    /// 録音をプレイリストから削除する
    /// - Parameters:
    ///   - recordingId: 削除する録音のID
    ///   - playlistId: 削除元プレイリストのID
    func removeFromPlaylist(recordingId: UUID, playlistId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else {
            return
        }
        playlists[index].removeRecording(recordingId)

        // 録音のプレイリストIDもクリアする（同じプレイリストの場合のみ）
        if let recordingIndex = allRecordings.firstIndex(where: { $0.id == recordingId }),
           allRecordings[recordingIndex].playlistId == playlistId {
            allRecordings[recordingIndex].playlistId = nil
        }

        savePlaylists()
        saveRecordingMetadata()
    }

    /// 指定プレイリストに含まれる録音を取得する
    /// - Parameter playlistId: プレイリストのID
    /// - Returns: プレイリスト内の録音配列
    func recordingsForPlaylist(_ playlistId: UUID) -> [Recording] {
        guard let playlist = playlists.first(where: { $0.id == playlistId }) else {
            return []
        }
        return playlist.recordingIds.compactMap { recordingId in
            allRecordings.first { $0.id == recordingId }
        }
    }

    // MARK: - 永続化（プレイリスト）

    /// プレイリストをJSONファイルに保存する
    private func savePlaylists() {
        do {
            let data = try JSONEncoder().encode(playlists)
            try data.write(to: playlistsFileURL)
        } catch {
            print("プレイリストの保存に失敗: \(error)")
        }
    }

    /// JSONファイルからプレイリストを読み込む
    private func loadPlaylists() {
        guard FileManager.default.fileExists(atPath: playlistsFileURL.path) else {
            // 初回起動時はデフォルトプレイリストを作成しない（ユーザーが作成する）
            return
        }

        do {
            let data = try Data(contentsOf: playlistsFileURL)
            playlists = try JSONDecoder().decode([Playlist].self, from: data)
        } catch {
            print("プレイリストの読み込みに失敗: \(error)")
        }
    }

    // MARK: - 永続化（録音メタデータ）

    /// 録音のメタデータ（お気に入り、タグ、メモ等）を保存するための軽量構造体
    private struct RecordingMetadata: Codable {
        let id: UUID
        var fileName: String
        var isFavorite: Bool
        var tags: [String]
        var playlistId: UUID?
        var notes: String
    }

    /// 録音メタデータをJSONファイルに保存する
    private func saveRecordingMetadata() {
        let metadataList = allRecordings.map { recording in
            RecordingMetadata(
                id: recording.id,
                fileName: recording.fileName,
                isFavorite: recording.isFavorite,
                tags: recording.tags,
                playlistId: recording.playlistId,
                notes: recording.notes
            )
        }

        do {
            let data = try JSONEncoder().encode(metadataList)
            try data.write(to: recordingMetadataFileURL)
        } catch {
            print("録音メタデータの保存に失敗: \(error)")
        }
    }

    /// JSONファイルから録音メタデータを読み込み、既存の録音に適用する
    private func loadRecordingMetadata() {
        guard FileManager.default.fileExists(atPath: recordingMetadataFileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: recordingMetadataFileURL)
            let metadataList = try JSONDecoder().decode([RecordingMetadata].self, from: data)

            // URLのlastPathComponentをキーにしてメタデータをマッチさせる
            // （UUIDは毎回新規生成されるため、ファイル名でマッチング）
            let metadataByFileName = Dictionary(
                uniqueKeysWithValues: metadataList.map {
                    ($0.fileName, $0)
                }
            )

            // URLのlastPathComponentでもマッチングを試みる
            for i in allRecordings.indices {
                let urlFileName = allRecordings[i].url.lastPathComponent
                // fileNameが一致するメタデータを検索
                if let metadata = metadataByFileName[urlFileName] ??
                    metadataList.first(where: { $0.fileName == allRecordings[i].fileName }) {
                    allRecordings[i].fileName = metadata.fileName
                    allRecordings[i].isFavorite = metadata.isFavorite
                    allRecordings[i].tags = metadata.tags
                    allRecordings[i].playlistId = metadata.playlistId
                    allRecordings[i].notes = metadata.notes
                }
            }
        } catch {
            print("録音メタデータの読み込みに失敗: \(error)")
        }
    }

    // MARK: - ユーザープリセット管理

    /// ユーザー作成プリセットを保存する
    func saveUserPresets(_ presets: [Preset]) {
        let userPresets = presets.filter { !$0.isFactory }
        do {
            let data = try JSONEncoder().encode(userPresets)
            try data.write(to: userPresetsFileURL)
        } catch {
            print("ユーザープリセットの保存に失敗: \(error)")
        }
    }

    /// ユーザー作成プリセットを読み込む
    /// - Returns: ファクトリープリセット + ユーザープリセットの結合配列
    func loadAllPresets() -> [Preset] {
        var allPresets = Preset.factoryPresets

        guard FileManager.default.fileExists(atPath: userPresetsFileURL.path) else {
            return allPresets
        }

        do {
            let data = try Data(contentsOf: userPresetsFileURL)
            let userPresets = try JSONDecoder().decode([Preset].self, from: data)
            allPresets.append(contentsOf: userPresets)
        } catch {
            print("ユーザープリセットの読み込みに失敗: \(error)")
        }

        return allPresets
    }
}
