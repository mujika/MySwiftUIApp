import Foundation
import SwiftUI

// MARK: - ソート順列挙型

/// プレイリスト内の録音の並び順を定義
enum PlaylistSortOrder: String, Codable, CaseIterable {
    case dateDesc = "新しい順"
    case dateAsc = "古い順"
    case nameAsc = "名前（A→Z）"
    case nameDesc = "名前（Z→A）"
    case durationDesc = "長い順"

    /// 表示用の名前
    var displayName: String {
        return rawValue
    }

    /// SF Symbolのアイコン名
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

// MARK: - プレイリストモデル

/// 録音を整理するためのプレイリスト/フォルダモデル
/// Spotify風のプレイリスト管理を実現する
struct Playlist: Identifiable, Codable {
    /// 一意識別子
    let id: UUID

    /// プレイリスト名
    var name: String

    /// プレイリストの説明文
    var description: String

    /// カバー表示用のHEXカラーコード（例: "#FF6B6B"）
    var coverColor: String

    /// SF Symbolのアイコン名
    var icon: String

    /// 作成日時
    let creationDate: Date

    /// 含まれる録音のID一覧（順序を保持）
    var recordingIds: [UUID]

    /// 並び順設定
    var sortOrder: PlaylistSortOrder

    // MARK: - 計算プロパティ

    /// プレイリスト内の録音件数
    var recordingCount: Int {
        return recordingIds.count
    }

    // MARK: - イニシャライザ

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        coverColor: String = "#4A90D9",
        icon: String = "music.note.list",
        creationDate: Date = Date(),
        recordingIds: [UUID] = [],
        sortOrder: PlaylistSortOrder = .dateDesc
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.coverColor = coverColor
        self.icon = icon
        self.creationDate = creationDate
        self.recordingIds = recordingIds
        self.sortOrder = sortOrder
    }

    // MARK: - 録音管理メソッド

    /// 録音をプレイリストに追加する
    /// - Parameter recordingId: 追加する録音のID
    mutating func addRecording(_ recordingId: UUID) {
        // 重複を防止
        guard !recordingIds.contains(recordingId) else { return }
        recordingIds.append(recordingId)
    }

    /// 録音をプレイリストから削除する
    /// - Parameter recordingId: 削除する録音のID
    mutating func removeRecording(_ recordingId: UUID) {
        recordingIds.removeAll { $0 == recordingId }
    }

    /// 録音がプレイリストに含まれているか判定する
    /// - Parameter recordingId: 確認する録音のID
    /// - Returns: 含まれている場合true
    func containsRecording(_ recordingId: UUID) -> Bool {
        return recordingIds.contains(recordingId)
    }

    /// 録音の順序を入れ替える
    /// - Parameters:
    ///   - source: 移動元のインデックスセット
    ///   - destination: 移動先のインデックス
    mutating func moveRecordings(from source: IndexSet, to destination: Int) {
        recordingIds.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - デフォルトプレイリスト

    /// 「全ての録音」仮想プレイリスト用のID
    static let allRecordingsId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// 「お気に入り」仮想プレイリスト用のID
    static let favoritesId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    /// 「最近の録音」仮想プレイリスト用のID
    static let recentsId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

    /// デフォルトのシステムプレイリスト一覧を返す
    static var defaultPlaylists: [Playlist] {
        return [
            Playlist(
                id: allRecordingsId,
                name: "すべての録音",
                description: "すべての録音ファイル",
                coverColor: "#4A90D9",
                icon: "music.note.list",
                sortOrder: .dateDesc
            ),
            Playlist(
                id: favoritesId,
                name: "お気に入り",
                description: "お気に入りの録音",
                coverColor: "#FF6B6B",
                icon: "heart.fill",
                sortOrder: .dateDesc
            ),
            Playlist(
                id: recentsId,
                name: "最近の録音",
                description: "最近10件の録音",
                coverColor: "#50C878",
                icon: "clock.fill",
                sortOrder: .dateDesc
            )
        ]
    }

    /// プリセットカラー一覧（プレイリスト作成時の選択肢）
    static let availableColors: [String] = [
        "#4A90D9",  // ブルー
        "#FF6B6B",  // レッド
        "#50C878",  // グリーン
        "#FFD700",  // ゴールド
        "#9B59B6",  // パープル
        "#FF8C00",  // オレンジ
        "#1ABC9C",  // ティール
        "#E91E63",  // ピンク
        "#607D8B",  // グレー
        "#795548"   // ブラウン
    ]
}
