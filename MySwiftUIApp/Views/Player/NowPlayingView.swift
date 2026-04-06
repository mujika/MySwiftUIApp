import SwiftUI

// MARK: - フルスクリーンNow Playingビュー
/// Spotify風のフルスクリーン再生画面
/// 波形ビジュアライザー、スクラバー、トランスポートコントロール、速度調整を提供
struct NowPlayingView: View {

    // MARK: - 環境

    /// シート閉じ用
    @Environment(\.dismiss) private var dismiss

    /// オーディオ再生マネージャー
    @EnvironmentObject var playerManager: AudioPlayerManager

    /// アプリ全体の状態
    @EnvironmentObject var appState: AppState

    // MARK: - 状態

    /// 再生ボタンのスケールアニメーション
    @State private var playButtonScale: CGFloat = 1.0

    /// 波形バーのアニメーション用タイマー
    @State private var waveformPhase: Double = 0.0

    /// 選択中の再生速度インデックス
    @State private var selectedRateIndex: Int = 2

    /// 波形データのキャッシュ
    @State private var waveformData: [Float] = []

    /// スピードコントロールの展開フラグ
    @State private var showSpeedControl: Bool = false

    /// 波形パルスアニメーション用タイマー
    private let pulseTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    // MARK: - 定数

    /// 選択可能な再生速度
    private let playbackRates: [Float] = AudioPlayerManager.availableRates

    // MARK: - ボディ

    var body: some View {
        ZStack {
            // 背景グラデーション
            backgroundGradient

            // メインコンテンツ
            VStack(spacing: 0) {
                // ドラッグハンドル＆閉じるボタン
                headerBar
                    .padding(.top, AppSpacing.sm)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        // 波形ビジュアライザーエリア
                        waveformVisualizerArea
                            .padding(.top, AppSpacing.md)

                        // 録音情報＆アクションボタン
                        recordingInfoSection

                        // 波形スクラバー
                        scrubberSection
                            .padding(.horizontal, AppSpacing.md)

                        // トランスポートコントロール
                        transportControls

                        // ボリュームスライダー
                        volumeSlider
                            .padding(.horizontal, AppSpacing.md)

                        // 速度コントロール
                        speedControl
                            .padding(.horizontal, AppSpacing.md)

                        // 下部ツールバー
                        bottomToolbar
                            .padding(.top, AppSpacing.sm)
                    }
                }
            }
        }
        .onAppear {
            loadWaveformData()
            syncRateIndex()
        }
        .onReceive(pulseTimer) { _ in
            if playerManager.isPlaying {
                withAnimation(AppAnimation.visualizer) {
                    waveformPhase += 0.1
                }
            }
        }
    }

    // MARK: - 背景グラデーション

    /// 深い暗色グラデーション背景
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.primaryGreenDark.opacity(0.3),
                AppColors.background.opacity(0.95),
                AppColors.background
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - ヘッダーバー

    /// ドラッグハンドルと閉じるボタン
    private var headerBar: some View {
        VStack(spacing: AppSpacing.sm) {
            // ドラッグハンドル
            Capsule()
                .fill(AppColors.textTertiary)
                .frame(width: 36, height: 5)

            HStack {
                // 閉じるボタン
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Spacer()

                // 再生中ラベル
                Text("再生中")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                // メニューボタン（プレースホルダー）
                Button {
                    // メニューアクション
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.sm)
        }
    }

    // MARK: - 波形ビジュアライザーエリア

    /// メインの波形表示エリア（アルバムアート代わり）
    private var waveformVisualizerArea: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width - AppSpacing.xl * 2, 320)

            ZStack {
                // 背景カード
                RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                    .fill(AppColors.backgroundElevated)
                    .shadow(
                        color: AppColors.primaryGreenDark.opacity(0.2),
                        radius: 24, y: 8
                    )

                // 波形グリッド
                waveformGrid(size: size)
                    .padding(AppSpacing.lg)

                // 中央の再生アイコンオーバーレイ
                if !playerManager.isPlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(AppColors.primaryGreen.opacity(0.3))
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 320)
        .padding(.horizontal, AppSpacing.xl)
    }

    /// 波形データをグリッド状に描画する
    private func waveformGrid(size: CGFloat) -> some View {
        GeometryReader { geometry in
            let data = effectiveWaveformData
            let barWidth: CGFloat = 3
            let barSpacing: CGFloat = 2
            let barCount = Int(geometry.size.width / (barWidth + barSpacing))
            let samples = resampleData(data, to: barCount)
            let maxHeight = geometry.size.height * 0.7

            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<samples.count, id: \.self) { index in
                    let amplitude = CGFloat(samples[index])
                    // 再生中は微妙にパルスさせる
                    let pulseOffset: CGFloat = playerManager.isPlaying
                        ? 0.05 * CGFloat(sin(waveformPhase + Double(index) * 0.3))
                        : 0

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(barGradient(for: index, total: samples.count))
                        .frame(
                            width: barWidth,
                            height: max(2, maxHeight * (amplitude + pulseOffset))
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// バーのグラデーション色を決定する
    private func barGradient(for index: Int, total: Int) -> LinearGradient {
        let normalizedIndex = Double(index) / Double(max(total - 1, 1))
        let isPlayed = normalizedIndex <= playerManager.playbackProgress

        if isPlayed {
            return LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.primaryGreen,
                    AppColors.primaryGreenLight
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.textTertiary.opacity(0.3),
                    AppColors.textTertiary.opacity(0.5)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }

    // MARK: - 録音情報セクション

    /// 録音名、日付、アクションボタン
    private var recordingInfoSection: some View {
        VStack(spacing: AppSpacing.md) {
            if let recording = playerManager.currentRecording {
                // 録音名
                Text(recording.displayName)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // 録音日
                Text(formatDate(recording.creationDate))
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)

                // アクションボタン行
                actionButtonsRow(recording: recording)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    /// お気に入り・プレイリスト追加・共有のアクションボタン行
    private func actionButtonsRow(recording: Recording) -> some View {
        HStack(spacing: AppSpacing.xl) {
            // お気に入りボタン
            Button {
                appState.toggleFavorite(for: recording)
            } label: {
                Image(systemName: recording.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundColor(recording.isFavorite ? AppColors.primaryGreen : AppColors.textSecondary)
            }
            .buttonStyle(.plain)

            // プレイリスト追加ボタン
            Button {
                // プレイリスト追加アクション
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(.plain)

            // 共有ボタン
            ShareLink(item: recording.url) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - スクラバーセクション

    /// 波形スクラバーコンポーネント
    private var scrubberSection: some View {
        WaveformScrubberView(
            waveformData: effectiveWaveformData,
            progress: playerManager.playbackProgress,
            currentTime: playerManager.currentTime,
            duration: playerManager.duration,
            onSeek: { time in
                playerManager.seek(to: time)
            }
        )
    }

    // MARK: - トランスポートコントロール

    /// 再生操作ボタン群（スキップバック、再生/一時停止、スキップフォワード）
    private var transportControls: some View {
        HStack(spacing: AppSpacing.xl) {
            Spacer()

            // シャッフル（オプション・装飾用）
            Button {
                // シャッフルアクション
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)

            // 15秒巻き戻し
            Button {
                let newTime = max(0, playerManager.currentTime - 15)
                playerManager.seek(to: newTime)
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.textPrimary)
            }
            .buttonStyle(.plain)

            // 再生/一時停止ボタン（大）
            Button {
                // タップ時のスケールアニメーション
                withAnimation(AppAnimation.fast) {
                    playButtonScale = 0.85
                }

                if playerManager.isPlaying {
                    playerManager.pause()
                } else if let recording = playerManager.currentRecording {
                    playerManager.play(recording: recording)
                }

                // バウンスバックアニメーション
                withAnimation(AppAnimation.spring) {
                    playButtonScale = 1.0
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.textPrimary)
                        .frame(width: 64, height: 64)

                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.background)
                        // 再生アイコンは少し右にオフセット
                        .offset(x: playerManager.isPlaying ? 0 : 2)
                }
                .scaleEffect(playButtonScale)
                .shadow(
                    color: AppColors.textPrimary.opacity(0.3),
                    radius: 8, y: 4
                )
            }
            .buttonStyle(.plain)

            // 15秒早送り
            Button {
                let newTime = min(playerManager.duration, playerManager.currentTime + 15)
                playerManager.seek(to: newTime)
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.textPrimary)
            }
            .buttonStyle(.plain)

            // リピート（オプション・装飾用）
            Button {
                // リピートアクション
            } label: {
                Image(systemName: "repeat")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - ボリュームスライダー

    /// スピーカーアイコン付きのボリューム調整スライダー
    private var volumeSlider: some View {
        HStack(spacing: AppSpacing.sm) {
            // 音量小アイコン
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textTertiary)

            // ボリュームスライダー
            Slider(
                value: Binding(
                    get: { Double(playerManager.volume) },
                    set: { playerManager.volume = Float($0) }
                ),
                in: 0...1
            )
            .tint(AppColors.primaryGreen)

            // 音量大アイコン
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - 速度コントロール

    /// 再生速度を切り替えるセグメントコントロール
    private var speedControl: some View {
        VStack(spacing: AppSpacing.sm) {
            // ラベル
            Button {
                withAnimation(AppAnimation.spring) {
                    showSpeedControl.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 14))
                    Text("再生速度: \(formatRate(playbackRates[selectedRateIndex]))")
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                    Image(systemName: showSpeedControl ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(.plain)

            // 速度セグメント
            if showSpeedControl {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(Array(playbackRates.enumerated()), id: \.offset) { index, rate in
                        Button {
                            withAnimation(AppAnimation.fast) {
                                selectedRateIndex = index
                            }
                            playerManager.setRate(rate)
                        } label: {
                            Text(formatRate(rate))
                                .font(AppTypography.caption)
                                .fontWeight(selectedRateIndex == index ? .bold : .regular)
                                .foregroundColor(
                                    selectedRateIndex == index
                                        ? AppColors.background
                                        : AppColors.textSecondary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    Capsule()
                                        .fill(
                                            selectedRateIndex == index
                                                ? AppColors.primaryGreen
                                                : AppColors.backgroundCard
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - 下部ツールバー

    /// 共有、AirPlay、キュー用の下部アイコンバー
    private var bottomToolbar: some View {
        HStack(spacing: AppSpacing.xl) {
            Spacer()

            // 共有ボタン
            if let recording = playerManager.currentRecording {
                ShareLink(item: recording.url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            // AirPlayアイコン
            Button {
                // AirPlayアクション
            } label: {
                Image(systemName: "airplayaudio")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)

            // キューアイコン
            Button {
                // キューアクション
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.bottom, AppSpacing.lg)
    }

    // MARK: - ユーティリティ

    /// 有効な波形データ（キャッシュまたはプレースホルダー）
    private var effectiveWaveformData: [Float] {
        if !waveformData.isEmpty {
            return waveformData
        }
        // プレースホルダーを生成
        return (0..<100).map { i in
            0.15 + 0.6 * abs(sin(Float(i) / 100.0 * .pi * 5))
        }
    }

    /// 現在の録音から波形データを読み込む
    private func loadWaveformData() {
        guard let recording = playerManager.currentRecording else { return }

        // 録音に波形データがキャッシュされていればそれを使う
        if let cached = recording.waveformData {
            waveformData = cached
            return
        }

        // バックグラウンドで波形を生成
        Task {
            let data = playerManager.generateWaveformData(from: recording.url, sampleCount: 200)
            await MainActor.run {
                waveformData = data
            }
        }
    }

    /// 現在の再生速度からインデックスを同期する
    private func syncRateIndex() {
        if let index = playbackRates.firstIndex(of: playerManager.playbackRate) {
            selectedRateIndex = index
        }
    }

    /// 再生速度を表示用にフォーマット
    private func formatRate(_ rate: Float) -> String {
        if rate == Float(Int(rate)) {
            return "\(Int(rate)).0x"
        }
        return String(format: "%.2gx", rate)
    }

    /// 日付を表示用にフォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
}

// MARK: - プレビュー
#Preview("NowPlayingView") {
    NowPlayingView()
        .environmentObject(AudioPlayerManager())
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
