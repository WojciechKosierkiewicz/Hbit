import Foundation

final class ActivityService {
    static let shared = ActivityService()
    private let baseURL = URL(string: "http://192.168.1.18:5000/")! // Change as necessary

    private init() {}

    enum ActivityError: LocalizedError {
        case responseError(status: Int, message: String)
        case decodingError
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .responseError(let status, let message):
                return "Fetch failed (HTTP \(status)): \(message)"
            case .decodingError:
                return "Failed to decode activities."
            case .unknown(let error):
                return "Unexpected error: \(error.localizedDescription)"
            }
        }
    }

    func fetchAllActivities() async throws -> [Activity] {
        let url = baseURL.appendingPathComponent("Activity")
        let data: Data
        do {
            data = try await AuthService.shared.performAuthenticatedRequest(to: url)
        } catch {
            throw ActivityError.unknown(error)
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Activity].self, from: data)
        } catch {
            throw ActivityError.decodingError
        }
    }
}
