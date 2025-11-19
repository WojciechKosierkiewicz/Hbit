import SwiftUI

public struct ActivityView: View {
    @State private var showAccount = false
    @State private var activities: [Activity] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.6), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 400)
                .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if activities.isEmpty {
                    Text("No activities found.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(activities) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationTitle("My Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAccount.toggle()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showAccount) {
            AccountView()
        }
        .onAppear {
            Task {
                await loadActivities()
            }
        }
    }

    @MainActor
    private func loadActivities() async {
        isLoading = true
        errorMessage = nil
        do {
            activities = try await ActivityService.shared.fetchAllActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                Image(systemName: iconName(for: activity.type))
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                VStack(alignment: .leading) {
                    Text(activity.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(activity.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(activity.type)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("User ID: \(activity.userId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            // You can extend with more info (heartRateSamples, etc) if needed
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func iconName(for type: String) -> String {
        switch type.lowercased() {
        case "hiking": return "figure.hiking"
        case "cycling": return "bicycle"
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        default: return "figure.walk"
        }
    }
}
