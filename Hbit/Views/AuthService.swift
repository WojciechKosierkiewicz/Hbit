import Foundation
import Security

final class AuthService {
    static let shared = AuthService()
    private let tokenKey = "jwtToken"
    private let authURL = URL(string: "http://192.168.1.18:5000/auth/login")! // <-- Replace with your endpoint

    private init() { }

    enum AuthError: LocalizedError {
        case responseError(status: Int, message: String)
        case decodingError
        case storageError
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .responseError(let status, let message):
                return "Login failed (HTTP \(status)): \(message)"
            case .decodingError:
                return "Failed to decode server response."
            case .storageError:
                return "Failed to store authentication data."
            case .unknown(let error):
                return "Unexpected error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Login (Obtain JWT)
    func login(username: String, password: String) async throws {
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let credentials = ["username": username, "password": password]
        request.httpBody = try JSONEncoder().encode(credentials)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.responseError(status: -1, message: "No HTTP response")
            }
            guard httpResponse.statusCode == 200 else {
                let message = String(data: data, encoding: .utf8) ?? "No error message from server."
                throw AuthError.responseError(status: httpResponse.statusCode, message: message)
            }
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            try saveToken(loginResponse.accessToken)
        } catch let error as AuthError {
            throw error
        } catch let error as DecodingError {
            throw AuthError.decodingError
        } catch {
            throw AuthError.unknown(error)
        }
    }

    // MARK: - Logout
    func logout() {
        deleteToken()
    }

    // MARK: - Token Management
    private func saveToken(_ token: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw AuthError.storageError }
    }

    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    // MARK: - Authenticated Request Example
    func performAuthenticatedRequest(to url: URL) async throws -> Data {
        guard let token = getToken() else { throw URLError(.userAuthenticationRequired) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("No HTTP response received.")
            throw URLError(.badServerResponse)
        }
        if !(200...299).contains(httpResponse.statusCode) {
            // Print error details for debugging
            print("Request to \(url) failed.")
            print("HTTP Status: \(httpResponse.statusCode)")
            if let body = String(data: data, encoding: .utf8) {
                print("Response body: \(body)")
            } else {
                print("Response body could not be decoded as UTF-8 string.")
            }
            throw URLError(.badServerResponse)
        }
        return data
    }
}

// MARK: - LoginResponse Model
struct LoginResponse: Decodable {
    let accessToken: String
    let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}
