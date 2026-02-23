import SwiftUI

struct InsightsView: View {
    @Environment(DataStore.self) private var store
    @State private var selectedPeriod: TimePeriod = .week
    @State private var appeared = false

    enum TimePeriod: String, CaseIterable {
        case week = "7D"
        case month = "30D"
    }

    var body: some View {
        ZStack {
            OrbBackground(color1: LuminaTheme.accent, color2: Color(hex: 0x302B63))

            ScrollView(showsIndicators: false) {
                VStack(spacing: LuminaTheme.spacingL) {
                    header
                    periodPicker
                    summaryCards
                    focusBreakdown
                    moodTrend
                    habitPerformance
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, LuminaTheme.spacingM)
                .opacity(appeared ? 1 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        appeared = true
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: LuminaTheme.spacingXS) {
            Text("Insights")
                .font(LuminaTheme.displayFont(32))
                .foregroundStyle(.white)
            Text(greetingText)
                .font(LuminaTheme.bodyFont(15))
                .foregroundStyle(LuminaTheme.textSecondary)
        }
        .padding(.top, LuminaTheme.spacingL)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(LuminaTheme.snappySpring) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(LuminaTheme.headingFont(14))
                        .foregroundStyle(selectedPeriod == period ? .white : LuminaTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? LuminaTheme.accent.opacity(0.3) : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassMorphism(cornerRadius: LuminaTheme.radiusL)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        let days = selectedPeriod == .week ? 7 : 30
        let focusMinutes = focusMinutesForPeriod(days: days)
        let moodCount = moodCountForPeriod(days: days)
        let habitRate = averageHabitRate(days: days)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LuminaTheme.spacingS) {
            StatCard(
                title: "Focus Time",
                value: formatMinutes(focusMinutes),
                icon: "bolt.fill",
                color: Color(hex: 0xFF6B6B),
                subtitle: "\(store.focusSessions.count) sessions"
            )

            StatCard(
                title: "Reflections",
                value: "\(moodCount)",
                icon: "heart.fill",
                color: Color(hex: 0xFF9FF3),
                subtitle: dominantMoodLabel
            )

            StatCard(
                title: "Habit Score",
                value: "\(Int(habitRate * 100))%",
                icon: "leaf.fill",
                color: Color(hex: 0x5FD068),
                subtitle: "\(store.habits.count) habits tracked"
            )

            StatCard(
                title: "Breath",
                value: "\(store.totalBreathMinutes)m",
                icon: "wind",
                color: Color(hex: 0x89F7FE),
                subtitle: "Total mindfulness"
            )
        }
    }

    // MARK: - Focus Breakdown

    private var focusBreakdown: some View {
        let categoryData = focusByCategory()

        return Group {
            if !categoryData.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: LuminaTheme.spacingM) {
                        Text("Focus Breakdown")
                            .font(LuminaTheme.headingFont(17))
                            .foregroundStyle(.white)

                        ForEach(categoryData, id: \.category.id) { item in
                            HStack(spacing: LuminaTheme.spacingS) {
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(item.category.color)
                                    .frame(width: 28)

                                Text(item.category.label)
                                    .font(LuminaTheme.bodyFont(14))
                                    .foregroundStyle(.white)
                                    .frame(width: 60, alignment: .leading)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color.white.opacity(0.06))

                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [item.category.color, item.category.color.opacity(0.5)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geo.size.width * item.percentage)
                                    }
                                }
                                .frame(height: 8)

                                Text(formatMinutes(item.minutes))
                                    .font(LuminaTheme.monoFont(12))
                                    .foregroundStyle(LuminaTheme.textSecondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mood Trend

    private var moodTrend: some View {
        let entries = store.moodEntriesForWeek()

        return Group {
            if !entries.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: LuminaTheme.spacingM) {
                        Text("Mood Distribution")
                            .font(LuminaTheme.headingFont(17))
                            .foregroundStyle(.white)

                        let distribution = MoodViewModel().moodDistribution(from: entries)

                        ForEach(distribution, id: \.mood) { item in
                            HStack(spacing: LuminaTheme.spacingS) {
                                Image(systemName: item.mood.emoji)
                                    .foregroundStyle(item.mood.color)
                                    .frame(width: 24)

                                Text(item.mood.label)
                                    .font(LuminaTheme.bodyFont(14))
                                    .foregroundStyle(.white)
                                    .frame(width: 80, alignment: .leading)

                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(item.mood.color.opacity(0.6))
                                        .frame(width: geo.size.width * item.percentage)
                                }
                                .frame(height: 8)

                                Text("\(item.count)")
                                    .font(LuminaTheme.monoFont(12))
                                    .foregroundStyle(LuminaTheme.textTertiary)
                                    .frame(width: 24, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Habit Performance

    private var habitPerformance: some View {
        Group {
            if !store.habits.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: LuminaTheme.spacingM) {
                        Text("Habit Streaks")
                            .font(LuminaTheme.headingFont(17))
                            .foregroundStyle(.white)

                        ForEach(store.habits.sorted(by: { $0.currentStreak > $1.currentStreak })) { habit in
                            HStack(spacing: LuminaTheme.spacingS) {
                                Image(systemName: habit.icon)
                                    .foregroundStyle(habit.color)
                                    .frame(width: 24)

                                Text(habit.name)
                                    .font(LuminaTheme.bodyFont(14))
                                    .foregroundStyle(.white)

                                Spacer()

                                AnimatedRing(
                                    progress: habit.completionRate(),
                                    lineWidth: 3,
                                    gradient: [habit.color, habit.color.opacity(0.5)],
                                    size: 28,
                                    showGlow: false
                                )

                                if habit.currentStreak > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.orange)
                                        Text("\(habit.currentStreak)")
                                            .font(LuminaTheme.monoFont(13))
                                            .foregroundStyle(.orange)
                                    }
                                    .frame(width: 36)
                                } else {
                                    Text("-")
                                        .font(LuminaTheme.monoFont(13))
                                        .foregroundStyle(LuminaTheme.textTertiary)
                                        .frame(width: 36)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data Helpers

    private func focusMinutesForPeriod(days: Int) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        return store.focusSessions
            .filter { $0.completedAt >= startDate && $0.wasCompleted }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    private func moodCountForPeriod(days: Int) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        return store.moodEntries.filter { $0.date >= startDate }.count
    }

    private func averageHabitRate(days: Int) -> Double {
        guard !store.habits.isEmpty else { return 0 }
        let rates = store.habits.map { $0.completionRate(days: days) }
        return rates.reduce(0, +) / Double(rates.count)
    }

    private var dominantMoodLabel: String {
        let weekly = store.moodEntriesForWeek()
        guard !weekly.isEmpty else { return "No data yet" }
        let distribution = MoodViewModel().moodDistribution(from: weekly)
        return distribution.first?.mood.label ?? "Mixed"
    }

    private func focusByCategory() -> [(category: FocusCategory, minutes: Int, percentage: Double)] {
        let days = selectedPeriod == .week ? 7 : 30
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let relevant = store.focusSessions.filter { $0.completedAt >= startDate && $0.wasCompleted }
        guard !relevant.isEmpty else { return [] }

        var byCategory: [FocusCategory: Int] = [:]
        for session in relevant {
            byCategory[session.category, default: 0] += session.durationMinutes
        }
        let total = byCategory.values.reduce(0, +)
        guard total > 0 else { return [] }

        return byCategory.map { ($0.key, $0.value, Double($0.value) / Double(total)) }
            .sorted { $0.minutes > $1.minutes }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }
}

#Preview {
    InsightsView()
        .environment(DataStore())
}
