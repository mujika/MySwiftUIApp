import SwiftUI

struct MoodJournalView: View {
    @State private var vm = MoodViewModel()
    @Environment(DataStore.self) private var store

    var body: some View {
        ZStack {
            let bgColor = vm.selectedMood?.color ?? LuminaTheme.accent
            OrbBackground(color1: bgColor, color2: LuminaTheme.surface)

            ScrollView(showsIndicators: false) {
                VStack(spacing: LuminaTheme.spacingXL) {
                    // Header
                    VStack(spacing: LuminaTheme.spacingXS) {
                        Text("Reflect")
                            .font(LuminaTheme.displayFont(32))
                            .foregroundStyle(.white)
                        Text("How are you feeling?")
                            .font(LuminaTheme.bodyFont(15))
                            .foregroundStyle(LuminaTheme.textSecondary)
                    }
                    .padding(.top, LuminaTheme.spacingL)

                    // Mood Selector
                    moodSelector

                    // Energy Slider
                    if vm.selectedMood != nil {
                        energySlider
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Note Input
                    if vm.selectedMood != nil {
                        noteInput
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Save Button
                    if vm.selectedMood != nil {
                        LuminaButton(
                            title: "Save Entry",
                            icon: "checkmark.circle.fill",
                            color: vm.selectedMood?.color ?? LuminaTheme.accent,
                            isLarge: true
                        ) {
                            if let entry = vm.createEntry() {
                                withAnimation(LuminaTheme.defaultSpring) {
                                    store.addMoodEntry(entry)
                                }
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Weekly Chart
                    weeklyChart

                    // Recent Entries
                    recentEntries

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, LuminaTheme.spacingM)
                .animation(LuminaTheme.defaultSpring, value: vm.selectedMood)
            }
        }
    }

    // MARK: - Mood Selector

    private var moodSelector: some View {
        VStack(spacing: LuminaTheme.spacingM) {
            // Top row
            HStack(spacing: LuminaTheme.spacingM) {
                ForEach(Array(MoodType.allCases.prefix(4)), id: \.self) { mood in
                    moodButton(mood)
                }
            }
            // Bottom row
            HStack(spacing: LuminaTheme.spacingM) {
                ForEach(Array(MoodType.allCases.suffix(3)), id: \.self) { mood in
                    moodButton(mood)
                }
            }
        }
    }

    private func moodButton(_ mood: MoodType) -> some View {
        let isSelected = vm.selectedMood == mood

        return Button {
            withAnimation(LuminaTheme.snappySpring) {
                vm.selectedMood = vm.selectedMood == mood ? nil : mood
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [mood.color.opacity(isSelected ? 0.5 : 0.2), mood.color.opacity(0.05)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 56, height: 56)
                        .scaleEffect(isSelected ? 1.15 : 1.0)

                    Image(systemName: mood.emoji)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? mood.color : mood.color.opacity(0.7))
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                }

                Text(mood.label)
                    .font(LuminaTheme.bodyFont(11))
                    .foregroundStyle(isSelected ? .white : LuminaTheme.textTertiary)
            }
            .overlay(
                Circle()
                    .stroke(mood.color.opacity(isSelected ? 0.6 : 0), lineWidth: 2)
                    .frame(width: 60, height: 60)
                    .offset(y: -3)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Energy Slider

    private var energySlider: some View {
        GlassCard {
            VStack(spacing: LuminaTheme.spacingS) {
                HStack {
                    Text("Energy Level")
                        .font(LuminaTheme.headingFont(15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(energyLabel)
                        .font(LuminaTheme.bodyFont(13))
                        .foregroundStyle(vm.selectedMood?.color ?? LuminaTheme.accent)
                }

                Slider(value: $vm.energyLevel, in: 0...1)
                    .tint(vm.selectedMood?.color ?? LuminaTheme.accent)

                HStack {
                    Text("Low")
                        .font(LuminaTheme.bodyFont(11))
                        .foregroundStyle(LuminaTheme.textTertiary)
                    Spacer()
                    Text("High")
                        .font(LuminaTheme.bodyFont(11))
                        .foregroundStyle(LuminaTheme.textTertiary)
                }
            }
        }
    }

    private var energyLabel: String {
        switch vm.energyLevel {
        case 0..<0.2: return "Depleted"
        case 0.2..<0.4: return "Low"
        case 0.4..<0.6: return "Moderate"
        case 0.6..<0.8: return "Energized"
        default: return "Vibrant"
        }
    }

    // MARK: - Note Input

    private var noteInput: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: LuminaTheme.spacingS) {
                Text("Notes")
                    .font(LuminaTheme.headingFont(15))
                    .foregroundStyle(.white)

                TextField("What's on your mind...", text: $vm.noteText, axis: .vertical)
                    .font(LuminaTheme.bodyFont(15))
                    .foregroundStyle(.white)
                    .lineLimit(3...6)
                    .textFieldStyle(.plain)
            }
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        let data = vm.weeklyMoodData(from: store.moodEntries)

        return GlassCard {
            VStack(alignment: .leading, spacing: LuminaTheme.spacingM) {
                Text("This Week")
                    .font(LuminaTheme.headingFont(17))
                    .foregroundStyle(.white)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            item.mood?.color ?? Color.white.opacity(0.1),
                                            (item.mood?.color ?? Color.white.opacity(0.1)).opacity(0.5)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: max(8, CGFloat(item.intensity) * 60))

                            Text(item.day)
                                .font(LuminaTheme.monoFont(10))
                                .foregroundStyle(LuminaTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)
            }
        }
    }

    // MARK: - Recent Entries

    private var recentEntries: some View {
        let recent = Array(store.moodEntries.prefix(5))

        return Group {
            if !recent.isEmpty {
                VStack(alignment: .leading, spacing: LuminaTheme.spacingS) {
                    SectionHeader(title: "Recent", subtitle: "\(store.moodEntries.count) entries total")
                        .padding(.horizontal, 4)

                    ForEach(recent) { entry in
                        moodEntryCard(entry)
                    }
                }
            }
        }
    }

    private func moodEntryCard(_ entry: MoodEntry) -> some View {
        GlassCard(padding: LuminaTheme.spacingS + 4) {
            HStack(spacing: LuminaTheme.spacingS) {
                // Mood indicator
                ZStack {
                    Circle()
                        .fill(entry.mood.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: entry.mood.emoji)
                        .foregroundStyle(entry.mood.color)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.mood.label)
                        .font(LuminaTheme.headingFont(15))
                        .foregroundStyle(.white)

                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(LuminaTheme.bodyFont(13))
                            .foregroundStyle(LuminaTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(entry.date.formatted(.dateTime.hour().minute()))
                    .font(LuminaTheme.monoFont(12))
                    .foregroundStyle(LuminaTheme.textTertiary)
            }
        }
    }
}

#Preview {
    MoodJournalView()
        .environment(DataStore())
}
