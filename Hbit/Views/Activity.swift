import Foundation

struct Activity: Identifiable, Codable {
    let id: Int
    let name: String
    let date: Date
    let type: String
    let userId: Int
    let user: User?
    let heartRateSamples: [HeartRateSample]

    struct User: Codable {
        // Update fields as needed
        let id: Int?
        let name: String?
    }

    struct HeartRateSample: Codable {
        // Update fields as needed
        let value: Int?
        let timestamp: Date?
    }
}
