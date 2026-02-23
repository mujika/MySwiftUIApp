import SwiftUI
import Observation

@Observable
final class MoodViewModel {
    var selectedMood: MoodType? = nil
    var noteText: String = ""
    var energyLevel: Double = 0.5
    var showingDetail = false
    var selectedEntry: MoodEntry? = nil

    func createEntry() -> MoodEntry? {
        guard let mood = selectedMood else { return nil }
        let entry = MoodEntry(
            mood: mood,
            note: noteText,
            energyLevel: energyLevel
        )
        reset()
        return entry
    }

    func reset() {
        selectedMood = nil
        noteText = ""
        energyLevel = 0.5
    }

    func weeklyMoodData(from entries: [MoodEntry]) -> [(day: String, mood: MoodType?, intensity: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let avgIntensity = dayEntries.isEmpty ? 0 : dayEntries.reduce(0.0) { $0 + $1.mood.intensity } / Double(dayEntries.count)
            let dominantMood = dayEntries.max(by: { $0.date < $1.date })?.mood
            return (formatter.string(from: date), dominantMood, avgIntensity)
        }
    }

    func moodDistribution(from entries: [MoodEntry]) -> [(mood: MoodType, count: Int, percentage: Double)] {
        guard !entries.isEmpty else { return [] }
        var counts: [MoodType: Int] = [:]
        for entry in entries {
            counts[entry.mood, default: 0] += 1
        }
        return counts.map { (mood: $0.key, count: $0.value, percentage: Double($0.value) / Double(entries.count)) }
            .sorted { $0.count > $1.count }
    }
}
