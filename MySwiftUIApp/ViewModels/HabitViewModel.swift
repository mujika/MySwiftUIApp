import SwiftUI
import Observation

@Observable
final class HabitViewModel {
    var showingAddSheet = false
    var newHabitName = ""
    var newHabitIcon: String = HabitIcon.water.rawValue
    var newHabitColorIndex: Int = 0
    var completionAnimatingId: UUID? = nil

    func createHabit() -> Habit? {
        let trimmed = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let habit = Habit(
            name: trimmed,
            icon: newHabitIcon,
            colorIndex: newHabitColorIndex
        )
        resetForm()
        return habit
    }

    func resetForm() {
        newHabitName = ""
        newHabitIcon = HabitIcon.water.rawValue
        newHabitColorIndex = 0
    }

    func triggerCompletionAnimation(for id: UUID) {
        completionAnimatingId = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            if self?.completionAnimatingId == id {
                self?.completionAnimatingId = nil
            }
        }
    }

    func overallCompletionRate(habits: [Habit]) -> Double {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { $0.isCompletedToday() }.count
        return Double(completed) / Double(habits.count)
    }

    func longestStreak(habits: [Habit]) -> (habit: Habit, streak: Int)? {
        guard !habits.isEmpty else { return nil }
        let best = habits.max(by: { $0.currentStreak < $1.currentStreak })!
        guard best.currentStreak > 0 else { return nil }
        return (best, best.currentStreak)
    }
}
