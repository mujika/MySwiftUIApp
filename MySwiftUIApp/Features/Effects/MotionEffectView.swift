import SwiftUI

struct MotionEffectView: View {
    let pitch: Double  // -1..1
    let roll: Double   // -1..1
    let isActive: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("モーション制御")
                .font(.headline)

            // Crosshair showing current tilt position
            ZStack {
                // Grid
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    .frame(width: 100, height: 100)
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 1, height: 150)
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 150, height: 1)

                // Position indicator
                if isActive {
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 20, height: 20)
                        .shadow(color: indicatorColor.opacity(0.5), radius: 6)
                        .offset(
                            x: CGFloat(roll) * 65,
                            y: CGFloat(-pitch) * 65
                        )
                        .animation(.easeOut(duration: 0.1), value: pitch)
                        .animation(.easeOut(duration: 0.1), value: roll)
                }
            }
            .frame(width: 150, height: 150)

            // Labels
            if isActive {
                HStack(spacing: 24) {
                    paramLabel("Pitch", value: pitch)
                    paramLabel("Roll", value: roll)
                }
            }

            // Control mapping description
            VStack(spacing: 4) {
                Text("前後傾き → ワウ / フィルター")
                Text("左右傾き → トレモロ速度")
                Text("シェイク → 録音開始/停止")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Button(action: onToggle) {
                Label(
                    isActive ? "モーション制御を停止" : "モーション制御を開始",
                    systemImage: isActive ? "gyroscope" : "gyroscope"
                )
                .font(.subheadline.bold())
                .foregroundStyle(isActive ? .red : .blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    (isActive ? Color.red : Color.blue).opacity(0.1),
                    in: Capsule()
                )
            }
        }
        .padding()
    }

    private func paramLabel(_ name: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f", value))
                .font(.system(size: 14, design: .monospaced))
        }
    }

    private var indicatorColor: Color {
        let intensity = sqrt(pitch * pitch + roll * roll)
        if intensity < 0.3 { return .green }
        if intensity < 0.7 { return .yellow }
        return .orange
    }
}
