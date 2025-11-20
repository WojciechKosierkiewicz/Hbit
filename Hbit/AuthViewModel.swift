import Foundation
import Combine

final class AuthViewModel: ObservableObject {
    @Published private(set) var isLoggedIn: Bool

    init() {
        // Initialize from token presence
        self.isLoggedIn = (AuthService.shared.getToken() != nil)
    }

    @MainActor
    func login(username: String, password: String) async -> String? {
        do {
            try await AuthService.shared.login(username: username, password: password)
            // Optional: persist credentials for auto-login
            KeychainHelper.saveCredentials(username: username, password: password)
            isLoggedIn = true
            return nil
        } catch {
            if let e = error as? AuthService.AuthError {
                return e.localizedDescription
            } else {
                return error.localizedDescription
            }
        }
    }

    func logout(clearSavedCredentials: Bool = true) {
        AuthService.shared.logout()
        if clearSavedCredentials {
            KeychainHelper.clearCredentials()
        }
        isLoggedIn = false
    }
}

// Expose KeychainHelper so the VM can clear credentials
enum KeychainHelper {
    private static let service = "com.yourapp.login" // Change to your bundle ID

    static func saveCredentials(username: String, password: String) {
        save(key: "username", value: username)
        save(key: "password", value: password)
    }

    static func loadCredentials() -> (username: String, password: String)? {
        guard
            let username = load(key: "username"),
            let password = load(key: "password")
        else {
            return nil
        }
        return (username, password)
    }

    static func clearCredentials() {
        delete(key: "username")
        delete(key: "password")
    }

    // MARK: - Private

    private static func save(key: String, value: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: value.data(using: .utf8)!
        ]
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
