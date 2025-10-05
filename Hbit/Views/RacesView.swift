//
//  RacesView.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 05/10/2025.
//

import SwiftUI

public struct RacesView: View {
    private var sampleRace: Race {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.MM.yyyy"
        let startDate = formatter.date(from: "2.04.2025") ?? Date()
        let endDate = formatter.date(from: "3.11.2025") ?? Date()
        return Race(name: "charlie eho", start: startDate, end: endDate, yourPostion: 1)
    }

    public var body: some View {
        NavigationStack {
            ZStack (alignment: .top){
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height:400)
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        RaceTab(race: sampleRace)
                        RaceTab(race: sampleRace)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Active Races")
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
            // Make the navigation bar transparent so the gradient shows under it
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
