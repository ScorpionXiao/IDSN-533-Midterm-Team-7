import SwiftUI

// MARK: - 4. Result

struct ResultView: View {
    @Environment(QuizSession.self) private var session
    @Environment(DataStore.self) private var store
    @Environment(AppRouter.self) private var router
    var onRestart: () -> Void

    var body: some View {
        ScrollView {
            if let revealed = session.revealed, let typeID = session.typeID {
                content(revealed: revealed, typeInfo: store.type(withID: typeID))
                    .padding()
            } else {
                ContentUnavailableView("No result yet", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("Your result")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }

    @ViewBuilder
    private func content(revealed: Weights, typeInfo: TypeInfo?) -> some View {
        let ranked = TypeCalculator.ranked(revealed)
        VStack(alignment: .leading, spacing: 24) {
            // Type name and description
            VStack(alignment: .leading, spacing: 8) {
                Text("You are")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(typeInfo?.name ?? "\(ranked[0].label) & \(ranked[1].label)")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.pink)
                Text(TypeInfo.describe(ranked[0], ranked[1]))
                    .font(.body)
                if let typeInfo {
                    HStack(spacing: 6) {
                        if typeInfo.isRare {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                        }
                        Text(shareText(typeInfo))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            // Stated vs revealed
            card {
                Text("What you said vs what you chose")
                    .font(.headline)
                Text("Gray is the 100 points you split in step 1. Pink is calculated from your \(session.deck.count) swipes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                StatedVsRevealedChart(stated: session.statedWeights, revealed: revealed)
                Text(gapText(stated: session.statedWeights, revealed: revealed))
                    .font(.subheadline)
            }

            // Real participants of the same type
            if let typeInfo {
                card {
                    Text("Real participants with your type")
                        .font(.headline)
                    TypeProfileView(type: typeInfo)
                }
            }

            Text("Note: with 16 cards, your top trait matches the full-data result about 91% of the time and the exact type about 68% of the time, so treat the second trait as a hint.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Button {
                    onRestart()
                } label: {
                    Text("Try again").frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    router.tab = .explore
                } label: {
                    Text("Explore everyone's data").frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.bordered)

                ShareLink(item: shareMessage(typeInfo: typeInfo, ranked: ranked)) {
                    Label("Share result", systemImage: "square.and.arrow.up")
                }
            }
            .controlSize(.large)
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func shareText(_ t: TypeInfo) -> String {
        let pct = Int((t.share * 100).rounded())
        let pctText = pct < 1 ? "under 1%" : "\(pct)%"
        let base = "\(t.count) of \(store.typedCount) real participants (\(pctText)) share your type"
        return t.isRare ? base + ". You're a rare type!" : base
    }

    /// Finds the attributes where stated and revealed differ most and describes them in one sentence
    private func gapText(stated: Weights, revealed: Weights) -> String {
        let gaps = Attribute.allCases.map { ($0, (revealed[$0] ?? 0) - (stated[$0] ?? 0)) }
        guard let up = gaps.max(by: { $0.1 < $1.1 }), let down = gaps.min(by: { $0.1 < $1.1 }) else { return "" }
        if up.1 < 5 && down.1 > -5 {
            return "What you said and what you chose are very close. You know yourself well!"
        }
        var parts: [String] = []
        if down.1 <= -5 {
            parts.append("You gave \(down.0.label) \(Int(stated[down.0] ?? 0)) points, but it only weighs \(Int((revealed[down.0] ?? 0).rounded())) in your actual choices")
        }
        if up.1 >= 5 {
            parts.append("\(up.0.label) matters more than you think (\(Int(stated[up.0] ?? 0)) -> \(Int((revealed[up.0] ?? 0).rounded())) points)")
        }
        return parts.joined(separator: "; ") + "."
    }

    private func shareMessage(typeInfo: TypeInfo?, ranked: [Attribute]) -> String {
        let name = typeInfo?.name ?? "\(ranked[0].label) & \(ranked[1].label)"
        return "My Find Your Type result: \(name). I care most about \(ranked[0].label), then \(ranked[1].label)."
    }
}

/// Profile of real participants with a type: gender, age, field, interests
struct TypeProfileView: View {
    let type: TypeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            row("person.2.fill", "People", "\(type.count)")
            row("figure.dress.line.vertical.figure", "Gender split",
                ["female", "male"].map { "\(Labels.gender($0)) \(Int(((type.gender[$0] ?? 0) * 100).rounded()))%" }
                    .joined(separator: " | "))
            if let age = type.ageMean {
                row("calendar", "Average age", String(format: "%.1f", age))
            }
            row("graduationcap.fill", "Top fields",
                TypeInfo.top(type.field, 3).map { "\(Labels.field($0.key)) \(Int(($0.value * 100).rounded()))%" }
                    .joined(separator: ", "))
            row("star.fill", "Favorite activities",
                TypeInfo.top(type.interests, 3).map { "\(Labels.interest($0.key)) (\(String(format: "%.1f", $0.value)))" }
                    .joined(separator: ", "))
        }
        .font(.subheadline)
    }

    private func row(_ symbol: String, _ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Label(title, systemImage: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
            Text(value)
        }
    }
}
