import SwiftUI
import Charts

/// "Stated vs revealed" bar chart: two bars per attribute
struct StatedVsRevealedChart: View {
    let stated: Weights
    let revealed: Weights
    var statedLabel = "Said"
    var revealedLabel = "Chose"

    private struct Point: Identifiable {
        let attr: Attribute
        let series: String
        let value: Double
        var id: String { attr.rawValue + series }
    }

    private var points: [Point] {
        Attribute.allCases.flatMap { a in
            [Point(attr: a, series: statedLabel, value: stated[a] ?? 0),
             Point(attr: a, series: revealedLabel, value: revealed[a] ?? 0)]
        }
    }

    var body: some View {
        Chart(points) { p in
            BarMark(
                x: .value("Attribute", p.attr.shortLabel),
                y: .value("Weight", p.value)
            )
            .foregroundStyle(by: .value("Series", p.series))
            .position(by: .value("Series", p.series))
            .annotation(position: .top, spacing: 2) {
                Text("\(Int(p.value.rounded()))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartForegroundStyleScale([statedLabel: Color.gray.opacity(0.45), revealedLabel: Color.pink])
        .chartYAxisLabel("Weight (6 traits total 100)")
        .chartLegend(position: .top, alignment: .leading)
        .frame(height: 240)
    }
}

/// Horizontal bar chart: number of people per type
struct TypeDistributionChart: View {
    struct Row: Identifiable {
        let type: TypeInfo
        let count: Int
        var id: String { type.id }
    }

    let rows: [Row]
    var highlightID: String?

    var body: some View {
        let total = max(rows.reduce(0) { $0 + $1.count }, 1)
        Chart(rows) { row in
            BarMark(
                x: .value("People", row.count),
                y: .value("Type", row.type.name)
            )
            .foregroundStyle(row.type.id == highlightID ? Color.pink : Color.pink.opacity(0.35))
            .annotation(position: .trailing, spacing: 4) {
                Text("\(row.count) (\(Int((Double(row.count) / Double(total) * 100).rounded()))%)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYScale(domain: rows.map(\.type.name))
        .chartXAxis(.hidden)
        .frame(height: CGFloat(rows.count) * 26 + 20)
    }
}

/// A small number tile, e.g. "8378 dates"
struct StatTile: View {
    let value: String
    let caption: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
