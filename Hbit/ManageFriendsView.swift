import SwiftUI

struct ManageFriendsView: View {
    @Environment(\.dismiss) private var dismiss

    // Placeholder state
    @State private var friends: [String] = ["Alice", "Bob", "Charlie", "Diana"]
    @State private var pendingRequests: [String] = ["Eve"]
    @State private var searchText: String = ""

    private var filteredFriends: [String] {
        guard !searchText.isEmpty else { return friends }
        return friends.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !pendingRequests.isEmpty {
                    Section("Requests") {
                        ForEach(pendingRequests, id: \.self) { name in
                            HStack {
                                Text(name)
                                Spacer()
                                Button("Accept") {
                                    accept(name)
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Decline", role: .destructive) {
                                    decline(name)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                Section("Friends") {
                    if filteredFriends.isEmpty {
                        Text("No friends found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredFriends, id: \.self) { name in
                            HStack {
                                Text(name)
                                Spacer()
                                Button(role: .destructive) {
                                    remove(name)
                                } label: {
                                    Image(systemName: "person.fill.xmark")
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove \(name)")
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Manage Friends")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addRandomFriend()
                    } label: {
                        Label("Add Friend", systemImage: "person.badge.plus")
                    }
                }
            }
        }
    }

    // MARK: - Placeholder actions

    private func accept(_ name: String) {
        pendingRequests.removeAll { $0 == name }
        if !friends.contains(name) {
            friends.append(name)
        }
    }

    private func decline(_ name: String) {
        pendingRequests.removeAll { $0 == name }
    }

    private func remove(_ name: String) {
        friends.removeAll { $0 == name }
    }

    private func addRandomFriend() {
        let pool = ["Frank", "Grace", "Heidi", "Ivan", "Judy", "Mallory", "Niaj"]
        if let candidate = pool.shuffled().first(where: { !friends.contains($0) }) {
            friends.append(candidate)
        }
    }
}

#Preview {
    ManageFriendsView()
}
