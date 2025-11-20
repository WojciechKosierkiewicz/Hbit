//
//  AccountView.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 05/10/2025.
//

import SwiftUI

public struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthViewModel

    // Placeholder user data
    var userName: String = "John Doe"
    var email: String = "john@example.com"
    var stat1: String = "Level 12"
    var stat2: String = "2200 steps"
    var stat3: String = "7 races completed"

    public var body: some View {
        VStack(spacing: 24) {
            // Content
            VStack(spacing: 24) {
                // User picture
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)

                // User name and email
                Text(userName)
                    .font(.title)
                    .fontWeight(.bold)
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider().padding(.vertical, 8)

                // Placeholder stats
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text(stat1)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "figure.walk")
                        Text(stat2)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "flag.checkered")
                        Text(stat3)
                        Spacer()
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            // Logout button pinned at bottom
            Button(role: .destructive) {
                handleLogout()
            } label: {
                Text("Log Out")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.12))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .padding(.top)
        .ignoresSafeArea(.keyboard) // keep button visible when keyboard appears
    }

    private func handleLogout() {
        auth.logout(clearSavedCredentials: true)
        dismiss()
    }
}
