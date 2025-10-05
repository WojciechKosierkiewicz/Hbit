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
    @Query private var items: [Item]
    @State private var isAnimating: Bool = true

    var body: some View {
        TabView {
            Tab("Races", systemImage: "flag.pattern.checkered") {
                RacesView()
            }

            Tab("Activity", systemImage: "figure.run") {
                NavigationStack{
                    ZStack (alignment: .top){
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.6), Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height:400)
                        .ignoresSafeArea()
                    }
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                }
                .navigationTitle("My Activity")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            // Handle inbox action
                        } label: {
                            Image(systemName: "tray")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            // Handle account action
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    }
                }
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
