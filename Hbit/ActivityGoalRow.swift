import SwiftUI

struct ActivityGoalRow: View {
    let goal: ActivityGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Image(systemName: "flag.pattern.checkered")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
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
