import Foundation

enum ActivityGoalServiceError: LocalizedError {
    case badResponse(status: Int, body: String)
    case decoding
    case unauthorized
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .badResponse(let status, let body):
            return "Fetch failed (HTTP \(status)): \(body)"
        case .decoding:
            return "Failed to decode activity goals."
        case .unauthorized:
            return "Not authorized."
        case .transport(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

final class ActivityGoalService {
    static let shared = ActivityGoalService()
    private init() {}

    func fetchAll() async throws -> [ActivityGoal] {
        let url = ApiConfig.baseURL.appendingPathComponent("ActivityGoal")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw ActivityGoalServiceError.badResponse(status: -1, body: "No HTTP response")
            }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode == 401 { throw ActivityGoalServiceError.unauthorized }
                throw ActivityGoalServiceError.badResponse(status: http.statusCode, body: body)
            }
            do {
                return try ActivityGoal.decoder.decode([ActivityGoal].self, from: data)
            } catch {
                throw ActivityGoalServiceError.decoding
            }
        } catch {
            throw ActivityGoalServiceError.transport(error)
        }
    }
}
