import SwiftUI

// MARK: - Mood Types

enum MoodType: String, Codable, CaseIterable, Identifiable {
    case radiant, joyful, serene, neutral, melancholy, storm, deep

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .radiant: return "sun.max.fill"
        case .joyful: return "face.smiling.inverse"
        case .serene: return "leaf.fill"
        case .neutral: return "cloud.fill"
        case .melancholy: return "cloud.rain.fill"
        case .storm: return "cloud.bolt.fill"
        case .deep: return "moon.stars.fill"
        }
    }

    var label: String {
        switch self {
        case .radiant: return "Radiant"
        case .joyful: return "Joyful"
        case .serene: return "Serene"
        case .neutral: return "Neutral"
        case .melancholy: return "Melancholy"
        case .storm: return "Stormy"
        case .deep: return "Deep"
        }
    }

    var color: Color {
        switch self {
        case .radiant: return LuminaTheme.moodRadiant
        case .joyful: return LuminaTheme.moodJoyful
        case .serene: return LuminaTheme.moodSerene
        case .neutral: return LuminaTheme.moodNeutral
        case .melancholy: return LuminaTheme.moodMelancholy
        case .storm: return LuminaTheme.moodStorm
        case .deep: return LuminaTheme.moodDeep
        }
    }

    var intensity: Double {
        switch self {
        case .radiant: return 1.0
        case .joyful: return 0.85
        case .serene: return 0.7
        case .neutral: return 0.5
        case .melancholy: return 0.35
        case .storm: return 0.2
        case .deep: return 0.1
        }
    }
}

// MARK: - Mood Entry

struct MoodEntry: Identifiable, Codable {
    let id: UUID
    var mood: MoodType
    var note: String
    var date: Date
    var energyLevel: Double

    init(id: UUID = UUID(), mood: MoodType, note: String = "", date: Date = Date(), energyLevel: Double = 0.5) {
        self.id = id
        self.mood = mood
        self.note = note
        self.date = date
        self.energyLevel = energyLevel
    }
}
