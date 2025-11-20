import SwiftUI

struct ManageFriendsView: View {
    @Environment(\.dismiss) private var dismiss

    // Real state from API
    @State private var friends: [FriendWithDetails] = []
    @State private var friendRequests: [FriendRequestWithDetails] = []
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Search results
    @State private var searchResults: [UserProfile] = []
    @State private var isSearching = false
    
    // Confirmation alert
    @State private var showRemoveConfirmation = false
    @State private var friendToRemove: FriendWithDetails?

    private var filteredFriends: [FriendWithDetails] {
        guard !searchText.isEmpty else { return friends }
        return friends.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var suggestedUsers: [UserProfile] {
        // Filter out users who are already friends
        let friendUserIds = Set(friends.map { $0.userId })
        return searchResults
            .filter { !friendUserIds.contains($0.id) }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            List {
                // Loading indicator
                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Friend requests from API
                if !friendRequests.isEmpty {
                    Section("Requests") {
                        ForEach(friendRequests) { request in
                            FriendRequestRow(
                                request: request,
                                onAccept: { acceptRequest(request) },
                                onDecline: { declineRequest(request) }
                            )
                        }
                    }
                }
                
                // Suggested users (when searching and results found)
                if !searchText.isEmpty && !suggestedUsers.isEmpty {
                    Section("Add Friends") {
                        if isSearching {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            ForEach(suggestedUsers) { user in
                                UserSearchRow(user: user, onAdd: {
                                    sendFriendRequest(to: user)
                                })
                            }
                        }
                    }
                }

                Section("Friends") {
                    if filteredFriends.isEmpty {
                        Text("No friends found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredFriends) { friend in
                            FriendRow(friend: friend, onRemove: {
                                removeFriend(friend)
                            })
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: searchText) { oldValue, newValue in
                Task {
                    await performSearch(query: newValue)
                }
            }
            .navigationTitle("Manage Friends")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await loadData() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadData()
            }
            .alert("Remove Friend?", isPresented: $showRemoveConfirmation, presenting: friendToRemove) { friend in
                Button("Cancel", role: .cancel) {
                    friendToRemove = nil
                }
                Button("Remove", role: .destructive) {
                    Task {
                        await confirmRemoveFriend(friend)
                    }
                }
            } message: { friend in
                Text("Are you sure you want to remove \(friend.username) from your friends?")
            }
        }
    }

    // MARK: - API Actions
    
    @MainActor
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        do {
            searchResults = try await FriendsService.shared.searchUsers(query: query)
        } catch {
            print("Search failed: \(error)")
            searchResults = []
        }
        
        isSearching = false
    }
    
    @MainActor
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        async let requestsTask = FriendsService.shared.fetchFriendRequestsWithDetails()
        async let friendsTask = FriendsService.shared.fetchFriendsWithDetails()
        
        do {
            let (fetchedRequests, fetchedFriends) = try await (requestsTask, friendsTask)
            friendRequests = fetchedRequests
            friends = fetchedFriends
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load friends data: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadFriendRequests() async {
        isLoading = true
        errorMessage = nil
        
        do {
            friendRequests = try await FriendsService.shared.fetchFriendRequestsWithDetails()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load friend requests: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    private func acceptRequest(_ request: FriendRequestWithDetails) {
        Task {
            do {
                try await FriendsService.shared.acceptFriendRequest(requestId: request.id)
                // Remove from local list and reload all data to get updated friends list
                friendRequests.removeAll { $0.id == request.id }
                await loadData()
            } catch {
                errorMessage = "Failed to accept request: \(error.localizedDescription)"
            }
        }
    }
    
    @MainActor
    private func declineRequest(_ request: FriendRequestWithDetails) {
        Task {
            do {
                try await FriendsService.shared.declineFriendRequest(requestId: request.id)
                // Remove from local list
                friendRequests.removeAll { $0.id == request.id }
            } catch {
                errorMessage = "Failed to decline request: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Friends Management
    
    @MainActor
    private func sendFriendRequest(to user: UserProfile) {
        Task {
            do {
                try await FriendsService.shared.sendFriendRequest(toUserId: user.id)
                // Remove from search results after sending request
                searchResults.removeAll { $0.id == user.id }
            } catch {
                errorMessage = "Failed to send friend request: \(error.localizedDescription)"
                print("Failed to send friend request to user \(user.id): \(error)")
            }
        }
    }
    
    @MainActor
    private func removeFriend(_ friend: FriendWithDetails) {
        friendToRemove = friend
        showRemoveConfirmation = true
    }
    
    @MainActor
    private func confirmRemoveFriend(_ friend: FriendWithDetails) async {
        do {
            try await FriendsService.shared.removeFriend(userId: friend.userId)
            // Remove from local list
            friends.removeAll { $0.id == friend.id }
            friendToRemove = nil
        } catch {
            errorMessage = "Failed to remove friend: \(error.localizedDescription)"
            print("Failed to remove friend \(friend.userId): \(error)")
        }
    }
}

// MARK: - Friend Request Row Component
private struct FriendRequestRow: View {
    let request: FriendRequestWithDetails
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    private var timeAgo: String {
        guard let date = request.createdAt else {
            return "Unknown"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title3)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("@\(request.userName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if request.activitiesCount > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("\(request.activitiesCount) activities")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button("Accept") {
                        onAccept()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Decline") {
                        onDecline()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Friend Row Component
private struct FriendRow: View {
    let friend: FriendWithDetails
    let onRemove: () -> Void
    
    private var friendSince: String {
        guard let since = friend.since else {
            return "Unknown"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Friends since " + formatter.localizedString(for: since, relativeTo: Date())
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.username)
                    .font(.headline)
                Text(friendSince)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "person.fill.xmark")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(friend.username)")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Search Row Component
private struct UserSearchRow: View {
    let user: UserProfile
    let onAdd: () -> Void
    @State private var requestSent = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text("@\(user.userName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let count = user.activitiesCount {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(count) activities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if requestSent {
                Text("Request Sent")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
            } else {
                Button {
                    requestSent = true
                    onAdd()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                        Text("Add")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ManageFriendsView()
}
