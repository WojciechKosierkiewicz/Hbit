import SwiftUI
import Charts

struct ActivityDetailView: View {
    let activity: Activity

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var samples: [HeartRatePoint] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Score / summary
                scoreSection

                // Chart
                chartSection
            }
            .padding()
        }
        .navigationTitle(activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHeartRate()
        }
    }

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wynik treningu")
                .font(.headline)

            // Placeholder scoring: average HR and duration (based on samples)
            if samples.isEmpty {
                if isLoading {
                    ProgressView()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                } else {
                    Text("Brak danych o tętnie.")
                        .foregroundColor(.secondary)
                }
            } else {
                let avg = Int(samples.map(\.value).reduce(0, +) / max(samples.count, 1))
                let minVal = samples.map(\.value).min() ?? 0
                let maxVal = samples.map(\.value).max() ?? 0
                let score = computeScore(avgHR: avg, minHR: minVal, maxHR: maxVal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Średnie tętno: \(avg) bpm")
                    Text("Min: \(minVal) bpm, Max: \(maxVal) bpm")
                    Text("Punktacja: \(score)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wykres tętna")
                .font(.headline)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            } else if samples.isEmpty {
                Text("Brak próbek tętna do wyświetlenia.")
                    .foregroundColor(.secondary)
            } else {
                Chart(samples) { point in
                    LineMark(
                        x: .value("Czas", point.time),
                        y: .value("Tętno", point.value)
                    )
                    .foregroundStyle(.red)
                    .interpolationMethod(.monotone)
                }
                .chartYScale(domain: yDomain)
                .frame(height: 240)
            }
        }
    }

    private var yDomain: ClosedRange<Double> {
        let minV = Double(samples.map(\.value).min() ?? 60)
        let maxV = Double(samples.map(\.value).max() ?? 180)
        // Add a small margin
        let lower = max(0, minV - 5)
        let upper = maxV + 5
        return lower...upper
    }

    private func computeScore(avgHR: Int, minHR: Int, maxHR: Int) -> Int {
        // Placeholder scoring formula; adjust to your needs.
        // Example: emphasize average and peak:
        let score = Double(avgHR) * 0.6 + Double(maxHR) * 0.3 + Double(minHR) * 0.1
        return Int(score.rounded())
    }

    @MainActor
    private func loadHeartRate() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            samples = try await HeartRateService.shared.fetchHeartRateSeries(forActivityId: activity.id)
        } catch {
            if let e = error as? LocalizedError, let msg = e.errorDescription {
                errorMessage = msg
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Model for chart points

struct HeartRatePoint: Identifiable, Hashable {
    let id = UUID()
    let time: Date
    let value: Int
}
