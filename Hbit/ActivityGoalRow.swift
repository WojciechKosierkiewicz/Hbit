import SwiftUI

struct ActivityGoalRow: View {
    let goal: ActivityGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                TimeProgressCircle(progress: progress, size: 40, lineWidth: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(goal.timeLeftString())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(goal.targetValue)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(goal.range)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Accepted activity icons at the bottom
            if !goal.acceptedActivityTypes.isEmpty {
                HStack(spacing: 10) {
                    ForEach(goal.acceptedActivityTypes, id: \.self) { type in
                        Image(systemName: iconName(for: type))
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Progress calculation

    private var progress: Double {
        let now = Date()
        let start = goal.startsAt
        let end = goal.endsAt

        guard end > start else { return 1.0 } // avoid division by zero; treat as complete
        if now <= start { return 0.0 }
        if now >= end { return 1.0 }

        let total = end.timeIntervalSince(start)
        let elapsed = now.timeIntervalSince(start)
        return min(max(elapsed / total, 0.0), 1.0)
    }

    // MARK: - Icons for accepted types

    private func iconName(for type: String) -> String {
        switch type.lowercased() {
        case "running": return "figure.run"
        case "swimming": return "figure.pool.swim"
        case "biking", "cycling": return "bicycle"
        case "hiking": return "figure.hiking"
        case "gym", "workout", "strength": return "dumbbell"
        case "walking": return "figure.walk"
        default: return "figure.walk"
        }
    }
}

// MARK: - Circular progress view

private struct TimeProgressCircle: View {
    let progress: Double   // 0.0 ... 1.0
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.25), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.blue, Color.green]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // start at top

            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Time progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}
