import SwiftUI

public struct FriendsView: View {
    // UI state
    @State private var activities: [FriendActivity] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Sheets
    @State private var showFilters = false
    @State private var showManageFriends = false

    // Filters (UI-only for now)
    @State private var selectedTypes: Set<String> = []
    @State private var selectedFriends: Set<String> = []

    private let allTypes = ["Running", "Walking", "Cycling", "Hiking", "Swimming", "Gym"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 400)
                .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if filteredActivities.isEmpty {
                    Text("No friend activities yet.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(filteredActivities) { activity in
                                NavigationLink {
                                    ActivityDetailView(activity: activity.asActivity())
                                } label: {
                                    FriendActivityRow(activity: activity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFilters = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManageFriends = true
                    } label: {
                        Label("Manage Friends", systemImage: "person.3")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadActivities() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet(
                allTypes: allTypes,
                availableFriends: availableFriends,
                selectedTypes: $selectedTypes,
                selectedFriends: $selectedFriends,
                onClear: {
                    selectedTypes.removeAll()
                    selectedFriends.removeAll()
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showManageFriends) {
            ManageFriendsView()
                .presentationDetents([.large])
        }
        .onAppear {
            Task { await loadActivities() }
        }
    }

    // Unique friend names from current activities
    private var availableFriends: [String] {
        let names = Set(activities.map { $0.friendName })
        return names.sorted()
    }

    // Derived list applying filters
    private var filteredActivities: [FriendActivity] {
        activities.filter { activity in
            let typePass = selectedTypes.isEmpty || selectedTypes.contains(activity.type)
            let friendPass = selectedFriends.isEmpty || selectedFriends.contains(activity.friendName)
            return typePass && friendPass
        }
    }

    // MARK: - Load activities from API
    @MainActor
    private func loadActivities() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let apiActivities = try await FriendsService.shared.fetchFriendActivitiesWithDetails()
            
            // Convert to FriendActivity for the UI
            activities = apiActivities.map { apiActivity in
                FriendActivity(
                    id: apiActivity.id,
                    friendName: apiActivity.friendName,
                    name: apiActivity.name,
                    date: apiActivity.date,
                    type: apiActivity.type,
                    userId: apiActivity.userId  // Pass the userId
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load friend activities: \(error)")
        }
    }
}

// MARK: - FriendActivity model for UI-only
struct FriendActivity: Identifiable {
    let id: Int
    let friendName: String
    let name: String
    let date: Date
    let type: String
    let userId: Int  // Added to store the friend's user ID

    // Temporary mapping to your Activity type for detail screen
    func asActivity() -> Activity {
        Activity(
            id: id,
            name: name,
            date: date,
            type: type,
            userId: userId,  // Pass the actual userId
            user: Activity.User(id: userId, name: friendName),
            heartRateSamples: []
        )
    }
}

// MARK: - Row mirroring ActivityRow with a "Friend" badge
struct FriendActivityRow: View {
    let activity: FriendActivity

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: activity.date)
    }

    private var iconName: String {
        switch activity.type.lowercased() {
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        case "cycling", "biking": return "bicycle"
        case "hiking": return "figure.hiking"
        case "swimming": return "figure.pool.swim"
        case "gym", "workout", "strength": return "dumbbell"
        default: return "figure.walk"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    FriendBadge(name: activity.friendName)
                }
                Text("\(formattedDate) • \(activity.type)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.name), \(activity.type), \(formattedDate), by \(activity.friendName)")
    }
}

private struct FriendBadge: View {
    let name: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2.fill")
            Text(name)
                .lineLimit(1)
        }
        .font(.caption)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.orange.opacity(0.15))
        .foregroundColor(.orange)
        .clipShape(Capsule())
    }
}

// MARK: - Compact Filter sheet with scalable friend selection
private struct FilterSheet: View {
    let allTypes: [String]
    let availableFriends: [String]
    @Binding var selectedTypes: Set<String>
    @Binding var selectedFriends: Set<String>
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Selected friends chips + navigation to selector
                Section("Friends") {
                    if selectedFriends.isEmpty {
                        Text("No friends selected")
                            .foregroundColor(.secondary)
                    } else {
                        FlowLayout(
                            views: Array(selectedFriends).sorted().map { name in
                                AnyView(ChipView(text: name) {
                                    selectedFriends.remove(name)
                                })
                            },
                            spacing: 8
                        )
                        .padding(.vertical, 4)
                    }

                    NavigationLink {
                        FriendsSelectorView(
                            allFriends: availableFriends,
                            initialSelection: selectedFriends
                        ) { newSelection in
                            selectedFriends = newSelection
                        }
                    } label: {
                        Label("Choose friends…", systemImage: "person.crop.circle.badge.plus")
                    }
                }

                // Activity types toggles (kept simple; can also move to selector if needed)
                Section("Activity types") {
                    ForEach(allTypes, id: \.self) { type in
                        Toggle(isOn: Binding(
                            get: { selectedTypes.contains(type) },
                            set: { newValue in
                                if newValue { selectedTypes.insert(type) }
                                else { selectedTypes.remove(type) }
                            }
                        )) {
                            Text(type)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") { onClear() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Searchable multi-select friends selector
private struct FriendsSelectorView: View {
    let allFriends: [String]
    let initialSelection: Set<String>
    let onDone: (Set<String>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<String> = []
    @State private var query: String = ""

    private var filteredFriends: [String] {
        guard !query.isEmpty else { return allFriends }
        return allFriends.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List {
            ForEach(filteredFriends, id: \.self) { name in
                Button {
                    toggle(name)
                } label: {
                    HStack {
                        Text(name)
                        Spacer()
                        if selection.contains(name) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Select Friends")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    onDone(selection)
                    dismiss()
                }
            }
        }
        .onAppear {
            self.selection = initialSelection
        }
    }

    private func toggle(_ name: String) {
        if selection.contains(name) { selection.remove(name) }
        else { selection.insert(name) }
    }
}

// MARK: - Small reusable chip and flow layout
private struct ChipView: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .lineLimit(1)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .font(.caption)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.orange.opacity(0.15))
        .foregroundColor(.orange)
        .clipShape(Capsule())
    }
}

// FlowLayout rebuilt to accept an explicit array of AnyView, avoiding reflection and `any View` casts.
private struct FlowLayout: View {
    let views: [AnyView]
    let spacing: CGFloat

    init(views: [AnyView], spacing: CGFloat = 8) {
        self.views = views
        self.spacing = spacing
    }

    var body: some View {
        FlexibleView(
            availableWidth: UIScreen.main.bounds.width - 48,
            spacing: spacing,
            alignment: .leading,
            contentViews: views
        )
    }
}

// Helper to layout chips in wrapped rows without using Mirror or any View existential casts
private struct FlexibleView: View {
    let availableWidth: CGFloat
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let contentViews: [AnyView]

    @State private var elementsSize: [Int: CGSize] = [:]

    var body: some View {
        // Precompute rows outside of the ViewBuilder closure to avoid control-flow in ViewBuilder
        let rows: [[Int]] = {
            var computedRows: [[Int]] = [[]]
            var currentRowWidth: CGFloat = 0

            for index in contentViews.indices {
                let elementSize = elementsSize[index, default: CGSize(width: availableWidth, height: 1)]
                let isRowEmpty = computedRows.last?.isEmpty ?? true
                let proposedWidth = (isRowEmpty ? currentRowWidth : currentRowWidth + spacing) + elementSize.width
                if proposedWidth > availableWidth {
                    computedRows.append([index])
                    currentRowWidth = elementSize.width
                } else {
                    if isRowEmpty {
                        computedRows[computedRows.count - 1] = [index]
                    } else {
                        computedRows[computedRows.count - 1].append(index)
                    }
                    currentRowWidth = (isRowEmpty ? currentRowWidth : currentRowWidth + spacing) + elementSize.width
                }
            }
            return computedRows
        }()

        return VStack(alignment: alignment, spacing: spacing) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: spacing) {
                    ForEach(rows[rowIndex], id: \.self) { index in
                        contentViews[index]
                            .fixedSize()
                            .readSize { size in
                                elementsSize[index] = size
                            }
                    }
                }
            }
        }
    }
}

// Utility to measure child size
private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { }
}

private extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

#Preview {
    FriendsView()
}
