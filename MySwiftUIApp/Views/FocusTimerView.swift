import SwiftUI

struct FocusTimerView: View {
    @State private var vm = FocusViewModel()
    @Environment(DataStore.self) private var store

    var body: some View {
        ZStack {
            OrbBackground(color1: vm.displayColor, color2: LuminaTheme.surface)

            VStack(spacing: LuminaTheme.spacingL) {
                // Header
                VStack(spacing: LuminaTheme.spacingXS) {
                    Text("Focus")
                        .font(LuminaTheme.displayFont(32))
                        .foregroundStyle(.white)

                    if vm.focusState == .idle {
                        Text("Choose your session")
                            .font(LuminaTheme.bodyFont(15))
                            .foregroundStyle(LuminaTheme.textSecondary)
                    }
                }
                .padding(.top, LuminaTheme.spacingL)

                // Category Selector (idle only)
                if vm.focusState == .idle {
                    categorySelector
                }

                Spacer()

                // Timer Ring
                ZStack {
                    OrbitalRingsView(
                        progress: vm.focusState == .running ? 1.0 : 0.3,
                        color: vm.displayColor
                    )
                    .frame(width: 300, height: 300)
                    .opacity(vm.focusState == .idle ? 0.3 : 0.6)

                    TimerRing(
                        progress: vm.focusState == .breakTime ? vm.breakProgress : vm.progress,
                        timeString: vm.timeString,
                        subtitle: vm.subtitle,
                        color: vm.displayColor
                    )
                }

                // Session counter
                sessionIndicator

                Spacer()

                // Duration Picker (idle only)
                if vm.focusState == .idle {
                    durationPicker
                }

                // Controls
                controlButtons
                    .padding(.bottom, LuminaTheme.spacingXXL + 30)
            }
        }
    }

    // MARK: - Category Selector

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LuminaTheme.spacingS) {
                ForEach(FocusCategory.allCases) { cat in
                    Button {
                        withAnimation(LuminaTheme.snappySpring) {
                            vm.selectCategory(cat)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 14))
                            Text(cat.label)
                                .font(LuminaTheme.headingFont(14))
                        }
                        .foregroundStyle(vm.category == cat ? .white : LuminaTheme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(vm.category == cat ? cat.color.opacity(0.3) : Color.white.opacity(0.06))
                                .overlay(
                                    Capsule()
                                        .stroke(vm.category == cat ? cat.color.opacity(0.5) : .clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, LuminaTheme.spacingM)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Duration Picker

    private var durationPicker: some View {
        VStack(spacing: LuminaTheme.spacingS) {
            Text("Duration")
                .font(LuminaTheme.bodyFont(13))
                .foregroundStyle(LuminaTheme.textTertiary)

            HStack(spacing: LuminaTheme.spacingS) {
                ForEach([10, 15, 25, 45, 60], id: \.self) { mins in
                    Button {
                        withAnimation(LuminaTheme.snappySpring) {
                            vm.setDuration(minutes: mins)
                        }
                    } label: {
                        Text("\(mins)m")
                            .font(LuminaTheme.headingFont(14))
                            .foregroundStyle(vm.totalSeconds == mins * 60 ? .white : LuminaTheme.textSecondary)
                            .frame(width: 48, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(vm.totalSeconds == mins * 60 ? vm.category.color.opacity(0.3) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Session Indicator

    private var sessionIndicator: some View {
        HStack(spacing: LuminaTheme.spacingS) {
            if vm.sessionsCompleted > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(vm.sessionsCompleted) session\(vm.sessionsCompleted == 1 ? "" : "s")")
                        .font(LuminaTheme.bodyFont(13))
                        .foregroundStyle(LuminaTheme.textSecondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 20)
        .animation(LuminaTheme.defaultSpring, value: vm.sessionsCompleted)
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: LuminaTheme.spacingL) {
            if vm.focusState != .idle {
                LuminaButton(title: "Reset", icon: "arrow.counterclockwise", color: Color(hex: 0xFF6B6B)) {
                    withAnimation(LuminaTheme.defaultSpring) {
                        vm.reset()
                    }
                }
            }

            LuminaButton(
                title: playButtonTitle,
                icon: playButtonIcon,
                color: vm.displayColor,
                isLarge: vm.focusState == .idle
            ) {
                withAnimation(LuminaTheme.defaultSpring) {
                    if vm.focusState == .completed {
                        store.addFocusSession(vm.createSession())
                    }
                    vm.togglePlayPause()
                }
            }
        }
    }

    private var playButtonTitle: String {
        switch vm.focusState {
        case .idle: return "Start Focus"
        case .running: return "Pause"
        case .paused: return "Resume"
        case .breakTime: return "Skip"
        case .completed: return "Done"
        }
    }

    private var playButtonIcon: String {
        switch vm.focusState {
        case .idle: return "bolt.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        case .breakTime: return "forward.fill"
        case .completed: return "checkmark"
        }
    }
}

#Preview {
    FocusTimerView()
        .environment(DataStore())
}
