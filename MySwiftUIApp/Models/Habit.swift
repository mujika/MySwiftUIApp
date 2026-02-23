import SwiftUI

// MARK: - Habit Model

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var colorIndex: Int
    var targetCount: Int
    var completedDates: [Date]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "star.fill",
        colorIndex: Int = 0,
        targetCount: Int = 1,
        completedDates: [Date] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorIndex = colorIndex
        self.targetCount = targetCount
        self.completedDates = completedDates
        self.createdAt = createdAt
    }

    var color: Color {
        LuminaTheme.habitColors[colorIndex % LuminaTheme.habitColors.count]
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while completedDates.contains(where: { calendar.isDate($0, inSameDayAs: checkDate) }) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        }
        return streak
    }

    func isCompletedToday() -> Bool {
        let calendar = Calendar.current
        return completedDates.contains { calendar.isDateInToday($0) }
    }

    func completionRate(days: Int = 7) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: Date()))!
        let completedInRange = completedDates.filter { $0 >= startDate }.count
        return min(Double(completedInRange) / Double(days), 1.0)
    }

    func weeklyStatus() -> [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            return completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
        }
    }
}

// MARK: - Habit Icons

enum HabitIcon: String, CaseIterable {
    case water = "drop.fill"
    case exercise = "figure.run"
    case read = "book.fill"
    case meditate = "brain.head.profile"
    case sleep = "bed.double.fill"
    case code = "chevron.left.forwardslash.chevron.right"
    case write = "pencil.line"
    case music = "music.note"
    case walk = "figure.walk"
    case stretch = "figure.flexibility"
    case journal = "note.text"
    case vitamin = "pill.fill"
}
