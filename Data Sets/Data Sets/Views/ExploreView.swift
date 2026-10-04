import SwiftUI

// MARK: - 5. Explore

struct ExploreView: View {
    @Environment(DataStore.self) private var store

    enum GenderFilter: String, CaseIterable, Identifiable {
        case all, female, male
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "Everyone"
            case .female: return "Women"
            case .male: return "Men"
            }
        }
    }

    @State private var gender: GenderFilter = .all
    @State private var field: String? = nil   // nil = all fields

    /// Participants who have a type and match the current filters
    private var filtered: [Participant] {
        store.participants.filter { p in
            p.revealedWeights != nil && p.statedWeights != nil
                && (gender == .all || p.gender == gender.rawValue)
                && (field == nil || p.field == field)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let s = store.summary {
                        HStack(spacing: 10) {
                            StatTile(value: "\(s.nDates)", caption: "dates")
                            StatTile(value: "\(s.nParticipants)", caption: "people")
                            StatTile(value: "\(Int((s.matchRate * 100).rounded()))%", caption: "match rate")
                        }
                    }

                    filters

                    let group = filtered
                    if group.count < 5 {
                        ContentUnavailableView("Not enough people", systemImage: "person.slash",
                                               description: Text("Only \(group.count) people match these filters. Try another combination."))
                    } else {
                        section("What people say vs what they choose", subtitle: "Average weights of \(group.count) people. Gray is the 100 points they split when signing up; pink is calculated from their actual choices.") {
                            StatedVsRevealedChart(stated: average(group.compactMap(\.statedWeights)),
                                                  revealed: average(group.compactMap(\.revealedWeights)))
                        }

                        section("How the 15 types are distributed", subtitle: "Tap a type in the list below to see its profile") {
                            TypeDistributionChart(rows: distribution(group))
                        }

                        VStack(spacing: 0) {
                            ForEach(distribution(group)) { row in
                                NavigationLink(value: row.type) {
                                    HStack {
                                        Text(row.type.name)
                                        Spacer()
                                        Text("\(row.count)").foregroundStyle(.secondary)
                                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                Divider()
                            }
                        }
                    }

                    Text("Data: Columbia University Speed Dating Experiment (2002-2004), Kaggle / OpenML version.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Explore")
            .navigationDestination(for: TypeInfo.self) { TypeDetailView(type: $0) }
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Gender", selection: $gender) {
                ForEach(GenderFilter.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker("Field of study", selection: $field) {
                Text("All fields").tag(String?.none)
                ForEach(Array(Labels.fields.keys).sorted(), id: \.self) { key in
                    Text(Labels.field(key)).tag(String?.some(key))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func section<Content: View>(_ title: String, subtitle: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }

    private func average(_ list: [Weights]) -> Weights {
        guard !list.isEmpty else { return [:] }
        var sum: Weights = [:]
        for w in list {
            for a in Attribute.allCases { sum[a, default: 0] += w[a] ?? 0 }
        }
        return sum.mapValues { $0 / Double(list.count) }
    }

    private func distribution(_ group: [Participant]) -> [TypeDistributionChart.Row] {
        var counts: [String: Int] = [:]
        for p in group {
            if let t = p.type { counts[t, default: 0] += 1 }
        }
        return store.types
            .map { TypeDistributionChart.Row(type: $0, count: counts[$0.id] ?? 0) }
            .sorted { $0.count > $1.count }
    }
}

/// Detailed profile of one type
struct TypeDetailView: View {
    @Environment(DataStore.self) private var store
    let type: TypeInfo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(type.name)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.pink)
                Text(type.summaryText)
                Text("\(type.count) of \(store.typedCount) participants (\(String(format: "%.1f", type.share * 100))%)")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What this type says vs chooses").font(.headline)
                    StatedVsRevealedChart(stated: type.stated.asWeights, revealed: type.revealed.asWeights)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Who they are").font(.headline)
                    TypeProfileView(type: type)
                }
            }
            .padding()
        }
        .navigationTitle(type.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
