import SwiftUI

// MARK: - Tab Definition

enum LuminaTab: String, CaseIterable {
    case breathe, focus, mood, habits, insights

    var icon: String {
        switch self {
        case .breathe: return "wind"
        case .focus: return "bolt.fill"
        case .mood: return "heart.fill"
        case .habits: return "leaf.fill"
        case .insights: return "chart.bar.fill"
        }
    }

    var label: String {
        switch self {
        case .breathe: return "Breathe"
        case .focus: return "Focus"
        case .mood: return "Reflect"
        case .habits: return "Grow"
        case .insights: return "Insights"
        }
    }

    var color: Color {
        switch self {
        case .breathe: return Color(hex: 0x89F7FE)
        case .focus: return Color(hex: 0xFF6B6B)
        case .mood: return Color(hex: 0xFF9FF3)
        case .habits: return Color(hex: 0x5FD068)
        case .insights: return Color(hex: 0xA770EF)
        }
    }
}

// MARK: - Main Tab View

struct ContentView: View {
    @State private var selectedTab: LuminaTab = .breathe
    @State private var tabBarVisible = true

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                BreatheView()
                    .tag(LuminaTab.breathe)

                FocusTimerView()
                    .tag(LuminaTab.focus)

                MoodJournalView()
                    .tag(LuminaTab.mood)

                HabitTrackerView()
                    .tag(LuminaTab.habits)

                InsightsView()
                    .tag(LuminaTab.insights)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            customTabBar
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(LuminaTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    LuminaTheme.background.opacity(0.8),
                                    LuminaTheme.background.opacity(0.95)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: LuminaTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(LuminaTheme.snappySpring) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(tab.color.opacity(0.15))
                            .frame(width: 56, height: 32)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? tab.color : LuminaTheme.textTertiary)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(height: 32)

                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isSelected ? tab.color : LuminaTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environment(DataStore())
}
