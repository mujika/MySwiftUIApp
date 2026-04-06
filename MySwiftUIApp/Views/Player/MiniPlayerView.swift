import SwiftUI

// MARK: - ミニプレイヤービュー
/// タブバー上部に表示するコンパクトな再生コントロールバー
/// タップでフルスクリーンのNowPlayingViewを展開する
struct MiniPlayerView: View {

    // MARK: - 環境オブジェクト

    /// オーディオ再生マネージャー
    @EnvironmentObject var playerManager: AudioPlayerManager

    /// アプリ全体の状態
    @EnvironmentObject var appState: AppState

    // MARK: - 状態

    /// NowPlayingViewの表示フラグ
    @State var showNowPlaying: Bool = false

    /// 再生ボタンのスケールアニメーション用
    @State private var playButtonScale: CGFloat = 1.0

    /// ミニプレイヤーの高さ
    private let playerHeight: CGFloat = 64

    // MARK: - ボディ

    var body: some View {
        // 再生中の録音がない場合は非表示
        if let recording = playerManager.currentRecording {
            VStack(spacing: 0) {
                // タップで全画面プレイヤーを開く
                Button {
                    showNowPlaying = true
                } label: {
                    playerContent(recording: recording)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    // 上スワイプでNowPlayingを表示
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            if value.translation.height < -30 {
                                showNowPlaying = true
                            }
                        }
                )

                // 下部のプログレスバー
                progressBar
            }
            .background(
                // グラスモーフィズム背景
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                // 上部ボーダー
                VStack {
                    AppColors.separator
                        .frame(height: 0.5)
                    Spacer()
                }
            )
            .fullScreenCover(isPresented: $showNowPlaying) {
                NowPlayingView()
                    .environmentObject(playerManager)
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - プレイヤーコンテンツ

    /// ミニプレイヤーの主要コンテンツ（サムネイル + 情報 + 再生ボタン）
    private func playerContent(recording: Recording) -> some View {
        HStack(spacing: AppSpacing.sm) {
            // 波形サムネイル
            waveformThumbnail(recording: recording)

            // 録音情報
            recordingInfo(recording: recording)

            Spacer()

            // 再生/一時停止ボタン
            playPauseButton
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: playerHeight)
    }

    // MARK: - 波形サムネイル

    /// 小さな波形プレビューサムネイル
    private func waveformThumbnail(recording: Recording) -> some View {
        RoundedRectangle(cornerRadius: AppCornerRadius.small)
            .fill(AppColors.backgroundCard)
            .frame(width: 32, height: 32)
            .overlay(
                // ミニ波形を描画
                miniWaveform(recording: recording)
                    .padding(4)
            )
            .overlay(
                // 再生中は緑のグロー
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .stroke(
                        playerManager.isPlaying ? AppColors.primaryGreen.opacity(0.6) : Color.clear,
                        lineWidth: 1
                    )
            )
    }

    /// サムネイル内のミニ波形描画
    private func miniWaveform(recording: Recording) -> some View {
        GeometryReader { geometry in
            let data = recording.waveformData ?? generateMiniPlaceholder()
            let barCount = 8
            let samples = resampleData(data, to: barCount)
            let barWidth: CGFloat = 2
            let spacing: CGFloat = 1

            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<samples.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(AppColors.primaryGreen)
                        .frame(
                            width: barWidth,
                            height: max(2, geometry.size.height * CGFloat(samples[index]) * 0.8)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 録音情報

    /// 録音名と再生時間テキスト
    private func recordingInfo(recording: Recording) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(recording.displayName)
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)

            Text("\(formatTime(playerManager.currentTime)) / \(formatTime(playerManager.duration))")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .monospacedDigit()
        }
    }

    // MARK: - 再生/一時停止ボタン

    /// 再生状態をトグルするボタン
    private var playPauseButton: some View {
        Button {
            withAnimation(AppAnimation.fast) {
                playButtonScale = 0.85
            }

            if playerManager.isPlaying {
                playerManager.pause()
            } else if let recording = playerManager.currentRecording {
                playerManager.play(recording: recording)
            }

            // バウンスアニメーション
            withAnimation(AppAnimation.spring) {
                playButtonScale = 1.0
            }
        } label: {
            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 22))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 44, height: 44)
                .scaleEffect(playButtonScale)
        }
        .buttonStyle(.plain)
    }

    // MARK: - プログレスバー

    /// 下部の薄いプログレスバー
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景トラック
                Rectangle()
                    .fill(AppColors.backgroundInput.opacity(0.5))

                // 再生済みバー
                Rectangle()
                    .fill(AppColors.primaryGreen)
                    .frame(width: geometry.size.width * playerManager.playbackProgress)
                    .animation(AppAnimation.fast, value: playerManager.playbackProgress)
            }
        }
        .frame(height: 2)
    }

    // MARK: - ユーティリティ

    /// プレースホルダーのミニ波形データを生成
    private func generateMiniPlaceholder() -> [Float] {
        (0..<8).map { i in
            0.3 + 0.5 * abs(sin(Float(i) / 8.0 * .pi * 2))
        }
    }

    /// データを指定数にリサンプリングする
    private func resampleData(_ data: [Float], to count: Int) -> [Float] {
        guard !data.isEmpty, count > 0 else { return Array(repeating: 0.3, count: count) }
        return (0..<count).map { index in
            let sourceIndex = Float(index) / Float(count) * Float(data.count)
            let lower = Int(sourceIndex)
            let upper = min(lower + 1, data.count - 1)
            let fraction = sourceIndex - Float(lower)
            return data[lower] * (1 - fraction) + data[upper] * fraction
        }
    }

    /// TimeIntervalをM:SS形式にフォーマットする
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - プレビュー
#Preview("MiniPlayer") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        VStack {
            Spacer()
            MiniPlayerView()
                .environmentObject({
                    let manager = AudioPlayerManager()
                    return manager
                }())
                .environmentObject(AppState())
        }
    }
    .preferredColorScheme(.dark)
}
