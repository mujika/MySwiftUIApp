import SwiftUI

// MARK: - 録音コントロールビュー
/// モダンな録音操作画面。GlowingRecordButton、音声レベル表示、
/// ステータスピル、エフェクトプリセット表示、モニタリング切替を提供する

struct RecordingControlsView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var appState: AppState

    /// モニタリングトグル状態
    @State private var isMonitoring: Bool = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                // ステータスエリア
                statusSection
                    .padding(.top, AppSpacing.xl)

                // 録音時間表示
                recordingTimeSection

                Spacer()

                // オーディオビジュアライザー
                AudioVisualizerView(
                    audioLevel: audioManager.audioLevel,
                    waveformSamples: audioManager.waveformSamples,
                    mode: .bars
                )
                .frame(height: 80)
                .padding(.horizontal, AppSpacing.md)

                Spacer()

                // メイン録音ボタン
                GlowingRecordButton(
                    isRecording: audioManager.isRecording,
                    isEnabled: audioManager.hasPermission
                ) {
                    if audioManager.isRecording {
                        audioManager.stopRecording()
                        // 録音一覧を更新
                        appState.loadAllRecordings()
                    } else {
                        audioManager.startRecording()
                    }
                }

                // エフェクトプリセット＋モニタリング
                bottomControlsSection

                Spacer(minLength: AppSpacing.xxl)
            }
        }
        .onChange(of: isMonitoring) { _, newValue in
            audioManager.isMonitoring = newValue
        }
        .task {
            // マイク許可がまだの場合はリクエスト
            if !audioManager.hasPermission {
                await audioManager.requestPermission()
            }
        }
    }

    // MARK: - ステータスセクション

    /// 録音状態を示すピルとタイトル
    private var statusSection: some View {
        VStack(spacing: AppSpacing.sm) {
            // ステータスピル
            StatusPill(
                status: audioManager.isRecording ? .recording : .idle,
                animated: true
            )

            // 許可がない場合の警告
            if !audioManager.hasPermission {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.warning)

                    Text("マイクへのアクセス許可が必要です")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.warning)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.warning.opacity(0.1))
                .cornerRadius(AppCornerRadius.full)
            }
        }
    }

    // MARK: - 録音時間セクション

    /// 録音経過時間を大きく表示する
    private var recordingTimeSection: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(formatTime(audioManager.recordingDuration))
                .font(AppTypography.recordingTime)
                .foregroundColor(
                    audioManager.isRecording
                        ? AppColors.recordingRed
                        : AppColors.textPrimary
                )
                .contentTransition(.numericText())
                .animation(AppAnimation.fast, value: audioManager.recordingDuration)

            // モニタリング中のインジケーター
            if audioManager.isRecording && isMonitoring {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.primaryGreen)

                    Text("モニタリング中")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.primaryGreen)
                }
            }
        }
    }

    // MARK: - 下部コントロールセクション

    /// エフェクトプリセット、モニタリングボタン、ツールリンクの行
    private var bottomControlsSection: some View {
        VStack(spacing: AppSpacing.md) {
            // エフェクトプリセット表示ピル
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: appState.currentPreset.icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.primaryGreen)

                Text(appState.currentPreset.name)
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.backgroundCard)
            .cornerRadius(AppCornerRadius.full)

            // モニタリング＋ツールボタン行
            HStack(spacing: AppSpacing.xl) {
                // モニタリングトグル
                Button {
                    isMonitoring.toggle()
                } label: {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: isMonitoring ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 22))
                            .foregroundColor(
                                isMonitoring ? AppColors.primaryGreen : AppColors.textTertiary
                            )

                        Text("モニター")
                            .font(AppTypography.micro)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                // チューナーリンク
                Button {
                    // チューナー画面遷移
                } label: {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "tuningfork")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.textTertiary)

                        Text("チューナー")
                            .font(AppTypography.micro)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                // メトロノームリンク
                Button {
                    // メトロノーム画面遷移
                } label: {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "metronome.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.textTertiary)

                        Text("メトロノーム")
                            .font(AppTypography.micro)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - ヘルパー

    /// 経過時間をMM:SSフォーマットに変換する
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - プレビュー

#Preview {
    RecordingControlsView()
        .environmentObject(AudioManager())
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
