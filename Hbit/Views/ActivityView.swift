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
                                NavigationLink {
                                    ActivityDetailView(activity: activity)
                                } label: {
                                    ActivityRow(activity: activity)
                                }
                                .buttonStyle(.plain)
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
