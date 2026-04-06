import SwiftUI

// MARK: - Spotify風ダークテーマ デザインシステム
// ギター録音アプリ向けのプレミアムなダークテーマ定義

// MARK: - カラーパレット
enum AppColors {
    // === 背景色 ===
    /// メイン背景（最も暗い）
    static let background = Color(hex: "121212")
    /// 浮き上がった要素の背景
    static let backgroundElevated = Color(hex: "181818")
    /// カード・サーフェスの背景
    static let backgroundCard = Color(hex: "282828")
    /// 入力フィールド・セパレーターの背景
    static let backgroundInput = Color(hex: "333333")

    // === プライマリアクセント（Spotifyグリーン） ===
    /// メインアクセント（ボタン、アクティブ状態）
    static let primaryGreen = Color(hex: "1DB954")
    /// ハイライト・ホバー用（やや明るい緑）
    static let primaryGreenLight = Color(hex: "1ED760")
    /// 暗めのグリーン（背景アクセント用）
    static let primaryGreenDark = Color(hex: "158C3E")

    // === 録音関連 ===
    /// 録音中の赤
    static let recordingRed = Color(hex: "FF4444")
    /// 録音赤の暗めバリエーション
    static let recordingRedDark = Color(hex: "CC3333")
    /// 録音ボタンのグロー用
    static let recordingRedGlow = Color(hex: "FF4444").opacity(0.4)

    // === テキスト ===
    /// プライマリテキスト（白）
    static let textPrimary = Color.white
    /// セカンダリテキスト（薄いグレー）
    static let textSecondary = Color(hex: "B3B3B3")
    /// ターシャリテキスト（さらに薄いグレー）
    static let textTertiary = Color(hex: "727272")
    /// 無効状態のテキスト
    static let textDisabled = Color(hex: "535353")

    // === ビジュアライザー用グラデーション ===
    /// 音声レベルビジュアライザーのグラデーション色配列
    static let visualizerGradient: [Color] = [
        Color(hex: "4A90D9"), // 青
        Color(hex: "50C8E8"), // シアン
        Color(hex: "1DB954"), // 緑
        Color(hex: "F5C542"), // 黄
        Color(hex: "F5A623"), // オレンジ
        Color(hex: "FF4444")  // 赤
    ]

    /// Spotifyグリーン系のグラデーション
    static let greenGradient: [Color] = [
        Color(hex: "1DB954"),
        Color(hex: "1ED760")
    ]

    // === セパレーター・ボーダー ===
    /// 区切り線の色
    static let separator = Color.white.opacity(0.1)
    /// ボーダーの色
    static let border = Color.white.opacity(0.15)

    // === ステータスカラー ===
    /// 成功
    static let success = Color(hex: "1DB954")
    /// 警告
    static let warning = Color(hex: "F5A623")
    /// エラー
    static let error = Color(hex: "FF4444")
    /// 情報
    static let info = Color(hex: "4A90D9")
}

// MARK: - タイポグラフィシステム
enum AppTypography {
    /// 画面タイトル用（32pt ボールド）
    static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    /// セクションヘッダー用（24pt ボールド）
    static let title = Font.system(size: 24, weight: .bold, design: .rounded)
    /// セクションサブヘッダー用（20pt セミボールド）
    static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
    /// 本文テキスト用（16pt レギュラー）
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    /// 補足テキスト用（14pt ミディアム）
    static let callout = Font.system(size: 14, weight: .medium, design: .rounded)
    /// キャプション用（12pt レギュラー）
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    /// 極小テキスト用（10pt レギュラー）
    static let micro = Font.system(size: 10, weight: .regular, design: .rounded)
    /// タイマー・数値表示用（48pt ライト モノスペース）
    static let timer = Font.system(size: 48, weight: .light, design: .monospaced)
    /// 録音時間表示用（28pt ミディアム モノスペース）
    static let recordingTime = Font.system(size: 28, weight: .medium, design: .monospaced)
}

// MARK: - スペーシングシステム
enum AppSpacing {
    /// 極小スペース: 4pt
    static let xs: CGFloat = 4
    /// 小スペース: 8pt
    static let sm: CGFloat = 8
    /// 中スペース: 16pt
    static let md: CGFloat = 16
    /// 大スペース: 24pt
    static let lg: CGFloat = 24
    /// 特大スペース: 32pt
    static let xl: CGFloat = 32
    /// 超特大スペース: 48pt
    static let xxl: CGFloat = 48
}

// MARK: - 角丸システム
enum AppCornerRadius {
    /// 小さい角丸: 4pt
    static let small: CGFloat = 4
    /// 中くらいの角丸: 8pt
    static let medium: CGFloat = 8
    /// 大きい角丸: 12pt
    static let large: CGFloat = 12
    /// 特大角丸: 16pt
    static let xl: CGFloat = 16
    /// ピル型（完全な丸み）: 999pt
    static let full: CGFloat = 999
}

// MARK: - シャドウ定義
enum AppShadow {
    /// 微妙なシャドウ（カードの浮き上がり効果）
    static func subtle(_ color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (color: color.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    /// 中程度のシャドウ（ボタン・モーダル用）
    static func medium(_ color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (color: color.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    /// 強いシャドウ（フローティング要素用）
    static func strong(_ color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (color: color.opacity(0.4), radius: 16, x: 0, y: 8)
    }
}

// MARK: - アニメーション定数
enum AppAnimation {
    /// 高速トランジション（0.15秒）
    static let fast: Animation = .easeInOut(duration: 0.15)
    /// 標準トランジション（0.25秒）
    static let standard: Animation = .easeInOut(duration: 0.25)
    /// ゆっくりトランジション（0.4秒）
    static let slow: Animation = .easeInOut(duration: 0.4)

    /// Spotify風の滑らかなスプリング
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0)
    /// バウンス感のあるスプリング
    static let bouncy: Animation = .spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
    /// 控えめなスプリング（微妙な動き用）
    static let gentle: Animation = .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)

    /// 録音ボタンの脈動アニメーション
    static let pulse: Animation = .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    /// ビジュアライザーのバー更新アニメーション
    static let visualizer: Animation = .easeInOut(duration: 0.08)

    // === デュレーション定数 ===
    /// 高速デュレーション
    static let durationFast: Double = 0.15
    /// 標準デュレーション
    static let durationStandard: Double = 0.25
    /// ゆっくりデュレーション
    static let durationSlow: Double = 0.4
}

// MARK: - カードスタイル ViewModifier
/// ダークカードの外観を適用するModifier
struct CardStyleModifier: ViewModifier {
    var backgroundColor: Color = AppColors.backgroundCard
    var cornerRadius: CGFloat = AppCornerRadius.large

    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: AppShadow.subtle().color,
                radius: AppShadow.subtle().radius,
                x: AppShadow.subtle().x,
                y: AppShadow.subtle().y
            )
    }
}

// MARK: - プライマリボタンスタイル ViewModifier
/// Spotifyグリーンのピル型ボタンスタイル
struct PrimaryButtonModifier: ViewModifier {
    var isEnabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(AppTypography.callout)
            .fontWeight(.bold)
            .foregroundColor(isEnabled ? AppColors.background : AppColors.textDisabled)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
            .background(
                Capsule()
                    .fill(isEnabled ? AppColors.primaryGreen : AppColors.backgroundInput)
            )
            .scaleEffect(isEnabled ? 1.0 : 0.95)
    }
}

// MARK: - セカンダリボタンスタイル ViewModifier
/// アウトラインのゴーストボタンスタイル
struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTypography.callout)
            .fontWeight(.semibold)
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
            .background(
                Capsule()
                    .stroke(AppColors.border, lineWidth: 1.5)
            )
    }
}

// MARK: - グラスモーフィズム ViewModifier
/// ブラー背景効果を適用するModifier（オーバーレイ用）
struct GlassMorphismModifier: ViewModifier {
    var opacity: Double = 0.6

    func body(content: Content) -> some View {
        content
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: AppCornerRadius.large)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .stroke(AppColors.border, lineWidth: 0.5)
            )
    }
}

// MARK: - View拡張（Modifier適用ショートカット）
extension View {
    /// ダークカードスタイルを適用する
    func cardStyle(
        backgroundColor: Color = AppColors.backgroundCard,
        cornerRadius: CGFloat = AppCornerRadius.large
    ) -> some View {
        modifier(CardStyleModifier(backgroundColor: backgroundColor, cornerRadius: cornerRadius))
    }

    /// プライマリボタンスタイル（Spotifyグリーン ピル型）を適用する
    func primaryButton(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButtonModifier(isEnabled: isEnabled))
    }

    /// セカンダリボタンスタイル（アウトライン）を適用する
    func secondaryButton() -> some View {
        modifier(SecondaryButtonModifier())
    }

    /// グラスモーフィズム効果を適用する
    func glassMorphism(opacity: Double = 0.6) -> some View {
        modifier(GlassMorphismModifier(opacity: opacity))
    }

    /// テーマ標準のシャドウを適用する
    func themeShadow(_ level: ShadowLevel = .subtle) -> some View {
        switch level {
        case .subtle:
            return AnyView(self.shadow(
                color: AppShadow.subtle().color,
                radius: AppShadow.subtle().radius,
                x: AppShadow.subtle().x,
                y: AppShadow.subtle().y
            ))
        case .medium:
            return AnyView(self.shadow(
                color: AppShadow.medium().color,
                radius: AppShadow.medium().radius,
                x: AppShadow.medium().x,
                y: AppShadow.medium().y
            ))
        case .strong:
            return AnyView(self.shadow(
                color: AppShadow.strong().color,
                radius: AppShadow.strong().radius,
                x: AppShadow.strong().x,
                y: AppShadow.strong().y
            ))
        }
    }
}

/// シャドウの強度レベル
enum ShadowLevel {
    case subtle
    case medium
    case strong
}

// MARK: - Color拡張（16進数カラー初期化）
extension Color {
    /// 16進数文字列からColorを初期化する
    /// - Parameter hex: 16進数カラー文字列（"#"プレフィックスはオプション）
    ///   6桁（RGB）または8桁（ARGB）をサポート
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - LinearGradient拡張
extension LinearGradient {
    /// ビジュアライザー用の標準グラデーション（下→上）
    static var visualizer: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: AppColors.visualizerGradient),
            startPoint: .bottom,
            endPoint: .top
        )
    }

    /// Spotifyグリーンのグラデーション（左→右）
    static var spotifyGreen: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: AppColors.greenGradient),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
