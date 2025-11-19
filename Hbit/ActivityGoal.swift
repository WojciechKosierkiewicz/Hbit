import Foundation

struct ActivityGoal: Identifiable, Decodable {
    let id: Int
    let name: String
    let description: String
    let targetValue: Int
    let range: String
    let acceptedActivityTypes: [String]
    let startsAt: Date
    let endsAt: Date

    // Custom decoder to handle ISO8601 with timezone offsets
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

extension ActivityGoal {
    // Helper similar to Race.timeLeft()
    func timeLeftString(from now: Date = Date()) -> String {
        let secondsLeft = endsAt.timeIntervalSince(now)
        if secondsLeft <= 0 {
            return "Finished"
        }
        let minutes = Int(ceil(secondsLeft / 60.0))
        if minutes / 60 > 24 {
            return "\(minutes / 60 / 24) days left"
        }
        if minutes < 120 {
            return "\(minutes) minutes left"
        }
        return "\(minutes / 60) hours left"
    }
}
