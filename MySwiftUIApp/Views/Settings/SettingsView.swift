import SwiftUI

// MARK: - 設定ビュー
/// アプリの各種設定を管理する画面。録音設定、エフェクト、
/// メトロノーム、一般設定、アプリ情報を提供する

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var audioManager: AudioManager

    /// サンプルレート選択（44.1kHz / 48kHz）
    @State private var selectedSampleRate: SampleRateOption = .rate44100

    /// 録音フォーマット選択
    @State private var selectedFormat: RecordingFormat = .m4a

    /// デフォルトBPM
    @State private var defaultBPM: Double = 120

    /// デフォルト拍子
    @State private var defaultTimeSignature: Int = 4

    /// ストレージ使用量（バイト）
    @State private var storageUsage: Int64 = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                List {
                    // 録音設定
                    recordingSettingsSection

                    // エフェクト設定
                    effectsSection

                    // メトロノーム設定
                    metronomeSection

                    // 一般設定
                    generalSection

                    // アプリについて
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                calculateStorageUsage()
            }
        }
    }

    // MARK: - 録音設定セクション

    /// サンプルレート、フォーマット、品質の設定
    private var recordingSettingsSection: some View {
        Section {
            // サンプルレート
            Picker("サンプルレート", selection: $selectedSampleRate) {
                ForEach(SampleRateOption.allCases, id: \.self) { rate in
                    Text(rate.displayName).tag(rate)
                }
            }
            .listRowBackground(AppColors.backgroundElevated)
            .foregroundColor(AppColors.textPrimary)
            .tint(AppColors.primaryGreen)

            // フォーマット
            Picker("フォーマット", selection: $selectedFormat) {
                ForEach(RecordingFormat.allCases, id: \.self) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .listRowBackground(AppColors.backgroundElevated)
            .foregroundColor(AppColors.textPrimary)
            .tint(AppColors.primaryGreen)

            // 品質表示
            HStack {
                Text("品質")
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(qualityDescription)
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            .listRowBackground(AppColors.backgroundElevated)
        } header: {
            Text("録音設定")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - エフェクト設定セクション

    /// デフォルトプリセットの選択
    private var effectsSection: some View {
        Section {
            // デフォルトプリセット
            NavigationLink {
                PresetPickerView()
                    .environmentObject(appState)
            } label: {
                HStack {
                    Text("デフォルトプリセット")
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text(appState.currentPreset.name)
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .listRowBackground(AppColors.backgroundElevated)
        } header: {
            Text("エフェクト")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - メトロノーム設定セクション

    /// デフォルトBPMと拍子の設定
    private var metronomeSection: some View {
        Section {
            // BPMスライダー
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("デフォルトBPM")
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("\(Int(defaultBPM))")
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.primaryGreen)
                        .fontWeight(.semibold)
                }

                Slider(value: $defaultBPM, in: 40...240, step: 1)
                    .tint(AppColors.primaryGreen)
            }
            .listRowBackground(AppColors.backgroundElevated)

            // 拍子
            Picker("拍子", selection: $defaultTimeSignature) {
                Text("3/4").tag(3)
                Text("4/4").tag(4)
                Text("6/8").tag(6)
            }
            .listRowBackground(AppColors.backgroundElevated)
            .foregroundColor(AppColors.textPrimary)
            .tint(AppColors.primaryGreen)
        } header: {
            Text("メトロノーム")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - 一般設定セクション

    /// テーマとストレージ使用量
    private var generalSection: some View {
        Section {
            // テーマ（ダーク固定）
            HStack {
                Text("テーマ")
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.primaryGreen)
                    Text("ダーク")
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .listRowBackground(AppColors.backgroundElevated)

            // ストレージ使用量
            HStack {
                Text("ストレージ使用量")
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(formattedStorageUsage)
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            .listRowBackground(AppColors.backgroundElevated)

            // 録音件数
            HStack {
                Text("録音件数")
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(appState.allRecordings.count)件")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            .listRowBackground(AppColors.backgroundElevated)
        } header: {
            Text("一般")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - アプリについてセクション

    /// バージョンとライセンス情報
    private var aboutSection: some View {
        Section {
            // バージョン
            HStack {
                Text("バージョン")
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(appVersion)
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            .listRowBackground(AppColors.backgroundElevated)

            // ビルド番号
            HStack {
                Text("ビルド番号")
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(buildNumber)
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            .listRowBackground(AppColors.backgroundElevated)

            // ライセンス
            NavigationLink {
                LicenseView()
            } label: {
                Text("ライセンス")
                    .foregroundColor(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.backgroundElevated)
        } header: {
            Text("アプリについて")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - ヘルパー

    /// 現在のフォーマットに応じた品質説明を返す
    private var qualityDescription: String {
        switch selectedFormat {
        case .m4a:
            return "高品質 (AAC)"
        case .wav:
            return "非圧縮 (ロスレス)"
        case .mp3:
            return "標準品質 (MP3)"
        }
    }

    /// アプリバージョンを取得する
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// ビルド番号を取得する
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// ストレージ使用量をフォーマットする
    private var formattedStorageUsage: String {
        if storageUsage < 1024 {
            return "\(storageUsage) B"
        } else if storageUsage < 1024 * 1024 {
            return String(format: "%.1f KB", Double(storageUsage) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(storageUsage) / (1024.0 * 1024.0))
        }
    }

    /// ドキュメントディレクトリのストレージ使用量を計算する
    private func calculateStorageUsage() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var totalSize: Int64 = 0

        if let files = try? FileManager.default.contentsOfDirectory(
            at: documentsPath,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for file in files {
                if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }

        storageUsage = totalSize
    }
}

// MARK: - サンプルレート選択肢

/// サンプルレートの選択肢
enum SampleRateOption: CaseIterable {
    case rate44100
    case rate48000

    var displayName: String {
        switch self {
        case .rate44100: return "44.1 kHz"
        case .rate48000: return "48 kHz"
        }
    }

    var value: Double {
        switch self {
        case .rate44100: return 44100
        case .rate48000: return 48000
        }
    }
}

// MARK: - プリセット選択ビュー

/// デフォルトエフェクトプリセットを選択する画面
struct PresetPickerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            List {
                ForEach(appState.loadAllPresets()) { preset in
                    Button {
                        appState.currentPreset = preset
                        dismiss()
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: preset.icon)
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primaryGreen)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(preset.name)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textPrimary)

                                if preset.isFactory {
                                    Text("内蔵プリセット")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }

                            Spacer()

                            if appState.currentPreset.id == preset.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.primaryGreen)
                            }
                        }
                    }
                    .listRowBackground(AppColors.backgroundElevated)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("プリセット選択")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ライセンスビュー

/// ライセンス情報を表示する画面
struct LicenseView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("ライセンス情報")
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)

                    Text("このアプリケーションは以下のオープンソースライブラリを使用しています。")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)

                    Divider()
                        .background(AppColors.separator)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("AVFoundation")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Text("Copyright (c) Apple Inc. All rights reserved.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("SwiftUI")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Text("Copyright (c) Apple Inc. All rights reserved.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
        .navigationTitle("ライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - プレビュー

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(AudioManager())
        .preferredColorScheme(.dark)
}
