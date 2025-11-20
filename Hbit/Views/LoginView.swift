import SwiftUI
import Security

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var showRegister = false

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
                Task { await login() }
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

            Button {
                showRegister = true
            } label: {
                Text("Register")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            Task { await tryAutoLogin() }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(auth)
        }
    }

    @MainActor
    private func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        if let error = await auth.login(username: username, password: password) {
            errorMessage = error
        }
    }

    @MainActor
    private func tryAutoLogin() async {
        if let credentials = KeychainHelper.loadCredentials() {
            username = credentials.username
            password = credentials.password
            await login()
        }
    }
}
