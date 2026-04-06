import SwiftUI

// MARK: - 録音リストビュー（互換性維持用リダイレクト）
/// LibraryViewへのリダイレクト。旧コードとの互換性を維持する

struct RecordingListView: View {
    var body: some View {
        LibraryView()
    }
}

// MARK: - プレビュー

#Preview {
    RecordingListView()
        .environmentObject(AudioManager())
        .environmentObject(AudioPlayerManager())
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
