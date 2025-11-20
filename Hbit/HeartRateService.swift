import Foundation

struct HeartRateZones: Decodable, Equatable {
    let restingHeartRate: Int
    let maxHeartRate: Int
    let zone1LowerLimit: Int
    let zone2LowerLimit: Int
    let zone3LowerLimit: Int
    let zone4LowerLimit: Int
    let zone5LowerLimit: Int
}

final class HeartRateService {
    static let shared = HeartRateService()
    private init() {}

    enum HRServiceError: LocalizedError {
        case badResponse(status: Int, body: String)
        case decoding
        case unauthorized
        case transport(Error)

        var errorDescription: String? {
            switch self {
            case .badResponse(let status, let body):
                return "Pobieranie tętna nie powiodło się (HTTP \(status)): \(body)"
            case .decoding:
                return "Nie udało się zdekodować danych tętna."
            case .unauthorized:
                return "Brak autoryzacji."
            case .transport(let error):
                return "Błąd sieci: \(error.localizedDescription)"
            }
        }
    }

    // Adjust the path once you share the endpoint (e.g., "Activity/{id}/HeartRate")
    func fetchHeartRateSeries(forActivityId id: Int) async throws -> [HeartRatePoint] {
        let url = ApiConfig.baseURL
            .appendingPathComponent("HeartRate")
            .appendingPathComponent(String(id))

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw HRServiceError.badResponse(status: -1, body: "No HTTP response")
            }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode == 401 { throw HRServiceError.unauthorized }
                throw HRServiceError.badResponse(status: http.statusCode, body: body)
            }

            // Oczekiwany JSON: [{ "time": "2025-11-17T12:00:00Z", "value": 90 }, ...]
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let raw = try decoder.decode([RawHeartRatePoint].self, from: data)
            return raw.map { HeartRatePoint(time: $0.time, value: $0.value) }
        } catch let e as HRServiceError {
            throw e
        } catch let e as DecodingError {
            throw HRServiceError.decoding
        } catch {
            throw HRServiceError.transport(error)
        }
    }

    // New: fetch heart rate zones
    func fetchZones() async throws -> HeartRateZones {
        let url = ApiConfig.baseURL
            .appendingPathComponent("HeartRate")
            .appendingPathComponent("zones")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw HRServiceError.badResponse(status: -1, body: "No HTTP response")
            }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode == 401 { throw HRServiceError.unauthorized }
                throw HRServiceError.badResponse(status: http.statusCode, body: body)
            }
            return try JSONDecoder().decode(HeartRateZones.self, from: data)
        } catch let e as HRServiceError {
            throw e
        } catch let e as DecodingError {
            throw HRServiceError.decoding
        } catch {
            throw HRServiceError.transport(error)
        }
    }

    // New: time spent per zone for a specific activity
    func fetchZoneTimeSpent(forActivityId id: Int) async throws -> ZoneTimeSpentResponse {
        let url = ApiConfig.baseURL
            .appendingPathComponent("HeartRate")
            .appendingPathComponent(String(id))
            .appendingPathComponent("zones")
            .appendingPathComponent("timespent")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw HRServiceError.badResponse(status: -1, body: "No HTTP response")
            }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode == 401 { throw HRServiceError.unauthorized }
                throw HRServiceError.badResponse(status: http.statusCode, body: body)
            }
            return try JSONDecoder().decode(ZoneTimeSpentResponse.self, from: data)
        } catch let e as HRServiceError {
            throw e
        } catch let e as DecodingError {
            throw HRServiceError.decoding
        } catch {
            throw HRServiceError.transport(error)
        }
    }

    private struct RawHeartRatePoint: Decodable {
        let time: Date
        let value: Int
    }
}

// MARK: - New models for time spent per zone

struct ZoneTimeSpentResponse: Decodable, Equatable {
    let maxHeartRate: Int
    let zones: [ZoneTimeSpentItem]
}

struct ZoneTimeSpentItem: Decodable, Equatable, Identifiable {
    var id: String { zone }
    let zone: String     // e.g., "Z1"
    let seconds: Int     // total seconds
    let duration: String // e.g., "00:20:00"
}
