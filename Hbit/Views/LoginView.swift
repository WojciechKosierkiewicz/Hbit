import SwiftUI
import Security

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Sign In")
                .font(.largeTitle)
                .bold()

            TextField("Username", text: $username)
                .textContentType(.username)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: {
                Task {
                    await login()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Login")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading || username.isEmpty || password.isEmpty)

            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                await tryAutoLogin()
            }
        }
    }

    @MainActor
    private func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.login(username: username, password: password)
            isLoggedIn = true
            KeychainHelper.saveCredentials(username: username, password: password)
        } catch {
            if let authError = error as? AuthService.AuthError {
                errorMessage = authError.localizedDescription
            } else {
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    private func tryAutoLogin() async {
        guard let credentials = KeychainHelper.loadCredentials() else { return }
        username = credentials.username
        password = credentials.password
        await login()
    }
}

// MARK: - Keychain Helper
private struct KeychainHelper {
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
}
