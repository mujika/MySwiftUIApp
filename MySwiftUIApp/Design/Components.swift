import SwiftUI

// MARK: - 再利用可能なデザインコンポーネント集
// Spotify風ダークテーマのギター録音アプリ向けUIパーツ

// MARK: - SpotifyTabBar（カスタムタブバー）
/// Spotify風のダーク背景＋ブラー付きカスタムボトムタブバー
struct SpotifyTabBar: View {
    /// タブの種類定義
    enum Tab: Int, CaseIterable {
        case home = 0
        case record = 1
        case tools = 2
        case library = 3

        /// タブのアイコン名
        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .record: return "mic.fill"
            case .tools: return "tuningfork"
            case .library: return "music.note.list"
            }
        }

        /// タブのラベル
        var label: String {
            switch self {
            case .home: return "ホーム"
            case .record: return "録音"
            case .tools: return "ツール"
            case .library: return "ライブラリ"
            }
        }
    }

    @Binding var selectedTab: Tab
    /// ミニプレイヤーを表示するかどうか
    var showMiniPlayer: Bool = false
    /// ミニプレイヤーのタップアクション
    var onMiniPlayerTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // ミニプレイヤー（タブバーの上に配置）
            if showMiniPlayer {
                miniPlayerView
            }

            // 区切り線
            AppColors.separator
                .frame(height: 0.5)

            // タブバー本体
            HStack {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.sm + 20) // SafeArea分のパディング
            .padding(.horizontal, AppSpacing.md)
            .background(
                // ブラー付きダーク背景
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
        }
    }

    /// タブボタンを生成する
    private func tabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(AppAnimation.fast) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)

                Text(tab.label)
                    .font(AppTypography.micro)
            }
            .foregroundColor(selectedTab == tab ? AppColors.primaryGreen : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    /// ミニプレイヤーのビュー
    private var miniPlayerView: some View {
        Button {
            onMiniPlayerTap?()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                // サムネイル
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
                    Text("録音タイトル")
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    Text("0:00 / 3:24")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // 再生ボタン
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.trailing, AppSpacing.xs)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.backgroundElevated)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - GradientButton（グラデーションボタン）
/// アニメーション付きのグラデーションボタン
struct GradientButton: View {
    let title: String
    let icon: String?
    let colors: [Color]
    let action: () -> Void

    @State private var isPressed = false

    /// グラデーションボタンを初期化する
    /// - Parameters:
    ///   - title: ボタンのラベル
    ///   - icon: SF Symbolsのアイコン名（オプション）
    ///   - colors: グラデーションの色配列（デフォルトはSpotifyグリーン）
    ///   - action: タップ時のアクション
    init(
        title: String,
        icon: String? = nil,
        colors: [Color] = AppColors.greenGradient,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.colors = colors
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(AppTypography.callout)
                    .fontWeight(.bold)
            }
            .foregroundColor(AppColors.background)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(
                color: colors.first?.opacity(0.3) ?? .clear,
                radius: isPressed ? 4 : 8,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AppAnimation.fast) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(AppAnimation.spring) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - RecordingThumbnail（録音サムネイル）
/// 波形プレビュー付きの録音カード
struct RecordingThumbnail: View {
    let title: String
    let duration: String
    let date: String
    /// 波形データ（0.0〜1.0の配列、プレースホルダー用）
    var waveformData: [CGFloat] = []
    var isPlaying: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // 波形プレビューエリア
                ZStack {
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .fill(AppColors.backgroundElevated)

                    // 波形のプレースホルダー
                    waveformPreview
                        .padding(.horizontal, AppSpacing.sm)

                    // 再生中インジケーター
                    if isPlaying {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.primaryGreen)
                                    .padding(AppSpacing.xs)
                                    .background(
                                        Circle()
                                            .fill(AppColors.background.opacity(0.8))
                                    )
                                    .padding(AppSpacing.sm)
                            }
                        }
                    }
                }
                .aspectRatio(1.0, contentMode: .fit)

                // 録音情報
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.xs) {
                        Text(duration)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        Text("・")
                            .foregroundColor(AppColors.textTertiary)

                        Text(date)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// 波形プレビューを描画する
    private var waveformPreview: some View {
        GeometryReader { geometry in
            let sampleData = waveformData.isEmpty ? generatePlaceholderWaveform() : waveformData
            let barWidth: CGFloat = 2
            let barSpacing: CGFloat = 1.5
            let barCount = Int(geometry.size.width / (barWidth + barSpacing))
            let samples = resampleData(sampleData, to: barCount)

            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<samples.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPlaying ? AppColors.primaryGreen : AppColors.textTertiary)
                        .frame(
                            width: barWidth,
                            height: max(2, geometry.size.height * 0.6 * samples[index])
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// プレースホルダー波形データを生成する
    private func generatePlaceholderWaveform() -> [CGFloat] {
        (0..<30).map { i in
            let normalized = CGFloat(i) / 30.0
            return 0.2 + 0.6 * abs(sin(normalized * .pi * 3))
        }
    }

    /// データを指定した数にリサンプリングする
    private func resampleData(_ data: [CGFloat], to count: Int) -> [CGFloat] {
        guard !data.isEmpty, count > 0 else { return [] }
        return (0..<count).map { index in
            let sourceIndex = CGFloat(index) / CGFloat(count) * CGFloat(data.count)
            let lower = Int(sourceIndex)
            let upper = min(lower + 1, data.count - 1)
            let fraction = sourceIndex - CGFloat(lower)
            return data[lower] * (1 - fraction) + data[upper] * fraction
        }
    }
}

// MARK: - SectionHeader（セクションヘッダー）
/// Spotify風「セクションタイトル + すべて表示」ヘッダー
struct SectionHeader: View {
    let title: String
    var showSeeAll: Bool = false
    var onSeeAllTap: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            if showSeeAll {
                Button {
                    onSeeAllTap?()
                } label: {
                    Text("すべて表示")
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - StatusPill（ステータスピル）
/// 小さなピル型のステータス表示コンポーネント
struct StatusPill: View {
    /// ステータスの種類
    enum Status {
        case recording
        case playing
        case paused
        case processing
        case idle

        /// ステータスラベル
        var label: String {
            switch self {
            case .recording: return "録音中"
            case .playing: return "再生中"
            case .paused: return "一時停止"
            case .processing: return "処理中"
            case .idle: return "待機中"
            }
        }

        /// ステータスの色
        var color: Color {
            switch self {
            case .recording: return AppColors.recordingRed
            case .playing: return AppColors.primaryGreen
            case .paused: return AppColors.warning
            case .processing: return AppColors.info
            case .idle: return AppColors.textTertiary
            }
        }

        /// ステータスのアイコン
        var icon: String {
            switch self {
            case .recording: return "circle.fill"
            case .playing: return "play.fill"
            case .paused: return "pause.fill"
            case .processing: return "ellipsis"
            case .idle: return "minus"
            }
        }
    }

    let status: Status
    /// パルスアニメーションを有効にするか
    var animated: Bool = true

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            // ステータスドット・アイコン
            Image(systemName: status.icon)
                .font(.system(size: 8))
                .foregroundColor(status.color)
                .opacity(isPulsing ? 0.5 : 1.0)

            Text(status.label)
                .font(AppTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, AppSpacing.sm + AppSpacing.xs)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.3), lineWidth: 0.5)
        )
        .onAppear {
            // 録音・再生中はパルスアニメーション
            if animated && (status == .recording || status == .playing) {
                withAnimation(AppAnimation.pulse) {
                    isPulsing = true
                }
            }
        }
    }
}

// MARK: - CircularProgressView（円形プログレス表示）
/// チューナー・レベルインジケーター用の円形プログレスビュー
struct CircularProgressView: View {
    /// 進捗値（0.0〜1.0）
    let progress: CGFloat
    /// リング内に表示するラベル
    var label: String = ""
    /// サブラベル
    var subLabel: String = ""
    /// リングの線幅
    var lineWidth: CGFloat = 8
    /// プログレスの色
    var progressColor: Color = AppColors.primaryGreen
    /// トラック（背景リング）の色
    var trackColor: Color = AppColors.backgroundCard
    /// ビューのサイズ
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            // 背景トラック
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // プログレスリング
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    progressGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(AppAnimation.standard, value: progress)

            // ラベル
            VStack(spacing: AppSpacing.xs) {
                if !label.isEmpty {
                    Text(label)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                if !subLabel.isEmpty {
                    Text(subLabel)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    /// プログレスリングのグラデーション
    private var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                progressColor.opacity(0.6),
                progressColor
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * Double(progress))
        )
    }
}

// MARK: - GlowingRecordButton（グロー付き録音ボタン）
/// 録音中に脈動するグロー効果付きの大型録音ボタン
struct GlowingRecordButton: View {
    let isRecording: Bool
    let isEnabled: Bool
    let action: () -> Void

    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.4

    /// ボタンのサイズ
    var buttonSize: CGFloat = 80

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                // 外側のグロー（録音中のみ）
                if isRecording {
                    Circle()
                        .fill(AppColors.recordingRed.opacity(glowOpacity * 0.3))
                        .frame(width: buttonSize * 1.8, height: buttonSize * 1.8)
                        .scaleEffect(glowScale)

                    Circle()
                        .fill(AppColors.recordingRed.opacity(glowOpacity * 0.5))
                        .frame(width: buttonSize * 1.4, height: buttonSize * 1.4)
                        .scaleEffect(glowScale * 0.95)
                }

                // ボタン外枠リング
                Circle()
                    .stroke(
                        isRecording ? AppColors.recordingRed.opacity(0.6) : AppColors.textTertiary.opacity(0.3),
                        lineWidth: 4
                    )
                    .frame(width: buttonSize + 12, height: buttonSize + 12)

                // ボタン本体
                Circle()
                    .fill(
                        isRecording
                            ? AppColors.recordingRed
                            : AppColors.primaryGreen
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(
                        color: isRecording
                            ? AppColors.recordingRed.opacity(0.5)
                            : AppColors.primaryGreen.opacity(0.3),
                        radius: isRecording ? 16 : 8
                    )

                // アイコン（マイク or 停止）
                if isRecording {
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(Color.white)
                        .frame(width: buttonSize * 0.3, height: buttonSize * 0.3)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: buttonSize * 0.35))
                        .foregroundColor(.white)
                }
            }
            .opacity(isEnabled ? 1.0 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startGlowAnimation()
            } else {
                stopGlowAnimation()
            }
        }
        .onAppear {
            if isRecording {
                startGlowAnimation()
            }
        }
    }

    /// グローの脈動アニメーションを開始する
    private func startGlowAnimation() {
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            glowScale = 1.15
            glowOpacity = 0.8
        }
    }

    /// グローアニメーションを停止する
    private func stopGlowAnimation() {
        withAnimation(AppAnimation.standard) {
            glowScale = 1.0
            glowOpacity = 0.4
        }
    }
}

// MARK: - プレビュー
#Preview("SpotifyTabBar") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        VStack {
            Spacer()
            SpotifyTabBar(
                selectedTab: .constant(.home),
                showMiniPlayer: true
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("GradientButton") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        VStack(spacing: AppSpacing.md) {
            GradientButton(title: "録音開始", icon: "mic.fill") {}
            GradientButton(
                title: "エクスポート",
                icon: "square.and.arrow.up",
                colors: [AppColors.info, Color(hex: "50C8E8")]
            ) {}
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("RecordingThumbnail") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        HStack(spacing: AppSpacing.md) {
            RecordingThumbnail(
                title: "ギター練習 #1",
                duration: "3:24",
                date: "今日",
                isPlaying: false
            ) {}
            .frame(width: 160)

            RecordingThumbnail(
                title: "新曲リフ",
                duration: "1:05",
                date: "昨日",
                isPlaying: true
            ) {}
            .frame(width: 160)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("StatusPill") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        VStack(spacing: AppSpacing.md) {
            StatusPill(status: .recording)
            StatusPill(status: .playing)
            StatusPill(status: .paused)
            StatusPill(status: .processing)
            StatusPill(status: .idle)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("CircularProgressView") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        HStack(spacing: AppSpacing.xl) {
            CircularProgressView(
                progress: 0.65,
                label: "A4",
                subLabel: "440Hz"
            )

            CircularProgressView(
                progress: 0.85,
                label: "-3",
                subLabel: "セント",
                progressColor: AppColors.warning,
                size: 100
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("GlowingRecordButton") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        HStack(spacing: AppSpacing.xxl) {
            GlowingRecordButton(
                isRecording: false,
                isEnabled: true
            ) {}

            GlowingRecordButton(
                isRecording: true,
                isEnabled: true
            ) {}
        }
    }
    .preferredColorScheme(.dark)
}
