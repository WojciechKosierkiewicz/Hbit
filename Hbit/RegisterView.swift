import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var userName: String = ""
    @State private var email: String = ""
    @State private var name: String = ""
    @State private var surname: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var password: String = ""

    // UI state
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    @State private var debugOutput: String = "" // Debug field

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    TextField("Username", text: $userName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    SecureField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }

                Section(header: Text("Profile")) {
                    TextField("Name", text: $name)
                    TextField("Surname", text: $surname)
                    // Date only (no time)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: [.date])
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }

                if !debugOutput.isEmpty {
                    Section(header: Text("Debug Output")) {
                        Text(debugOutput)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Register")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await submitRegistration() }
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("Create Account")
                        }
                    }
                    .disabled(!isValid || isGenerating)
                }
            }
        }
    }

    private var isValid: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !surname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func submitRegistration() async {
        errorMessage = nil
        isGenerating = true
        debugOutput = ""
        defer { isGenerating = false }

        do {
            // Normalize to date-only (00:00:00Z)
            let normalizedDOB = Calendar(identifier: .gregorian).date(
                from: Calendar.current.dateComponents([.year, .month, .day], from: dateOfBirth)
            ) ?? dateOfBirth

            let payload = RegistrationPayload(
                userName: userName,
                email: email,
                name: name,
                surname: surname,
                DateOfBirth: ISO8601DateFormatter.iso8601Z.string(from: normalizedDOB),
                Password: password
            )

            // Build request
            let url = ApiConfig.baseURL.appendingPathComponent("Users")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let token = AuthService.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            // Encode body
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(payload)

            // Perform request
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw RegistrationError.badResponse(status: -1, body: "No HTTP response")
            }
            guard (200...299).contains(http.statusCode) else {
                let responseBody = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode == 401 { throw RegistrationError.unauthorized }
                throw RegistrationError.badResponse(status: http.statusCode, body: responseBody)
            }

            // Decode {"id": 3}
            _ = try JSONDecoder().decode(CreateUserResponse.self, from: data)

            // Compose and show the attempted login request details
            await logLoginAttempt(username: userName, password: password)

            // Attempt login
            do {
                try await AuthService.shared.login(username: userName, password: password)
                debugOutput.append("\nLogin result: success.\n")
                dismiss()
            } catch {
                let message: String
                if let authError = error as? AuthService.AuthError,
                   let desc = authError.errorDescription {
                    message = desc
                } else {
                    message = error.localizedDescription
                }
                debugOutput.append("\nLogin result: failed - \(message)\n")
                self.errorMessage = "Registered, but login failed: \(message)"
            }

        } catch {
            if let e = error as? LocalizedError, let msg = e.errorDescription {
                errorMessage = msg
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    // Logs what the login request would look like based on AuthService.login implementation.
    private func logLoginAttempt(username: String, password: String) async {
        // AuthService.authURL is internal, so we reconstruct the same info for display.
        // From AuthService.swift, the URL is:
        // private let authURL = URL(string: "http://192.168.1.18:5000/auth/login")!
        // To avoid tight coupling, we’ll show the known path and body.
        let loginURLString = "http://192.168.1.18:5000/auth/login" // mirror of AuthService.authURL
        let credentials = ["username": username, "password": password]

        let bodyData: Data
        do {
            bodyData = try JSONEncoder().encode(credentials)
        } catch {
            debugOutput = "Login Request:\nURL: \(loginURLString)\nHeaders: {\"Content-Type\": \"application/json\"}\nBody: <encoding error: \(error.localizedDescription)>\n"
            return
        }

        let bodyString = String(data: bodyData, encoding: .utf8) ?? "<unprintable>"

        debugOutput = """
        Login Request:
        URL: \(loginURLString)
        Headers: {"Content-Type": "application/json"}
        Body: \(bodyString)
        """
    }
}

// Exact-key payload as requested
private struct RegistrationPayload: Encodable {
    let userName: String
    let email: String
    let name: String
    let surname: String
    let DateOfBirth: String
    let Password: String
}

private struct CreateUserResponse: Decodable {
    let id: Int
}

private enum RegistrationError: LocalizedError {
    case badResponse(status: Int, body: String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .badResponse(let status, let body):
            return "Registration failed (HTTP \(status)): \(body)"
        case .unauthorized:
            return "Not authorized."
        }
    }
}

// ISO8601 formatter producing "YYYY-MM-DDTHH:mm:ssZ"
private extension ISO8601DateFormatter {
    static let iso8601Z: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}
