import SwiftUI

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = LuminaTheme.spacingM
    var cornerRadius: CGFloat = LuminaTheme.radiusM

    init(
        padding: CGFloat = LuminaTheme.spacingM,
        cornerRadius: CGFloat = LuminaTheme.radiusM,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .glassMorphism(cornerRadius: cornerRadius)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil

    @State private var appeared = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: LuminaTheme.spacingS) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Spacer()
                }

                Text(value)
                    .font(LuminaTheme.displayFont(28))
                    .foregroundStyle(.white)

                Text(title)
                    .font(LuminaTheme.bodyFont(13))
                    .foregroundStyle(LuminaTheme.textSecondary)

                if let subtitle {
                    Text(subtitle)
                        .font(LuminaTheme.bodyFont(11))
                        .foregroundStyle(LuminaTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(LuminaTheme.defaultSpring) {
                appeared = true
            }
        }
    }
}

// MARK: - Action Button

struct LuminaButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var isLarge: Bool = false

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: LuminaTheme.spacingS) {
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 18 : 15, weight: .semibold))
                Text(title)
                    .font(isLarge ? LuminaTheme.headingFont(17) : LuminaTheme.headingFont(15))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, isLarge ? LuminaTheme.spacingXL : LuminaTheme.spacingL)
            .padding(.vertical, isLarge ? LuminaTheme.spacingM : LuminaTheme.spacingS + 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.4), radius: isPressed ? 4 : 12, y: isPressed ? 2 : 6)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(LuminaTheme.snappySpring) { isPressed = pressing }
        }, perform: {})
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(LuminaTheme.headingFont(22))
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(LuminaTheme.bodyFont(14))
                    .foregroundStyle(LuminaTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
