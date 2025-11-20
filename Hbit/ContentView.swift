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

    var body: some View {
        TabView {
            Tab("Races", systemImage: "flag.pattern.checkered") {
                RacesView()
            }

            Tab("Activity", systemImage: "figure.run") {
                ActivityView()
            }
            Tab("Friends", systemImage: "person.3.fill") {
                Text("Activity")
            }
        }
        .tabViewStyle(.automatic)
        .tabBarMinimizeBehavior(.onScrollDown)
        .toolbarBackground(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: .constant(!auth.isLoggedIn)) {
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
