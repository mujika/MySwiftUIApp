import SwiftUI

// MARK: - Lumina Design System

enum LuminaTheme {

    // MARK: - Adaptive Color Palette (Time-of-Day Aware)

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: adaptiveColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var adaptiveColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<9:
            return [Color(hex: 0xFDB99B), Color(hex: 0xCF8BF3), Color(hex: 0xA770EF)]
        case 9..<15:
            return [Color(hex: 0x89F7FE), Color(hex: 0x66A6FF), Color(hex: 0x7F53AC)]
        case 15..<19:
            return [Color(hex: 0xF7971E), Color(hex: 0xE44D26), Color(hex: 0x8E2DE2)]
        default:
            return [Color(hex: 0x0F0C29), Color(hex: 0x302B63), Color(hex: 0x24243E)]
        }
    }

    static var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Core Colors

    static let background = Color(hex: 0x0A0A1A)
    static let surface = Color(hex: 0x14142B)
    static let surfaceLight = Color(hex: 0x1E1E3F)
    static let accent = Color(hex: 0xA770EF)
    static let accentSecondary = Color(hex: 0xCF8BF3)
    static let accentTertiary = Color(hex: 0xFDB99B)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.4)

    // MARK: - Mood Colors

    static let moodRadiant = Color(hex: 0xFFD700)
    static let moodJoyful = Color(hex: 0xFF9500)
    static let moodSerene = Color(hex: 0x34C759)
    static let moodNeutral = Color(hex: 0x5AC8FA)
    static let moodMelancholy = Color(hex: 0x5856D6)
    static let moodStorm = Color(hex: 0xAF52DE)
    static let moodDeep = Color(hex: 0xFF3B30)

    // MARK: - Habit Colors

    static let habitColors: [Color] = [
        Color(hex: 0xFF6B6B), Color(hex: 0xFECA57), Color(hex: 0x48DBFB),
        Color(hex: 0xFF9FF3), Color(hex: 0x54A0FF), Color(hex: 0x5FD068),
        Color(hex: 0xFFA502), Color(hex: 0xA29BFE)
    ]

    // MARK: - Typography

    static func displayFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headingFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func bodyFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func monoFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radii

    static let radiusS: CGFloat = 12
    static let radiusM: CGFloat = 20
    static let radiusL: CGFloat = 28
    static let radiusXL: CGFloat = 36

    // MARK: - Animation

    static let springResponse: Double = 0.6
    static let springDamping: Double = 0.8
    static let defaultSpring: Animation = .spring(response: 0.6, dampingFraction: 0.8)
    static let gentleSpring: Animation = .spring(response: 0.8, dampingFraction: 0.7)
    static let snappySpring: Animation = .spring(response: 0.35, dampingFraction: 0.85)
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Glass Morphism Modifier

struct GlassMorphism: ViewModifier {
    var cornerRadius: CGFloat = LuminaTheme.radiusM
    var opacity: Double = 0.12

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(opacity),
                                        Color.white.opacity(opacity * 0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func glassMorphism(cornerRadius: CGFloat = LuminaTheme.radiusM, opacity: Double = 0.12) -> some View {
        modifier(GlassMorphism(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.1),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    phase = 350
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}
