//
//  RacesView.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 05/10/2025.
//

import SwiftUI

public struct RacesView: View {
    @State private var showAddRace = false

    private var sampleRace: Race {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.MM.yyyy"
        let startDate = formatter.date(from: "2.04.2025") ?? Date()
        let endDate = formatter.date(from: "3.11.2025") ?? Date()
        return Race(name: "Pwr marathon training", start: startDate, end: endDate, yourPostion: 1)
    }
    
    private var sampleRace2: Race {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.MM.yyyy"
        let startDate = formatter.date(from: "2.10.2025") ?? Date()
        let endDate = formatter.date(from: "14.11.2025") ?? Date()
        return Race(name: "Gym with friends", start: startDate, end: endDate, yourPostion: 2)
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
                        RaceTab(race: sampleRace2)
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
                        showAddRace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddRace) {
                AddRaceView()
            }
        }
    }
}

struct AddRaceView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var targetValue = ""
    @State private var activityGoalRange = "Monthly"
    @State private var acceptedActivityTypes = ""
    @State private var startsAt = Date()
    @State private var endsAt = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    let activityGoalRanges = ["Weekly", "Monthly", "Yearly"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Race Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Target Value", text: $targetValue)
                        .keyboardType(.numberPad)
                    Picker("Activity Goal Range", selection: $activityGoalRange) {
                        ForEach(activityGoalRanges, id: \.self) { range in
                            Text(range)
                        }
                    }
                    TextField("Accepted Activity Types (comma separated)", text: $acceptedActivityTypes)
                    DatePicker("Start Date", selection: $startsAt, displayedComponents: .date)
                    DatePicker("End Date", selection: $endsAt, displayedComponents: .date)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                if let successMessage = successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Add Race")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Submitting..." : "Create") {
                        Task { await submitRace() }
                    }
                    .disabled(isSubmitting || !formIsValid)
                }
            }
        }
    }

    private var formIsValid: Bool {
        !name.isEmpty &&
        !description.isEmpty &&
        !targetValue.isEmpty &&
        Int(targetValue) != nil &&
        !acceptedActivityTypes.isEmpty
    }

    private func submitRace() async {
        isSubmitting = true
        errorMessage = nil
        successMessage = nil

        guard let targetValueInt = Int(targetValue) else {
            errorMessage = "Target Value must be a number."
            isSubmitting = false
            return
        }

        let raceJSON: [String: Any] = [
            "Name": name,
            "Description": description,
            "TargetValue": targetValueInt,
            "ActivityGoalRange": activityGoalRange,
            "AcceptedActivityTypes": acceptedActivityTypes
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            "StartsAt": iso8601String(from: startsAt),
            "EndsAt": iso8601String(from: endsAt)
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: raceJSON, options: [])
            // Replace with your real endpoint
            let url = URL(string: "https://your.api/races")!

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data

            // If you want to add authorization:
            // request.setValue("Bearer \(yourToken)", forHTTPHeaderField: "Authorization")

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                successMessage = "Race created successfully!"
                // Optionally, dismiss or trigger a refresh
                await MainActor.run {
                    dismiss()
                }
            } else {
                errorMessage = "Failed to create race. Please try again."
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }

        isSubmitting = false
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
