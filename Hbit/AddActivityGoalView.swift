import SwiftUI

struct AddActivityGoalView: View {
    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var name: String = ""
    @State private var descriptionText: String = ""
    @State private var targetValue: Int = 1
    @State private var range: String = "Monthly"
    @State private var acceptedTypes: Set<String> = ["Running"]
    @State private var startsAt: Date = Date()
    @State private var endsAt: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    // UI state
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // Callback to refresh parent on success
    let onCreated: (() -> Void)?

    // Allowed values (adjust as needed)
    private let ranges = ["Daily", "Weekly", "Monthly"]
    private let activityTypes = ["Running", "Walking", "Cycling", "Hiking", "Swimming"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section(header: Text("Target")) {
                    Stepper(value: $targetValue, in: 1...1000) {
                        HStack {
                            Text("Target Value")
                            Spacer()
                            Text("\(targetValue)")
                                .foregroundColor(.secondary)
                        }
                    }
                    Picker("Range", selection: $range) {
                        ForEach(ranges, id: \.self) { r in
                            Text(r).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Accepted Activity Types")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(activityTypes, id: \.self) { type in
                                Toggle(isOn: Binding(
                                    get: { acceptedTypes.contains(type) },
                                    set: { newValue in
                                        if newValue { acceptedTypes.insert(type) }
                                        else { acceptedTypes.remove(type) }
                                    }
                                )) {
                                    Text(type)
                                        .font(.subheadline)
                                }
                                .toggleStyle(.button)
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Schedule")) {
                    DatePicker("Starts At", selection: $startsAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Ends At", selection: $endsAt, in: startsAt..., displayedComponents: [.date, .hourAndMinute])
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("New Activity Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await submit() }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        targetValue > 0 &&
        endsAt > startsAt &&
        !acceptedTypes.isEmpty
    }

    @MainActor
    private func submit() async {
        guard isValid else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await createActivityGoal()
            onCreated?()
            dismiss()
        } catch {
            if let e = error as? LocalizedError, let msg = e.errorDescription {
                errorMessage = msg
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func createActivityGoal() async throws {
        // Build payload with PascalCase keys as required by backend
        let payload = ActivityGoalCreatePayload(
            Name: name,
            Description: descriptionText,
            TargetValue: targetValue,
            ActivityGoalRange: range,
            AcceptedActivityTypes: Array(acceptedTypes),
            StartsAt: iso8601Z(startsAt),
            EndsAt: iso8601Z(endsAt)
        )

        let url = ApiConfig.baseURL.appendingPathComponent("ActivityGoal")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body
        let encoder = JSONEncoder()
        let body = try encoder.encode(payload)
        request.httpBody = body

        // Pretty-print for console
        let prettyEncoder = JSONEncoder()
        prettyEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let prettyBody = try prettyEncoder.encode(payload)
        if let bodyString = String(data: prettyBody, encoding: .utf8) {
            print("=== ActivityGoal CREATE REQUEST ===")
            print("URL: \(url.absoluteString)")
            var headersLogged: [String: String] = ["Content-Type": "application/json"]
            if let token = AuthService.shared.getToken() {
                headersLogged["Authorization"] = "Bearer \(token.prefix(8))…"
            }
            print("Headers: \(headersLogged)")
            print("Body:\n\(bodyString)")
            print("===================================")
        }

        // Perform request
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ActivityGoalServiceError.badResponse(status: -1, body: "No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            if http.statusCode == 401 { throw ActivityGoalServiceError.unauthorized }
            throw ActivityGoalServiceError.badResponse(status: http.statusCode, body: responseBody)
        }
    }

    private func iso8601Z(_ date: Date) -> String {
        ISO8601DateFormatter.iso8601Z.string(from: date)
    }
}

// Payload using PascalCase keys
private struct ActivityGoalCreatePayload: Encodable {
    let Name: String
    let Description: String
    let TargetValue: Int
    let ActivityGoalRange: String
    let AcceptedActivityTypes: [String]
    let StartsAt: String
    let EndsAt: String
}

// ISO8601 formatter helper
private extension ISO8601DateFormatter {
    static let iso8601Z: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        // Produces "2025-02-01T00:00:00Z" (no fractional seconds).
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
