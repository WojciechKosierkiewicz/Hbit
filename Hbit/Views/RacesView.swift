//
//  RacesView.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 05/10/2025.
//

import SwiftUI

public struct RacesView: View {
    @State private var showAddRace = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var goals: [ActivityGoal] = []

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 400)
                .ignoresSafeArea()

                Group {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else if goals.isEmpty {
                        Text("No goals found.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(goals) { goal in
                                    ActivityGoalRow(goal: goal)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .navigationTitle("Activity Goals")
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
                        showAddRace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddRace) {
                AddActivityGoalView {
                    Task { await loadGoals() }
                }
            }
        }
        .task {
            await loadGoals()
        }
    }

    @MainActor
    private func loadGoals() async {
        isLoading = true
        errorMessage = nil
        do {
            goals = try await ActivityGoalService.shared.fetchAll()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
