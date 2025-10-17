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
        // Attach this to the TabView so the tab bar becomes transparent
        .toolbarBackground(.hidden, for: .tabBar)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

