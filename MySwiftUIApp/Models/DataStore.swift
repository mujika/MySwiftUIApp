import Foundation
import Observation

// MARK: - Persistent Data Store

@Observable
final class DataStore {
    var moodEntries: [MoodEntry] {
        didSet { save(moodEntries, forKey: "lumina_moods") }
    }

    var habits: [Habit] {
        didSet { save(habits, forKey: "lumina_habits") }
    }

    var focusSessions: [FocusSession] {
        didSet { save(focusSessions, forKey: "lumina_focus") }
    }

    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "lumina_onboarded") }
    }

    var totalBreathMinutes: Int {
        didSet { UserDefaults.standard.set(totalBreathMinutes, forKey: "lumina_breath_minutes") }
    }

    init() {
        self.moodEntries = Self.load(forKey: "lumina_moods") ?? []
        self.habits = Self.load(forKey: "lumina_habits") ?? []
        self.focusSessions = Self.load(forKey: "lumina_focus") ?? []
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "lumina_onboarded")
        self.totalBreathMinutes = UserDefaults.standard.integer(forKey: "lumina_breath_minutes")
    }

    // MARK: - Mood

    func addMoodEntry(_ entry: MoodEntry) {
        moodEntries.insert(entry, at: 0)
    }

    func moodEntriesForWeek() -> [MoodEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return moodEntries.filter { $0.date >= weekAgo }
    }

    // MARK: - Habits

    func addHabit(_ habit: Habit) {
        habits.append(habit)
    }

    func toggleHabitCompletion(_ habitId: UUID) {
        guard let index = habits.firstIndex(where: { $0.id == habitId }) else { return }
        let calendar = Calendar.current
        if habits[index].isCompletedToday() {
            habits[index].completedDates.removeAll { calendar.isDateInToday($0) }
        } else {
            habits[index].completedDates.append(Date())
        }
    }

    func deleteHabit(_ habitId: UUID) {
        habits.removeAll { $0.id == habitId }
    }

    // MARK: - Focus

    func addFocusSession(_ session: FocusSession) {
        focusSessions.insert(session, at: 0)
    }

    func totalFocusMinutesToday() -> Int {
        let calendar = Calendar.current
        return focusSessions
            .filter { calendar.isDateInToday($0.completedAt) && $0.wasCompleted }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    func totalFocusMinutesThisWeek() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return focusSessions
            .filter { $0.completedAt >= weekAgo && $0.wasCompleted }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    // MARK: - Persistence Helpers

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
