import Foundation

/// What the user has done in Discover, kept on the device and used to adapt recommendations.
struct RecommendationSignals: Codable, Equatable {
    /// Learned adjustments to the onboarding trait weights, keyed by Attribute.rawValue.
    var weightDeltas: [String: Double] = [:]
    var liked: [String] = []
    var passed: [String] = []
    var matched: [String] = []
    var engaged: [String] = []
}

/// The nearest real speed-dating participants and what they actually chose.
struct NeighborPrior {
    /// Average revealed weights of the neighbors (sums to 100).
    let weights: Weights
    let neighborCount: Int
    let poolSize: Int

    /// The two traits the neighbors weighted most, for explanations.
    var topAttributes: [Attribute] { Array(TypeCalculator.ranked(weights).prefix(2)) }
}

struct Recommendation: Identifiable {
    let character: VirtualCharacter
    /// Displayed fit index, 25 to 95; not a calibrated probability.
    let score: Int
    /// Ranking value, 0 to 100.
    let rankValue: Double
    let datasetScore: Double
    let personalScore: Double
    let interestScore: Double
    let sharedInterests: [String]
    let standoutAttribute: Attribute?
    /// Item-to-item feedback from likes and passes, roughly -1...1.
    let feedback: Double
    /// The liked character this one most resembles, if the resemblance is strong.
    let similarToLiked: VirtualCharacter?

    var id: String { character.id }

    var reason: String {
        var parts: [String] = []
        if let similarToLiked {
            parts.append("Similar to \(similarToLiked.name), whom you liked")
        } else if let standoutAttribute {
            let value = character.scores[standoutAttribute] ?? 0
            parts.append("Strong on \(standoutAttribute.label.lowercased()) (\(String(format: "%.1f", value)))")
        }
        if !sharedInterests.isEmpty {
            parts.append("you both like \(sharedInterests.prefix(2).joined(separator: " & ").lowercased())")
        }
        return parts.isEmpty ? "A different kind of energy to explore" : parts.joined(separator: " · ")
    }
}

/// Hybrid recommender:
/// 45% dataset prior (user-based k-nearest neighbors over participants.json),
/// 35% personal fit (onboarding weights refined by likes, passes, matches, and chats),
/// 20% interest overlap between the profile and the character,
/// plus item-to-item feedback: characters similar to liked ones move up, similar to passed ones move down.
/// Everything runs locally with plain arithmetic.
enum RecommendationEngine {
    static let neighborCount = 25
    static let datasetShare = 0.45
    static let personalShare = 0.35
    static let interestShare = 0.20
    /// Points added per unit of feedback, so a single swipe can visibly reorder the deck.
    static let feedbackPoints = 30.0
    static let passPenalty = 0.8
    static let similarThreshold = 0.3

    /// Learning rates for each kind of feedback.
    static let likeRate = 6.0
    static let passRate = -3.0
    static let matchRate = 6.0
    static let engageRate = 3.0
    static let maxDelta = 15.0
    static let engagedMessageCount = 4

    // MARK: Dataset prior

    /// Finds the participants whose stated priorities and interests are closest to the user,
    /// then averages what those people revealed through their real yes/no decisions.
    static func neighborPrior(
        weights: Weights,
        profile: DatingProfile,
        participants: [Participant],
        k: Int = neighborCount
    ) -> NeighborPrior? {
        let userWeights = normalized(weights)
        // The dataset is heterosexual speed dating: men in it rated women and vice versa.
        let raterGender = profile.preference == "man" ? "female" : "male"
        let usable = participants.filter { $0.statedWeights != nil && $0.revealedWeights != nil }
        let sameSide = profile.preference == "both" ? usable : usable.filter { $0.gender == raterGender }
        let pool = sameSide.isEmpty ? usable : sameSide
        guard !pool.isEmpty else { return nil }

        let interestKeys = datasetInterestKeys(for: profile.interests)
        let ranked = pool.map { participant -> (distance: Double, participant: Participant) in
            let stated = normalized(participant.statedWeights ?? [:])
            let weightDistance = Attribute.allCases.reduce(0.0) { sum, attribute in
                let delta = (userWeights[attribute] ?? 0) - (stated[attribute] ?? 0)
                return sum + delta * delta
            }.squareRoot() / 100
            let ratings = interestKeys.compactMap { participant.interests[$0] ?? nil }
            let affinity = ratings.isEmpty ? 0.5 : ratings.reduce(0, +) / Double(ratings.count) / 10
            return (weightDistance + 0.5 * (1 - affinity), participant)
        }
        .sorted { $0.distance < $1.distance }

        let neighbors = ranked.prefix(max(1, k)).map { $0.participant }
        var average: Weights = [:]
        for attribute in Attribute.allCases {
            let total = neighbors.reduce(0.0) { $0 + (normalized($1.revealedWeights ?? [:])[attribute] ?? 0) }
            average[attribute] = total / Double(neighbors.count)
        }
        return NeighborPrior(weights: normalized(average), neighborCount: neighbors.count, poolSize: pool.count)
    }

    // MARK: Behavior learning

    /// Onboarding weights plus everything learned from the user's actions.
    static func learnedWeights(base: Weights, signals: RecommendationSignals) -> Weights {
        var result = normalized(base)
        for attribute in Attribute.allCases {
            let delta = signals.weightDeltas[attribute.rawValue] ?? 0
            result[attribute] = max(2, (result[attribute] ?? 0) + delta)
        }
        return normalized(result)
    }

    /// Moves the learned weights toward (positive rate) or away from (negative rate)
    /// the traits that make this character stand out from the rest of the pool.
    static func update(_ signals: inout RecommendationSignals, toward character: VirtualCharacter, in pool: [VirtualCharacter], rate: Double) {
        let means = poolMeans(pool.isEmpty ? [character] : pool)
        for attribute in Attribute.allCases {
            let offset = (character.scores[attribute] ?? 0) - (means[attribute] ?? 0)
            let current = signals.weightDeltas[attribute.rawValue] ?? 0
            signals.weightDeltas[attribute.rawValue] = min(maxDelta, max(-maxDelta, current + rate * offset))
        }
    }

    // MARK: Ranking

    static func rank(
        _ characters: [VirtualCharacter],
        profile: DatingProfile,
        baseWeights: Weights,
        signals: RecommendationSignals,
        prior: NeighborPrior?
    ) -> [Recommendation] {
        guard !characters.isEmpty else { return [] }
        let means = poolMeans(characters)
        let personalWeights = learnedWeights(base: baseWeights, signals: signals)
        let priorWeights = prior?.weights ?? personalWeights
        var combined: Weights = [:]
        for attribute in Attribute.allCases {
            combined[attribute] = datasetShare * (priorWeights[attribute] ?? 0) + personalShare * (personalWeights[attribute] ?? 0)
        }

        return characters.map { character in
            let dataset = traitScore(character, weights: priorWeights, means: means)
            let traitPart = traitScore(character, weights: personalWeights, means: means)
            let personal = 0.6 * traitPart + 0.4 * temperamentScore(character, profile: profile)
            let shared = sharedInterests(profile: profile, character: character)
            let wanted = max(1, min(3, profile.interests.count))
            let interest = min(1, Double(shared.count) / Double(wanted)) * 100
            let feedback = feedbackValue(character, signals: signals, pool: characters, means: means)
            let value = datasetShare * dataset + personalShare * personal + interestShare * interest
                + feedbackPoints * feedback.value

            let standout = Attribute.allCases
                .map { ($0, (combined[$0] ?? 0) * ((character.scores[$0] ?? 0) - (means[$0] ?? 0))) }
                .filter { $0.1 > 0 }
                .max { $0.1 < $1.1 }?.0

            return Recommendation(
                character: character,
                score: displayedFit(for: value),
                rankValue: value,
                datasetScore: dataset,
                personalScore: personal,
                interestScore: interest,
                sharedInterests: shared,
                standoutAttribute: standout,
                feedback: feedback.value,
                similarToLiked: feedback.closestLiked
            )
        }
        .sorted { $0.rankValue != $1.rankValue ? $0.rankValue > $1.rankValue : $0.character.id < $1.character.id }
    }

    static func displayedFit(for rankValue: Double) -> Int {
        min(95, max(25, Int((25 + 0.75 * rankValue).rounded())))
    }

    /// Discover order: fresh faces first, then passed ones, then existing connections.
    static func deckOrder(_ ranked: [Recommendation], signals: RecommendationSignals, connected: Set<String>) -> [VirtualCharacter] {
        func group(_ id: String) -> Int {
            if connected.contains(id) { return 2 }
            return signals.passed.contains(id) ? 1 : 0
        }
        return ranked.enumerated()
            .sorted { lhs, rhs in
                let left = group(lhs.element.id), right = group(rhs.element.id)
                return left != right ? left < right : lhs.offset < rhs.offset
            }
            .map { $0.element.character }
    }

    // MARK: Item similarity

    /// Similarity of two characters, roughly -1...1: trait shape (cosine of above- and below-average
    /// scores) 60%, same temperament 25%, shared persona interests 15%.
    static func similarity(_ lhs: VirtualCharacter, _ rhs: VirtualCharacter, means: Weights) -> Double {
        let left = Attribute.allCases.map { (lhs.scores[$0] ?? 0) - (means[$0] ?? 0) }
        let right = Attribute.allCases.map { (rhs.scores[$0] ?? 0) - (means[$0] ?? 0) }
        let dot = zip(left, right).reduce(0.0) { $0 + $1.0 * $1.1 }
        let lengths = left.reduce(0.0) { $0 + $1 * $1 }.squareRoot() * right.reduce(0.0) { $0 + $1 * $1 }.squareRoot()
        let cosine = lengths > 0 ? dot / lengths : 0
        let sameTemperament = lhs.temperament == rhs.temperament ? 1.0 : 0
        let leftInterests = Set(lhs.interests), rightInterests = Set(rhs.interests)
        let union = leftInterests.union(rightInterests).count
        let overlap = union > 0 ? Double(leftInterests.intersection(rightInterests).count) / Double(union) : 0
        return 0.6 * cosine + 0.25 * sameTemperament + 0.15 * overlap
    }

    /// Average similarity to liked characters minus a share of the average similarity to passed ones.
    static func feedbackValue(
        _ character: VirtualCharacter,
        signals: RecommendationSignals,
        pool: [VirtualCharacter],
        means: Weights
    ) -> (value: Double, closestLiked: VirtualCharacter?) {
        func others(_ ids: [String]) -> [VirtualCharacter] {
            var seen = Set<String>()
            return ids.filter { $0 != character.id && seen.insert($0).inserted }
                .compactMap { id in pool.first { $0.id == id } }
        }
        let liked = others(signals.liked + signals.matched)
        let passed = others(signals.passed)
        let likedScores = liked.map { ($0, similarity(character, $0, means: means)) }
        let passedScores = passed.map { similarity(character, $0, means: means) }
        let likeAverage = likedScores.isEmpty ? 0 : likedScores.reduce(0.0) { $0 + $1.1 } / Double(likedScores.count)
        let passAverage = passedScores.isEmpty ? 0 : passedScores.reduce(0, +) / Double(passedScores.count)
        let closest = likedScores.filter { $0.1 >= similarThreshold }.max { $0.1 < $1.1 }?.0
        return (likeAverage - passPenalty * passAverage, closest)
    }

    // MARK: Helpers

    /// How much the character's above-average traits line up with the weights, mapped to 0...100.
    static func traitScore(_ character: VirtualCharacter, weights: Weights, means: Weights) -> Double {
        let fit = Attribute.allCases.reduce(0.0) { sum, attribute in
            sum + (weights[attribute] ?? 0) / 100 * ((character.scores[attribute] ?? 0) - (means[attribute] ?? 0))
        }
        return min(100, max(0, 50 + 100 * fit))
    }

    /// Energy and communication style, using the same temperament mapping as CompatibilityEngine.
    static func temperamentScore(_ character: VirtualCharacter, profile: DatingProfile) -> Double {
        let favored: (energy: String, style: String)
        switch character.temperament {
        case .reflective: favored = ("deep", "Thoughtful")
        case .spontaneous: favored = ("playful", "Playful")
        case .steady: favored = ("calm", "Direct")
        case .expressive: favored = ("playful", "Thoughtful")
        }
        return (profile.energy == favored.energy ? 67 : 0) + (profile.communication == favored.style ? 33 : 0)
    }

    static func sharedInterests(profile: DatingProfile, character: VirtualCharacter) -> [String] {
        let theirs = Set(character.interests)
        return profile.interests.filter { theirs.contains($0) }
    }

    /// Maps profile interests to the 17 interest columns in participants.json.
    static func datasetInterestKeys(for interests: [String]) -> [String] {
        let map: [String: [String]] = [
            "Music": ["music", "concerts"], "Art": ["art", "museums"], "Coffee": ["dining"],
            "Books": ["reading"], "Gaming": ["gaming"], "Travel": ["hiking"],
            "Design": ["art", "museums"], "Film": ["movies", "theater"], "Nature": ["hiking"],
            "Food": ["dining"], "Fantasy": ["reading", "movies"], "Fitness": ["exercise", "sports", "yoga"],
        ]
        var keys: [String] = []
        for interest in interests {
            for key in map[interest] ?? [] where !keys.contains(key) { keys.append(key) }
        }
        return keys
    }

    static func poolMeans(_ characters: [VirtualCharacter]) -> Weights {
        var means: Weights = [:]
        for attribute in Attribute.allCases {
            let total = characters.reduce(0.0) { $0 + ($1.scores[attribute] ?? 0) }
            means[attribute] = characters.isEmpty ? 0 : total / Double(characters.count)
        }
        return means
    }

    static func normalized(_ weights: Weights) -> Weights {
        let total = Attribute.allCases.reduce(0.0) { $0 + max(0, weights[$1] ?? 0) }
        guard total > 0 else {
            return Dictionary(uniqueKeysWithValues: Attribute.allCases.map { ($0, 100.0 / 6) })
        }
        return Dictionary(uniqueKeysWithValues: Attribute.allCases.map { ($0, max(0, weights[$0] ?? 0) / total * 100) })
    }
}

extension VirtualCharacter {
    /// Profile-interest vocabulary (see ProfileEditorView) drawn from each persona's interests.
    var interests: [String] {
        switch id {
        case "victoria": return ["Art", "Coffee", "Music", "Books"]
        case "vivian": return ["Books", "Nature", "Coffee"]
        case "lily": return ["Nature", "Music", "Food", "Fantasy"]
        case "selene": return ["Fantasy", "Nature", "Music"]
        case "charlie": return ["Music", "Film", "Food", "Design"]
        case "vaggie": return ["Fitness", "Food", "Coffee"]
        case "riven": return ["Music", "Travel", "Food", "Art"]
        case "loid": return ["Coffee", "Gaming", "Food", "Travel"]
        case "dorian": return ["Art", "Design", "Music", "Coffee"]
        case "nightwing": return ["Fitness", "Travel", "Food"]
        case "angel": return ["Design", "Music", "Film", "Food"]
        case "joon": return ["Design", "Food", "Art", "Music"]
        default: return ["Music", "Film", "Food", "Books"]
        }
    }
}
