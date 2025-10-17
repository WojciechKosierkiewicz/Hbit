//
//  ActivityTab.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 17/10/2025.
//

import SwiftUI

struct SampleActivity {
    let title: String
    let date: Date
    let steps: Int
    let goal: Int
    
    var progress: Double {
        min(Double(steps) / Double(goal), 1.0)
    }
}

struct ActivityRow: View {
    let activity: SampleActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                VStack(alignment: .leading) {
                    Text(activity.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(activity.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(activity.steps) steps")
                        .fontWeight(.semibold)
                    Text("Goal: \(activity.goal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            ProgressView(value: activity.progress)
                .accentColor(.green)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
