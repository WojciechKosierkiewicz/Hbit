import SwiftUI

struct ActivityRow: View {
    let activity: Activity

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: activity.date)
    }

    private var iconName: String {
        switch activity.type.lowercased() {
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        case "cycling", "biking": return "bicycle"
        case "hiking": return "figure.hiking"
        case "swimming": return "figure.pool.swim"
        case "gym", "workout", "strength": return "dumbbell"
        default: return "figure.walk"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(formattedDate) • \(activity.type)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let user = activity.user, let userName = user.name, !userName.isEmpty {
                Text(userName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.name), \(activity.type), \(formattedDate)")
    }
}
