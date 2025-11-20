//
//  HbitApp.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 22/09/2025.
//

import SwiftUI
import SwiftData

@main
struct HbitApp: App {
    @StateObject private var auth = AuthViewModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            // Race.self, // Removed legacy model
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
        }
        .modelContainer(sharedModelContainer)
    }
}
