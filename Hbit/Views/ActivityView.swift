//
//  ActivityView.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 05/10/2025.
//

import SwiftUI

public struct ActivityView: View {
    @State
    private var showAccount = false

    private var sampleActivity = SampleActivity(
        title: "Morning Walk",
        date: Date(),
        steps: 7420,
        goal: 10000
    )
    
    private var sampleActivity2 = SampleActivity(
        title: "Evening Walk",
        date: Date(),
        steps: 12000,
        goal: 10000
    )

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.6), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height:400)
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ActivityRow(activity: sampleActivity2)
                        ActivityRow(activity: sampleActivity)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("My Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAccount.toggle()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showAccount) {
            AccountView()
        }
    }
}
