//
//  RaceView.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 05/10/2025.
//

import SwiftUI

public struct RaceTab: View {
    var race: Race

    public var body: some View {
        VStack(){
            HStack(spacing: 14) {
                Image(systemName: "figure.run.treadmill")
                Text(race.name)
                    .font(.headline)
                    .fontWeight(.bold)
                VStack(alignment: .leading) {
                    Text(race.timeLeft())
                }
                Spacer()
            }
            HStack(alignment: .bottom){
                switch race.yourPosition {
                case 1:    Text("You are 1st ! 🎉").foregroundColor(.yellow).fontWeight(.bold)
                case 2:    Text("You are 2nd !").foregroundColor(.green)
                case 3:    Text("You are 3rd !").foregroundColor(.green)
                default:
                    Text(String(format: "You are %dth", race.yourPosition))
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
