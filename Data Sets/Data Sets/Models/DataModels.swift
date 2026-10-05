import Foundation

/// One card from cards.json: the six scores (1-10) a partner received in one real speed date.
struct Card: Codable, Identifiable, Hashable {
    var id = UUID()
    let attractive: Int
    let sincere: Int
    let intelligent: Int
    let funny: Int
    let ambitious: Int
    let sharedInterests: Int
    /// Whether the original rater said yes (never shown to the user; kept for reference)
    let decision: Int
    /// Gender of the person on the card: "male" / "female"
    let partnerGender: String

    enum CodingKeys: String, CodingKey {
        case attractive, sincere, intelligent, funny, ambitious
        case sharedInterests = "shared_interests"
        case decision
        case partnerGender = "partner_gender"
    }

    func score(_ a: Attribute) -> Double {
        switch a {
        case .attractive: return Double(attractive)
        case .sincere: return Double(sincere)
        case .intelligent: return Double(intelligent)
        case .funny: return Double(funny)
        case .ambitious: return Double(ambitious)
        case .sharedInterests: return Double(sharedInterests)
        }
    }
}

/// Top-level structure of types.json
struct TypesFile: Codable {
    let summary: Summary
    let types: [TypeInfo]
}

struct Summary: Codable {
    let nDates: Int
    let nParticipants: Int
    let nWithRevealed: Int
    let matchRate: Double
    let overall: StatedRevealed
    let byGender: [String: StatedRevealed]

    enum CodingKeys: String, CodingKey {
        case nDates = "n_dates"
        case nParticipants = "n_participants"
        case nWithRevealed = "n_with_revealed"
        case matchRate = "match_rate"
        case overall
        case byGender = "by_gender"
    }
}

struct StatedRevealed: Codable {
    let stated: [String: Double]
    let revealed: [String: Double]
}

/// Profile of one of the 15 types
struct TypeInfo: Codable, Identifiable, Hashable {
    let id: String              // e.g. "attractive+funny"
    let name: String            // e.g. "Attractive & Funny"; edit types.json to rename
    let topAttrs: [String]
    let count: Int
    let share: Double           // share of the 452 typed participants
    let revealed: [String: Double]
    let stated: [String: Double]
    let gender: [String: Double]
    let ageMean: Double?
    let field: [String: Double]
    let interests: [String: Double]

    enum CodingKeys: String, CodingKey {
        case id, name, count, share, revealed, stated, gender, field, interests
        case topAttrs = "top_attrs"
        case ageMean = "age_mean"
    }

    var topAttributes: [Attribute] { topAttrs.compactMap(Attribute.init(rawValue:)) }

    /// The two attributes, ordered by this type's average revealed weight
    var rankedTopAttributes: [Attribute] {
        topAttributes.sorted { (revealed[$0.rawValue] ?? 0) > (revealed[$1.rawValue] ?? 0) }
    }

    var summaryText: String {
        let attrs = rankedTopAttributes
        guard attrs.count == 2 else { return "" }
        return TypeInfo.describe(attrs[0], attrs[1])
    }

    static func describe(_ first: Attribute, _ second: Attribute) -> String {
        "Top priority: \(first.label), \(first.blurb). Second: \(second.label), \(second.blurb)."
    }

    var isRare: Bool { share < 0.03 }

    /// The n largest entries, e.g. fields of study or interests
    static func top(_ dict: [String: Double], _ n: Int) -> [(key: String, value: Double)] {
        Array(dict.sorted { $0.value > $1.value }.prefix(n))
    }
}

/// One real participant from participants.json
struct Participant: Codable, Identifiable {
    let id: Int
    let gender: String
    let age: Double?
    let field: String
    let stated: [String: Double?]
    let revealed: [String: Double?]?
    let interests: [String: Double?]
    let type: String?

    var statedWeights: Weights? { Participant.weights(stated) }
    var revealedWeights: Weights? { revealed.flatMap(Participant.weights) }

    private nonisolated static func weights(_ dict: [String: Double?]) -> Weights? {
        var w: Weights = [:]
        for a in Attribute.allCases {
            guard let v = dict[a.rawValue] ?? nil else { return nil }
            w[a] = v
        }
        return w
    }
}
