import SwiftUI

/// Quiz flow: 1 Home -> 2 Stated -> 3 Swipe -> 4 Result
struct QuizFlowView: View {
    enum Step: Hashable { case stated, swipe, result }

    @State private var session = QuizSession()
    @State private var path: [Step] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(onStart: { path.append(.stated) })
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .stated:
                        StatedView(onNext: { path.append(.swipe) })
                    case .swipe:
                        SwipeView(onFinished: { path.append(.result) })
                    case .result:
                        ResultView(onRestart: {
                            session.reset()
                            path = []
                        })
                    }
                }
        }
        .environment(session)
    }
}

// MARK: - 1. Home

struct HomeView: View {
    @Environment(QuizSession.self) private var session
    @Environment(DataStore.self) private var store
    var onStart: () -> Void

    var body: some View {
        @Bindable var session = session
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(.pink.gradient)
                    .padding(.top, 40)

                VStack(spacing: 10) {
                    Text("Find Your Type")
                        .font(.largeTitle.bold())
                    Text("Find your real type using \(store.summary?.nDates ?? 8378) speed dates from \(store.summary?.nParticipants ?? 549) real people")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Whose cards do you want to see?")
                        .font(.headline)
                    Picker("Show me", selection: $session.target) {
                        ForEach(QuizSession.Target.allCases) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    howItWorksRow("1.circle.fill", "Tell us what you value: split 100 points across 6 traits")
                    howItWorksRow("2.circle.fill", "Swipe through \(QuizSession.firstDeckSize) real date cards: yes or no")
                    howItWorksRow("3.circle.fill", "See whether what you said matches what you chose")
                }

                Button(action: onStart) {
                    Text("Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("")
    }

    private func howItWorksRow(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text).foregroundStyle(.secondary)
        } icon: {
            Image(systemName: symbol).foregroundStyle(.pink)
        }
        .font(.subheadline)
    }
}

// MARK: - 2. Stated: split 100 points

struct StatedView: View {
    @Environment(QuizSession.self) private var session
    @Environment(DataStore.self) private var store
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("What matters to you in a partner?")
                    .font(.title2.bold())
                Text("Split 100 points across the 6 traits. More points = more important.")
                    .foregroundStyle(.secondary)
                Text(session.statedRemaining == 0 ? "All points used" : "\(session.statedRemaining) points left")
                    .font(.headline)
                    .foregroundStyle(session.statedRemaining == 0 ? .green : .pink)
                    .contentTransition(.numericText())
                    .padding(.top, 4)
            }
            .padding()

            List {
                ForEach(Attribute.allCases) { attr in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(attr.longLabel, systemImage: attr.symbol)
                            Spacer()
                            Text("\(session.stated[attr] ?? 0)")
                                .font(.headline.monospacedDigit())
                        }
                        Slider(value: binding(for: attr), in: 0...100, step: Double(QuizSession.statedStep))
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)

            Button {
                session.startDeck(store: store)
                onNext()
            } label: {
                Text("Next: start swiping")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(session.statedRemaining != 0)
            .padding()
        }
        .navigationTitle("Step 1: What you say")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Keeps the total from going above 100 while dragging
    private func binding(for attr: Attribute) -> Binding<Double> {
        Binding(
            get: { Double(session.stated[attr] ?? 0) },
            set: { session.setStated(attr, to: Int($0.rounded())) }
        )
    }
}
