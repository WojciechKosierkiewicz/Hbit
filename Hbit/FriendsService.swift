import Foundation

// MARK: - Friend Request Model
struct FriendRequest: Identifiable, Codable {
    let id: Int
    let fromUserId: Int
    let toUserId: Int
    let createdAt: String
    let status: String
    
    var formattedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
}

// MARK: - Friend Request with User Details (for display)
struct FriendRequestWithDetails: Identifiable {
    let id: Int
    let fromUserId: Int
    let toUserId: Int
    let createdAt: Date?
    let status: String
    let fromUserProfile: UserProfile?
    
    var displayName: String {
        fromUserProfile?.displayName ?? "User \(fromUserId)"
    }
    
    var userName: String {
        fromUserProfile?.userName ?? "unknown"
    }
    
    var activitiesCount: Int {
        fromUserProfile?.activitiesCount ?? 0
    }
}

// MARK: - Friend Model
struct Friend: Identifiable, Codable {
    let userId: Int
    let since: String
    
    var id: Int { userId }
    
    var formattedSince: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: since)
    }
}

// MARK: - Friend with User Details (for display)
struct FriendWithDetails: Identifiable {
    let userId: Int
    let username: String
    let since: Date?
    
    var id: Int { userId }
}

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable {
    let id: Int
    let userName: String
    let email: String?
    let name: String?
    let surname: String?
    let activitiesCount: Int?
    
    // Computed property for convenience
    var displayName: String {
        if let name = name, let surname = surname {
            return "\(name) \(surname)"
        }
        return userName
    }
}

// MARK: - Friend Activity Response (from API)
struct FriendActivityResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let date: Date
    let type: String
    let userId: Int
}

// MARK: - Friend Activity with User Details (for display)
struct FriendActivityWithDetails: Identifiable {
    let id: Int
    let name: String
    let date: Date
    let type: String
    let userId: Int
    let friendName: String
    let userName: String
}

// MARK: - Friends Service
final class FriendsService {
    static let shared = FriendsService()
    
    private init() {}
    
    enum FriendsError: LocalizedError {
        case noToken
        case invalidResponse
        case httpError(status: Int, message: String)
        case decodingError(Error)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .noToken:
                return "You must be logged in to access friend requests."
            case .invalidResponse:
                return "Invalid response from server."
            case .httpError(let status, let message):
                return "Server error (\(status)): \(message)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Fetch Friend Requests
    func fetchFriendRequests() async throws -> [FriendRequest] {
        guard let token = AuthService.shared.getToken() else {
            throw FriendsError.noToken
        }
        
        let url = ApiConfig.baseURL.appendingPathComponent("Friends/requests")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FriendsError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw FriendsError.httpError(status: httpResponse.statusCode, message: message)
            }
            
            let decoder = JSONDecoder()
            let requests = try decoder.decode([FriendRequest].self, from: data)
            return requests
            
        } catch let error as FriendsError {
            throw error
        } catch let error as DecodingError {
            throw FriendsError.decodingError(error)
        } catch {
            throw FriendsError.networkError(error)
        }
    }
    
    // MARK: - Fetch Friend Requests with User Details
    func fetchFriendRequestsWithDetails() async throws -> [FriendRequestWithDetails] {
        let requests = try await fetchFriendRequests()
        
        // Fetch user profiles concurrently for all requests
        let requestsWithDetails = try await withThrowingTaskGroup(of: FriendRequestWithDetails?.self) { group in
            for request in requests {
                group.addTask {
                    do {
                        let profile = try await self.fetchUserProfile(userId: request.fromUserId)
                        return FriendRequestWithDetails(
                            id: request.id,
                            fromUserId: request.fromUserId,
                            toUserId: request.toUserId,
                            createdAt: request.formattedDate,
                            status: request.status,
                            fromUserProfile: profile
                        )
                    } catch {
                        // If we can't fetch the profile, return request without profile
                        print("Failed to fetch profile for request from user \(request.fromUserId): \(error)")
                        return FriendRequestWithDetails(
                            id: request.id,
                            fromUserId: request.fromUserId,
                            toUserId: request.toUserId,
                            createdAt: request.formattedDate,
                            status: request.status,
                            fromUserProfile: nil
                        )
                    }
                }
            }
            
            var results: [FriendRequestWithDetails] = []
            for try await requestDetail in group {
                if let requestDetail = requestDetail {
                    results.append(requestDetail)
                }
            }
            return results
        }
        
        return requestsWithDetails
    }
    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(requestId: Int) async throws {
        guard let token = AuthService.shared.getToken() else {
            throw FriendsError.noToken
        }
        
        let url = ApiConfig.baseURL.appendingPathComponent("Friends/requests/\(requestId)/accept")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FriendsError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw FriendsError.httpError(status: httpResponse.statusCode, message: message)
        }
    }
    
    // MARK: - Decline Friend Request
    func declineFriendRequest(requestId: Int) async throws {
        guard let token = AuthService.shared.getToken() else {
            throw FriendsError.noToken
        }
        
        let url = ApiConfig.baseURL.appendingPathComponent("Friends/requests/\(requestId)/decline")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FriendsError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw FriendsError.httpError(status: httpResponse.statusCode, message: message)
        }
    }
    
    // MARK: - Fetch Friends List
    func fetchFriends() async throws -> [Friend] {
        guard let token = AuthService.shared.getToken() else {
            throw FriendsError.noToken
        }
        
        let url = ApiConfig.baseURL.appendingPathComponent("Friends")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FriendsError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw FriendsError.httpError(status: httpResponse.statusCode, message: message)
            }
            
            let decoder = JSONDecoder()
            let friends = try decoder.decode([Friend].self, from: data)
            return friends
            
        } catch let error as FriendsError {
            throw error
        } catch let error as DecodingError {
            throw FriendsError.decodingError(error)
        } catch {
            throw FriendsError.networkError(error)
        }
    }
    
    // MARK: - Fetch User Profile by ID
    func fetchUserProfile(userId: Int) async throws -> UserProfile {
        guard let token = AuthService.shared.getToken() else {
            throw FriendsError.noToken
        }
        
        let url = ApiConfig.baseURL.appendingPathComponent("users/\(userId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FriendsError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw FriendsError.httpError(status: httpResponse.statusCode, message: message)
            }
            
            let decoder = JSONDecoder()
            let profile = try decoder.decode(UserProfile.self, from: data)
            return profile
            
        } catch let error as FriendsError {
            throw error
        } catch let error as DecodingError {
            throw FriendsError.decodingError(error)
        } catch {
            throw FriendsError.networkError(error)
        }
    }
    
    // MARK: - Fetch Friends with User Details
    func fetchFriendsWithDetails() async throws -> [FriendWithDetails] {
        let friends = try await fetchFriends()
        
        // Fetch user profiles concurrently for all friends
        let friendsWithDetails = try await withThrowingTaskGroup(of: FriendWithDetails?.self) { group in
            for friend in friends {
                group.addTask {
                    do {
                        let profile = try await self.fetchUserProfile(userId: friend.userId)
                        return FriendWithDetails(
                            userId: friend.userId,
                            username: profile.displayName,
                            since: friend.formattedSince
                        )
                    } catch {
                        // If we can't fetch the profile, return nil
                        print("Failed to fetch profile for user \(friend.userId): \(error)")
                        return nil
                    }
                }
            }
            
            var results: [FriendWithDetails] = []
            for try await friendDetail in group {
                if let friendDetail = friendDetail {
                    results.append(friendDetail)
                }
            }
            return results
        }
        
        return friendsWithDetails
    }
    
    // MARK: - Search Users
    func searchUsers(query: String) async throws -> [UserProfile] {
        guard let token = AuthService.shared.getToken() else {
            throw FriendsError.noToken
        }
        
        guard !query.isEmpty else {
            return []
        }
        
        var urlComponents = URLComponents(url: ApiConfig.baseURL.appendingPathComponent("Users"), resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [URLQueryItem(name: "q", value: query)]
        
        guard let url = urlComponents?.url else {
            throw FriendsError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FriendsError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw FriendsError.httpError(status: httpResponse.statusCode, message: message)
            }
            
            let decoder = JSONDecoder()
            let users = try decoder.decode([UserProfile].self, from: data)
            return users
            
        } catch let error as FriendsError {
            throw error
        } catch let error as DecodingError {
            throw FriendsError.decodingError(error)
        } catch {
            throw FriendsError.networkError(error)
        }
    }
    
    // MARK: - Send Friend Request
    func sendFriendRequest(toUserId: Int) async throws {
        guard let token = AuthService.shared.getToken() else {
            throw FriendsError.noToken
        }
        
        let url = ApiConfig.baseURL.appendingPathComponent("Friends/requests")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["toUserId": toUserId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FriendsError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw FriendsError.httpError(status: httpResponse.statusCode, message: message)
        }
    }
    
    // MARK: - Remove Friend
    func removeFriend(userId: Int) async throws {
        guard let token = AuthService.shared.getToken() else {
            throw FriendsError.noToken
        }
        
        let url = ApiConfig.baseURL.appendingPathComponent("Friends/\(userId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FriendsError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw FriendsError.httpError(status: httpResponse.statusCode, message: message)
            }
            
        } catch let error as FriendsError {
            throw error
        } catch {
            throw FriendsError.networkError(error)
        }
    }
    
    // MARK: - Fetch Friend Activities
    func fetchFriendActivities() async throws -> [FriendActivityResponse] {
        guard let token = AuthService.shared.getToken() else {
            throw FriendsError.noToken
        }
        
        let url = ApiConfig.baseURL.appendingPathComponent("Activity/friends")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FriendsError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw FriendsError.httpError(status: httpResponse.statusCode, message: message)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let activities = try decoder.decode([FriendActivityResponse].self, from: data)
            return activities
            
        } catch let error as FriendsError {
            throw error
        } catch let error as DecodingError {
            throw FriendsError.decodingError(error)
        } catch {
            throw FriendsError.networkError(error)
        }
    }
    
    // MARK: - Fetch Friend Activities with User Details
    func fetchFriendActivitiesWithDetails() async throws -> [FriendActivityWithDetails] {
        let activities = try await fetchFriendActivities()
        
        // Group activities by userId to minimize API calls
        let userIds = Set(activities.map { $0.userId })
        
        // Fetch all user profiles concurrently
        var userProfiles: [Int: UserProfile] = [:]
        try await withThrowingTaskGroup(of: (Int, UserProfile).self) { group in
            for userId in userIds {
                group.addTask {
                    let profile = try await self.fetchUserProfile(userId: userId)
                    return (userId, profile)
                }
            }
            
            for try await (userId, profile) in group {
                userProfiles[userId] = profile
            }
        }
        
        // Map activities to include user details
        return activities.map { activity in
            let profile = userProfiles[activity.userId]
            return FriendActivityWithDetails(
                id: activity.id,
                name: activity.name,
                date: activity.date,
                type: activity.type,
                userId: activity.userId,
                friendName: profile?.displayName ?? "User \(activity.userId)",
                userName: profile?.userName ?? "unknown"
            )
        }
    }
}
