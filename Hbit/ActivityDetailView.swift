import SwiftUI
import Charts

struct ActivityDetailView: View {
    let activity: Activity

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var samples: [HeartRatePoint] = []
    @State private var zones: HeartRateZones?
    @State private var zoneTimeSpent: ZoneTimeSpentResponse?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Score / summary
                scoreSection

                // Chart
                chartSection

                // Time spent per HR zone
                timeSpentSection
            }
            .padding()
        }
        .navigationTitle(activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wynik treningu")
                .font(.headline)

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
                    if let z = zones, !samples.isEmpty {
                        Text("Strefy (max \(z.maxHeartRate) bpm)")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
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
                Chart {
                    if let z = zones, let xStart = samples.first?.time, let xEnd = samples.last?.time {
                        // Bands only when they intersect yDomain, clamped to visible range
                        if intersectsDomain(lower: 0, upper: z.zone1LowerLimit) {
                            let lo = max(Double(0), yDomain.lowerBound)
                            let hi = min(Double(z.zone1LowerLimit), yDomain.upperBound)
                            zoneBandRect(xStart: xStart, xEnd: xEnd, from: Int(lo.rounded()), to: Int(hi.rounded()), color: .blue.opacity(0.06))
                        }
                        if intersectsDomain(lower: z.zone1LowerLimit, upper: z.zone2LowerLimit) {
                            let lo = max(Double(z.zone1LowerLimit), yDomain.lowerBound)
                            let hi = min(Double(z.zone2LowerLimit), yDomain.upperBound)
                            zoneBandRect(xStart: xStart, xEnd: xEnd, from: Int(lo.rounded()), to: Int(hi.rounded()), color: .green.opacity(0.06))
                        }
                        if intersectsDomain(lower: z.zone2LowerLimit, upper: z.zone3LowerLimit) {
                            let lo = max(Double(z.zone2LowerLimit), yDomain.lowerBound)
                            let hi = min(Double(z.zone3LowerLimit), yDomain.upperBound)
                            zoneBandRect(xStart: xStart, xEnd: xEnd, from: Int(lo.rounded()), to: Int(hi.rounded()), color: .yellow.opacity(0.08))
                        }
                        if intersectsDomain(lower: z.zone3LowerLimit, upper: z.zone4LowerLimit) {
                            let lo = max(Double(z.zone3LowerLimit), yDomain.lowerBound)
                            let hi = min(Double(z.zone4LowerLimit), yDomain.upperBound)
                            zoneBandRect(xStart: xStart, xEnd: xEnd, from: Int(lo.rounded()), to: Int(hi.rounded()), color: .orange.opacity(0.08))
                        }
                        if intersectsDomain(lower: z.zone4LowerLimit, upper: z.zone5LowerLimit) {
                            let lo = max(Double(z.zone4LowerLimit), yDomain.lowerBound)
                            let hi = min(Double(z.zone5LowerLimit), yDomain.upperBound)
                            zoneBandRect(xStart: xStart, xEnd: xEnd, from: Int(lo.rounded()), to: Int(hi.rounded()), color: .red.opacity(0.08))
                        }
                        if intersectsDomain(lower: z.zone5LowerLimit, upper: z.maxHeartRate) {
                            let lo = max(Double(z.zone5LowerLimit), yDomain.lowerBound)
                            let hi = min(Double(z.maxHeartRate), yDomain.upperBound)
                            zoneBandRect(xStart: xStart, xEnd: xEnd, from: Int(lo.rounded()), to: Int(hi.rounded()), color: .purple.opacity(0.08))
                        }

                        // Boundary rules with Zone 1..5 labels (and Max)
                        if yDomain.contains(Double(z.zone1LowerLimit)) { zoneRule(at: z.zone1LowerLimit, xStart: xStart, xEnd: xEnd, color: .green, label: "Zone 1") }
                        if yDomain.contains(Double(z.zone2LowerLimit)) { zoneRule(at: z.zone2LowerLimit, xStart: xStart, xEnd: xEnd, color: .yellow, label: "Zone 2") }
                        if yDomain.contains(Double(z.zone3LowerLimit)) { zoneRule(at: z.zone3LowerLimit, xStart: xStart, xEnd: xEnd, color: .orange, label: "Zone 3") }
                        if yDomain.contains(Double(z.zone4LowerLimit)) { zoneRule(at: z.zone4LowerLimit, xStart: xStart, xEnd: xEnd, color: .red, label: "Zone 4") }
                        if yDomain.contains(Double(z.zone5LowerLimit)) { zoneRule(at: z.zone5LowerLimit, xStart: xStart, xEnd: xEnd, color: .purple, label: "Zone 5") }
                        if yDomain.contains(Double(z.maxHeartRate))    { zoneRule(at: z.maxHeartRate, xStart: xStart, xEnd: xEnd, color: .gray, label: "Max") }
                    }

                    // HR series
                    ForEach(samples) { point in
                        LineMark(
                            x: .value("Czas", point.time),
                            y: .value("Tętno", point.value)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.monotone)
                    }
                }
                .chartYScale(domain: yDomain)
                .frame(height: 260)
            }
        }
    }

    private var timeSpentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Czas w strefach")
                .font(.headline)

            if isLoading && zoneTimeSpent == nil {
                ProgressView()
            } else if let errorMessage = errorMessage, zoneTimeSpent == nil {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            } else if let ts = zoneTimeSpent {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(ts.zones) { item in
                        let n = zoneNumber(from: item.zone)
                        HStack(spacing: 10) {
                            Circle()
                                .fill(zoneColor(for: n))
                                .frame(width: 10, height: 10)
                            Text("Zone \(n)")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(item.duration)
                                .monospacedDigit()
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
            } else {
                Text("Brak danych o czasie w strefach.")
                    .foregroundColor(.secondary)
            }
        }
    }

    // Trimmed Y-axis: start at the nearest relevant zone boundary below the lowest sample
    private var yDomain: ClosedRange<Double> {
        let dataMin = Double(samples.map(\.value).min() ?? 60)
        let dataMax = Double(samples.map(\.value).max() ?? 180)

        let zoneBounds: [Double] = {
            guard let z = zones else { return [] }
            return [Double(z.zone1LowerLimit),
                    Double(z.zone2LowerLimit),
                    Double(z.zone3LowerLimit),
                    Double(z.zone4LowerLimit),
                    Double(z.zone5LowerLimit),
                    Double(z.maxHeartRate)]
        }()

        let candidateLowers = ([0.0] + zoneBounds).filter { $0 <= dataMin }
        let snappedLower = candidateLowers.max() ?? dataMin

        let zonesMax = zoneBounds.max() ?? 0.0
        let maxV = max(dataMax, zonesMax)

        let lower = max(0.0, snappedLower - 3.0)
        let upper = maxV + 5.0
        return lower...upper
    }

    // Does a band [lower, upper] intersect the visible yDomain?
    private func intersectsDomain(lower: Int, upper: Int) -> Bool {
        let d = yDomain
        return Double(upper) >= d.lowerBound && Double(lower) <= d.upperBound && upper > lower
    }

    private func computeScore(avgHR: Int, minHR: Int, maxHR: Int) -> Int {
        let score = Double(avgHR) * 0.6 + Double(maxHR) * 0.3 + Double(minHR) * 0.1
        return Int(score.rounded())
    }

    @MainActor
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let s: [HeartRatePoint] = HeartRateService.shared.fetchHeartRateSeries(forActivityId: activity.id)
            async let z: HeartRateZones = HeartRateService.shared.fetchZones()
            async let ts: ZoneTimeSpentResponse = HeartRateService.shared.fetchZoneTimeSpent(forActivityId: activity.id)

            let (series, fetchedZones, timeSpent) = try await (s, z, ts)
            self.samples = series.sorted(by: { $0.time < $1.time })
            self.zones = fetchedZones
            self.zoneTimeSpent = timeSpent
        } catch {
            if let e = error as? LocalizedError, let msg = e.errorDescription {
                errorMessage = msg
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Zone overlays

    @ChartContentBuilder
    private func zoneRule(at bpm: Int, xStart: Date, xEnd: Date, color: Color, label: String) -> some ChartContent {
        RectangleMark(
            xStart: .value("xStart", xStart),
            xEnd: .value("xEnd", xEnd),
            yStart: .value("yStart", bpm),
            yEnd: .value("yEnd", bpm + 1)
        )
        .foregroundStyle(color.opacity(0.6))
        .opacity(1.0)
        .annotation(position: .trailing, alignment: .leading) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    @ChartContentBuilder
    private func zoneBandRect(xStart: Date, xEnd: Date, from lower: Int, to upper: Int, color: Color) -> some ChartContent {
        RectangleMark(
            xStart: .value("xStart", xStart),
            xEnd: .value("xEnd", xEnd),
            yStart: .value("lower", lower),
            yEnd: .value("upper", upper)
        )
        .foregroundStyle(color)
        .opacity(1.0)
    }

    // MARK: - Helpers for zone label/color

    private func zoneNumber(from apiZone: String) -> Int {
        // Accepts "Z1", "z1", "Zone 1", "1"
        let trimmed = apiZone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.hasPrefix("z"), let n = Int(trimmed.dropFirst()) { return n }
        if trimmed.hasPrefix("zone"), let n = Int(trimmed.replacingOccurrences(of: "zone", with: "").trimmingCharacters(in: .whitespaces)) { return n }
        if let n = Int(trimmed) { return n }
        return 0
    }

    private func zoneColor(for zone: Int) -> Color {
        switch zone {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }
}

// MARK: - Model for chart points

struct HeartRatePoint: Identifiable, Hashable {
    let id = UUID()
    let time: Date
    let value: Int
}
