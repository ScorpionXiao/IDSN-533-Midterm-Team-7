import Foundation
import Observation

/// All state for one quiz run: who the user wants to see, what they said, the cards drawn, and what they chose.
@Observable
final class QuizSession {
    enum Target: String, CaseIterable, Identifiable {
        case female, male, any
        var id: String { rawValue }
        var label: String {
            switch self {
            case .female: return "Women"
            case .male: return "Men"
            case .any: return "Either"
            }
        }
        /// Gender passed to DataStore.drawCards
        var cardGender: String? { self == .any ? nil : rawValue }
    }

    static let firstDeckSize = 16
    static let extraDeckSize = 8
    static let statedStep = 5

    var target: Target = .any
    /// "Stated" points per attribute (multiples of 5); must total 100
    var stated: [Attribute: Int] = Dictionary(uniqueKeysWithValues: Attribute.allCases.map { ($0, 0) })
    private(set) var deck: [Card] = []
    private(set) var liked: [Bool] = []
    private(set) var revealed: Weights?

    var statedTotal: Int { stated.values.reduce(0, +) }
    var statedRemaining: Int { 100 - statedTotal }
    var statedWeights: Weights { stated.mapValues(Double.init) }

    var currentIndex: Int { liked.count }
    var currentCard: Card? { currentIndex < deck.count ? deck[currentIndex] : nil }
    var isDeckFinished: Bool { !deck.isEmpty && liked.count == deck.count }
    var typeID: String? { revealed.map(TypeCalculator.typeID(for:)) }

    func setStated(_ attr: Attribute, to value: Int) {
        let others = statedTotal - (stated[attr] ?? 0)
        let snapped = (value / Self.statedStep) * Self.statedStep
        stated[attr] = max(0, min(snapped, 100 - others))
    }

    func startDeck(store: DataStore) {
        deck = store.drawCards(Self.firstDeckSize, gender: target.cardGender)
        liked = []
        revealed = nil
    }

    /// Draws a few more cards when the user said yes to everything or no to everything
    func addCards(store: DataStore) {
        let used = Set(deck.map(\.id))
        deck += store.drawCards(Self.extraDeckSize, gender: target.cardGender, excluding: used)
    }

    /// Records the choice for the current card and computes the result after the last card.
    /// Returns nil = not finished yet; true = result ready; false = no result, more cards needed
    @discardableResult
    func decide(_ like: Bool) -> Bool? {
        guard currentCard != nil else { return nil }
        liked.append(like)
        guard isDeckFinished else { return nil }
        revealed = TypeCalculator.revealedWeights(cards: deck, liked: liked)
        return revealed != nil
    }

    func undo() {
        guard !liked.isEmpty else { return }
        liked.removeLast()
        revealed = nil
    }

    func reset() {
        stated = Dictionary(uniqueKeysWithValues: Attribute.allCases.map { ($0, 0) })
        deck = []
        liked = []
        revealed = nil
    }
}
