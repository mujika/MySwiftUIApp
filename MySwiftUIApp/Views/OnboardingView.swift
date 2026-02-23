import SwiftUI

struct OnboardingView: View {
    @Environment(DataStore.self) private var store
    @State private var currentPage = 0
    @State private var appeared = false

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("sparkles", "Welcome to Lumina", "Illuminate your inner world through mindful practice", Color(hex: 0xA770EF)),
        ("wind", "Breathe", "Find calm with guided breathing exercises and beautiful visualizations", Color(hex: 0x89F7FE)),
        ("bolt.fill", "Focus", "Deep work sessions with elegant timers that keep you in flow", Color(hex: 0xFF6B6B)),
        ("heart.fill", "Reflect", "Track your emotional landscape and discover patterns", Color(hex: 0xFF9FF3)),
        ("leaf.fill", "Grow", "Build lasting habits with satisfying streaks and progress rings", Color(hex: 0x5FD068)),
    ]

    var body: some View {
        ZStack {
            OrbBackground(
                color1: pages[currentPage].color,
                color2: LuminaTheme.surface
            )
            .animation(.easeInOut(duration: 0.8), value: currentPage)

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [pages[currentPage].color.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)

                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(pages[currentPage].color)
                        .symbolEffect(.pulse, isActive: true)
                }
                .animation(.easeInOut(duration: 0.5), value: currentPage)

                Spacer()
                    .frame(height: LuminaTheme.spacingXXL)

                // Text
                VStack(spacing: LuminaTheme.spacingM) {
                    Text(pages[currentPage].title)
                        .font(LuminaTheme.displayFont(28))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(pages[currentPage].subtitle)
                        .font(LuminaTheme.bodyFont(16))
                        .foregroundStyle(LuminaTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, LuminaTheme.spacingXL)
                }
                .animation(.easeInOut(duration: 0.4), value: currentPage)

                Spacer()

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? pages[currentPage].color : Color.white.opacity(0.2))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(LuminaTheme.snappySpring, value: currentPage)
                    }
                }
                .padding(.bottom, LuminaTheme.spacingL)

                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(LuminaTheme.defaultSpring) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            store.hasCompletedOnboarding = true
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Begin Journey")
                            .font(LuminaTheme.headingFont(17))

                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: pages[currentPage].color.opacity(0.4), radius: 16, y: 8)
                    )
                    .padding(.horizontal, LuminaTheme.spacingXL)
                }
                .buttonStyle(.plain)

                // Skip
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            store.hasCompletedOnboarding = true
                        }
                    } label: {
                        Text("Skip")
                            .font(LuminaTheme.bodyFont(15))
                            .foregroundStyle(LuminaTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, LuminaTheme.spacingM)
                }

                Spacer()
                    .frame(height: LuminaTheme.spacingXL)
            }
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    appeared = true
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(DataStore())
}
