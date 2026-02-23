import SwiftUI

struct HabitTrackerView: View {
    @State private var vm = HabitViewModel()
    @Environment(DataStore.self) private var store

    var body: some View {
        ZStack {
            OrbBackground(color1: Color(hex: 0x5FD068), color2: LuminaTheme.surface)

            ScrollView(showsIndicators: false) {
                VStack(spacing: LuminaTheme.spacingL) {
                    header
                    overviewRings
                    habitsList
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, LuminaTheme.spacingM)
            }
        }
        .sheet(isPresented: $vm.showingAddSheet) {
            addHabitSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: LuminaTheme.spacingXS) {
                Text("Grow")
                    .font(LuminaTheme.displayFont(32))
                    .foregroundStyle(.white)
                Text("Build lasting habits")
                    .font(LuminaTheme.bodyFont(15))
                    .foregroundStyle(LuminaTheme.textSecondary)
            }

            Spacer()

            Button {
                vm.showingAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .glassMorphism(cornerRadius: 14)
            }
        }
        .padding(.top, LuminaTheme.spacingL)
    }

    // MARK: - Overview Rings

    private var overviewRings: some View {
        let completionRate = vm.overallCompletionRate(habits: store.habits)
        let streak = vm.longestStreak(habits: store.habits)

        return GlassCard {
            HStack(spacing: LuminaTheme.spacingL) {
                // Ring
                AnimatedRing(
                    progress: completionRate,
                    lineWidth: 10,
                    gradient: [Color(hex: 0x5FD068), Color(hex: 0x48DBFB)],
                    size: 80
                )
                .overlay(
                    VStack(spacing: 0) {
                        Text("\(Int(completionRate * 100))%")
                            .font(LuminaTheme.headingFont(18))
                            .foregroundStyle(.white)
                        Text("Today")
                            .font(LuminaTheme.bodyFont(10))
                            .foregroundStyle(LuminaTheme.textTertiary)
                    }
                )

                VStack(alignment: .leading, spacing: LuminaTheme.spacingS) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: 0x5FD068))
                        Text("\(store.habits.filter { $0.isCompletedToday() }.count)/\(store.habits.count) done")
                            .font(LuminaTheme.bodyFont(14))
                            .foregroundStyle(.white)
                    }

                    if let streak {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(streak.streak) day streak")
                                .font(LuminaTheme.bodyFont(14))
                                .foregroundStyle(.white)
                        }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Habits List

    private var habitsList: some View {
        VStack(spacing: LuminaTheme.spacingS) {
            if store.habits.isEmpty {
                emptyState
            } else {
                ForEach(store.habits) { habit in
                    habitCard(habit)
                }
            }
        }
    }

    private func habitCard(_ habit: Habit) -> some View {
        let isCompleted = habit.isCompletedToday()
        let isAnimating = vm.completionAnimatingId == habit.id

        return GlassCard(padding: LuminaTheme.spacingS + 4) {
            HStack(spacing: LuminaTheme.spacingM) {
                // Completion button
                Button {
                    withAnimation(LuminaTheme.snappySpring) {
                        store.toggleHabitCompletion(habit.id)
                        if !isCompleted {
                            vm.triggerCompletionAnimation(for: habit.id)
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? habit.color.opacity(0.3) : Color.white.opacity(0.06))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(habit.color.opacity(isCompleted ? 0.8 : 0.3), lineWidth: 2)
                            )

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(habit.color)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: habit.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(habit.color.opacity(0.6))
                        }

                        // Completion burst
                        if isAnimating {
                            ForEach(0..<8, id: \.self) { i in
                                Circle()
                                    .fill(habit.color)
                                    .frame(width: 4, height: 4)
                                    .offset(y: -30)
                                    .rotationEffect(.degrees(Double(i) * 45))
                                    .opacity(0)
                                    .scaleEffect(isAnimating ? 1.5 : 0)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(LuminaTheme.headingFont(16))
                        .foregroundStyle(isCompleted ? LuminaTheme.textSecondary : .white)
                        .strikethrough(isCompleted, color: LuminaTheme.textTertiary)

                    // Weekly dots
                    HStack(spacing: 3) {
                        ForEach(Array(habit.weeklyStatus().enumerated()), id: \.offset) { _, done in
                            Circle()
                                .fill(done ? habit.color : Color.white.opacity(0.12))
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                Spacer()

                // Streak
                if habit.currentStreak > 0 {
                    VStack(spacing: 2) {
                        Text("\(habit.currentStreak)")
                            .font(LuminaTheme.headingFont(18))
                            .foregroundStyle(habit.color)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(LuminaTheme.defaultSpring) {
                    store.deleteHabit(habit.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: LuminaTheme.spacingM) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: 0x5FD068).opacity(0.5))

                Text("Plant Your First Seed")
                    .font(LuminaTheme.headingFont(18))
                    .foregroundStyle(.white)

                Text("Start building habits that grow with you")
                    .font(LuminaTheme.bodyFont(14))
                    .foregroundStyle(LuminaTheme.textSecondary)
                    .multilineTextAlignment(.center)

                LuminaButton(title: "Add Habit", icon: "plus", color: Color(hex: 0x5FD068)) {
                    vm.showingAddSheet = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LuminaTheme.spacingM)
        }
    }

    // MARK: - Add Habit Sheet

    private var addHabitSheet: some View {
        NavigationStack {
            ZStack {
                LuminaTheme.background.ignoresSafeArea()

                VStack(spacing: LuminaTheme.spacingL) {
                    // Name
                    GlassCard {
                        VStack(alignment: .leading, spacing: LuminaTheme.spacingS) {
                            Text("Habit Name")
                                .font(LuminaTheme.headingFont(15))
                                .foregroundStyle(.white)

                            TextField("e.g., Drink water", text: $vm.newHabitName)
                                .font(LuminaTheme.bodyFont(16))
                                .foregroundStyle(.white)
                                .textFieldStyle(.plain)
                        }
                    }

                    // Icon
                    GlassCard {
                        VStack(alignment: .leading, spacing: LuminaTheme.spacingS) {
                            Text("Icon")
                                .font(LuminaTheme.headingFont(15))
                                .foregroundStyle(.white)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(HabitIcon.allCases, id: \.rawValue) { icon in
                                    Button {
                                        vm.newHabitIcon = icon.rawValue
                                    } label: {
                                        Image(systemName: icon.rawValue)
                                            .font(.system(size: 20))
                                            .foregroundStyle(vm.newHabitIcon == icon.rawValue ? .white : LuminaTheme.textSecondary)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(vm.newHabitIcon == icon.rawValue ? LuminaTheme.accent.opacity(0.3) : Color.white.opacity(0.06))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Color
                    GlassCard {
                        VStack(alignment: .leading, spacing: LuminaTheme.spacingS) {
                            Text("Color")
                                .font(LuminaTheme.headingFont(15))
                                .foregroundStyle(.white)

                            HStack(spacing: 10) {
                                ForEach(Array(LuminaTheme.habitColors.enumerated()), id: \.offset) { index, color in
                                    Button {
                                        vm.newHabitColorIndex = index
                                    } label: {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white, lineWidth: vm.newHabitColorIndex == index ? 2 : 0)
                                                    .padding(2)
                                            )
                                            .scaleEffect(vm.newHabitColorIndex == index ? 1.15 : 1.0)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(LuminaTheme.spacingM)
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.resetForm()
                        vm.showingAddSheet = false
                    }
                    .foregroundStyle(LuminaTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let habit = vm.createHabit() {
                            store.addHabit(habit)
                            vm.showingAddSheet = false
                        }
                    }
                    .foregroundStyle(LuminaTheme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
    }
}

#Preview {
    HabitTrackerView()
        .environment(DataStore())
}
