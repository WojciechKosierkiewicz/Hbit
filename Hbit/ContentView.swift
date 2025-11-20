//
//  ContentView.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 22/09/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var auth: AuthViewModel
    @State private var healthAuthStatus: String = "Requesting HealthKit access..."

    // Avoid presenting login or doing heavy work in previews
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var body: some View {
        TabView {
            Tab("Races", systemImage: "flag.pattern.checkered") {
                RacesView()
            }

            Tab("Activity", systemImage: "figure.run") {
                ActivityView()
            }
            Tab("Friends", systemImage: "person.3.fill") {
                FriendsView()
            }
        }
        .tabViewStyle(.automatic)
        .tabBarMinimizeBehavior(.onScrollDown)
        .toolbarBackground(.hidden, for: .tabBar)
        // Skip login cover in previews to avoid side effects/cancellations
        .fullScreenCover(isPresented: .constant(!auth.isLoggedIn && !isPreview)) {
            LoginView()
                .environmentObject(auth)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .modelContainer(for: Item.self, inMemory: true)
}
