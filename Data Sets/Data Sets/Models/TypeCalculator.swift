import Foundation

/// Turns the user's yes / no choices into what they actually value, and into their type.
/// Same algorithm as steps 5 and 6 of preprocess.ipynb, which produced the types of the 452 real participants.
enum TypeCalculator {
    /// Minimum number of "yes" and of "no" answers needed for a comparison
    static let minPerSide = 2

    /// Returns the six weights (summing to 100), or nil when the user said yes to everything,
    /// no to everything, or one side has too few answers.
    static func revealedWeights(cards: [Card], liked: [Bool]) -> Weights? {
        let n = cards.count
        guard n > 0, n == liked.count else { return nil }
        let yesCount = liked.filter { $0 }.count
        let noCount = n - yesCount
        guard yesCount >= minPerSide, noCount >= minPerSide else { return nil }

        var diffs: Weights = [:]
        for attr in Attribute.allCases {
            let scores = cards.map { $0.score(attr) }

            // 1. Standardize within this set of cards (z-scores), so attributes that are scored high everywhere don't dominate
            let mean = scores.reduce(0, +) / Double(n)
            let variance = scores.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(n)
            let sd = variance.squareRoot()
            guard sd > 0 else {
                // Every card has the same score here, so it cannot have influenced the choice
                diffs[attr] = 0
                continue
            }

            // 2. Mean of the "yes" cards minus mean of the "no" cards
            var yesSum = 0.0, noSum = 0.0
            for (i, s) in scores.enumerated() {
                let z = (s - mean) / sd
                if liked[i] { yesSum += z } else { noSum += z }
            }
            let diff = yesSum / Double(yesCount) - noSum / Double(noCount)

            // 3. Negative differences count as 0
            diffs[attr] = max(0, diff)
        }

        // 4. Rescale so the weights sum to 100
        let total = diffs.values.reduce(0, +)
        guard total > 0 else { return nil }
        return diffs.mapValues { $0 / total * 100 }
    }

    /// All six attributes sorted by weight, highest first (ties keep Attribute order)
    static func ranked(_ weights: Weights) -> [Attribute] {
        Attribute.allCases.sorted { a, b in
            let wa = weights[a] ?? 0, wb = weights[b] ?? 0
            return wa != wb ? wa > wb : a.order < b.order
        }
    }

    /// Type id such as "attractive+funny" (the two attributes joined in Attribute order, matching types.json)
    static func typeID(for weights: Weights) -> String {
        let top = ranked(weights).prefix(2).sorted { $0.order < $1.order }
        return top.map(\.rawValue).joined(separator: "+")
    }
}
