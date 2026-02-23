import SwiftUI

// MARK: - Focus Category

enum FocusCategory: String, Codable, CaseIterable, Identifiable {
    case work, study, create, read, meditate

    var id: String { rawValue }

    var label: String {
        switch self {
        case .work: return "Work"
        case .study: return "Study"
        case .create: return "Create"
        case .read: return "Read"
        case .meditate: return "Meditate"
        }
    }

    var icon: String {
        switch self {
        case .work: return "laptopcomputer"
        case .study: return "graduationcap.fill"
        case .create: return "paintbrush.fill"
        case .read: return "book.fill"
        case .meditate: return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .work: return Color(hex: 0xFF6B6B)
        case .study: return Color(hex: 0x54A0FF)
        case .create: return Color(hex: 0xFF9FF3)
        case .read: return Color(hex: 0x5FD068)
        case .meditate: return Color(hex: 0xFECA57)
        }
    }

    var defaultMinutes: Int {
        switch self {
        case .work: return 25
        case .study: return 45
        case .create: return 30
        case .read: return 20
        case .meditate: return 10
        }
    }
}

// MARK: - Focus Session

struct FocusSession: Identifiable, Codable {
    let id: UUID
    var category: FocusCategory
    var durationMinutes: Int
    var completedAt: Date
    var wasCompleted: Bool

    init(
        id: UUID = UUID(),
        category: FocusCategory,
        durationMinutes: Int,
        completedAt: Date = Date(),
        wasCompleted: Bool = true
    ) {
        self.id = id
        self.category = category
        self.durationMinutes = durationMinutes
        self.completedAt = completedAt
        self.wasCompleted = wasCompleted
    }
}

// MARK: - Breathing Pattern

enum BreathPattern: String, CaseIterable, Identifiable {
    case calm
    case box
    case energize
    case sleep478

    var id: String { rawValue }

    var label: String {
        switch self {
        case .calm: return "Calm"
        case .box: return "Box"
        case .energize: return "Energize"
        case .sleep478: return "4-7-8 Sleep"
        }
    }

    var description: String {
        switch self {
        case .calm: return "Gentle rhythm for relaxation"
        case .box: return "Equal phases for balance"
        case .energize: return "Quick inhale, slow exhale"
        case .sleep478: return "Deep sleep preparation"
        }
    }

    /// Returns (inhale, hold1, exhale, hold2) durations in seconds
    var phases: (Double, Double, Double, Double) {
        switch self {
        case .calm: return (4, 0, 6, 0)
        case .box: return (4, 4, 4, 4)
        case .energize: return (2, 0, 4, 0)
        case .sleep478: return (4, 7, 8, 0)
        }
    }

    var totalCycleDuration: Double {
        let p = phases
        return p.0 + p.1 + p.2 + p.3
    }
}
