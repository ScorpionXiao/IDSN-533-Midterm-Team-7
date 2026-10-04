import SwiftUI

// MARK: - 3. Swipe: what you choose

struct SwipeView: View {
    @Environment(QuizSession.self) private var session
    @Environment(DataStore.self) private var store
    var onFinished: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var showNeedMore = false

    private let swipeThreshold: CGFloat = 110

    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(session.currentIndex), total: Double(max(session.deck.count, 1))) {
                Text("Card \(min(session.currentIndex + 1, session.deck.count)) of \(session.deck.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Text("Go with your gut: would you see this person again?")
                .font(.headline)

            ZStack {
                if let card = session.currentCard {
                    CardView(card: card, number: session.currentIndex + 1)
                        .id(card.id)
                        .offset(x: dragOffset.width, y: dragOffset.height * 0.2)
                        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                        .overlay(alignment: .top) { swipeStamp }
                        .gesture(dragGesture)
                        .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity),
                                                removal: .opacity))
                } else {
                    ProgressView()
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal)

            HStack(spacing: 48) {
                circleButton("xmark", color: .gray) { choose(false) }
                circleButton("arrow.uturn.backward", color: .secondary, size: 44) { session.undo() }
                    .disabled(session.currentIndex == 0)
                circleButton("heart.fill", color: .pink) { choose(true) }
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("Step 2: What you choose")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Let's try a few more", isPresented: $showNeedMore) {
            Button("OK, \(QuizSession.extraDeckSize) more cards") {
                session.addCards(store: store)
            }
        } message: {
            Text("You said yes to everything or no to everything, so we can't tell what you value yet. Swipe \(QuizSession.extraDeckSize) more cards, with some yes and some no.")
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { dragOffset = $0.translation }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    choose(true)
                } else if value.translation.width < -swipeThreshold {
                    choose(false)
                } else {
                    withAnimation(.spring) { dragOffset = .zero }
                }
            }
    }

    @ViewBuilder private var swipeStamp: some View {
        if dragOffset.width > 30 {
            stamp("YES", color: .pink)
        } else if dragOffset.width < -30 {
            stamp("NO", color: .gray)
        }
    }

    private func stamp(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 3))
            .padding(.top, 24)
            .opacity(min(1, abs(dragOffset.width) / swipeThreshold))
    }

    private func choose(_ like: Bool) {
        dragOffset = .zero
        let result: Bool? = withAnimation(.easeOut(duration: 0.2)) { session.decide(like) }
        switch result {
        case .some(true): onFinished()
        case .some(false): showNeedMore = true
        case .none: break
        }
    }

    private func circleButton(_ symbol: String, color: Color, size: CGFloat = 64,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(.background, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        }
    }
}

/// A date card: the six scores this person received in a real speed date
struct CardView: View {
    let card: Card
    let number: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.pink.opacity(0.8))
                VStack(alignment: .leading) {
                    Text("Date #\(number)")
                        .font(.title3.bold())
                    Text("\(card.partnerGender == "female" ? "Woman" : "Man") | scores from a real date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(Attribute.allCases) { attr in
                ScoreBar(attribute: attr, score: card.score(attr))
            }
        }
        .padding(24)
        .frame(maxWidth: 400)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.quaternary))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
    }
}

struct ScoreBar: View {
    let attribute: Attribute
    let score: Double   // 1-10

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(attribute.label, systemImage: attribute.symbol)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(score)) / 10")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(.pink.gradient)
                        .frame(width: geo.size.width * min(max(score / 10, 0), 1))
                }
            }
            .frame(height: 8)
        }
    }
}
