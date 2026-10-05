import Foundation

/// The six attributes, in the same order as ATTRS in preprocess.ipynb (type ids are built in this order).
enum Attribute: String, CaseIterable, Identifiable, Hashable {
    case attractive
    case sincere
    case intelligent
    case funny
    case ambitious
    case sharedInterests = "shared_interests"

    var id: String { rawValue }

    /// Position in allCases, used for sorting and for building type ids
    nonisolated var order: Int { Attribute.allCases.firstIndex(of: self) ?? 0 }

    var label: String {
        switch self {
        case .attractive: return "Attractive"
        case .sincere: return "Sincere"
        case .intelligent: return "Intelligent"
        case .funny: return "Funny"
        case .ambitious: return "Ambitious"
        case .sharedInterests: return "Shared interests"
        }
    }

    /// Short label for chart axes
    var shortLabel: String {
        switch self {
        case .attractive: return "Looks"
        case .sincere: return "Sincere"
        case .intelligent: return "Smart"
        case .funny: return "Funny"
        case .ambitious: return "Ambition"
        case .sharedInterests: return "Interests"
        }
    }

    /// Full description shown next to the sliders
    var longLabel: String {
        switch self {
        case .attractive: return "Attractive (looks)"
        case .sincere: return "Sincere (honest, trustworthy)"
        case .intelligent: return "Intelligent (smart, well-informed)"
        case .funny: return "Funny (humor, fun to be with)"
        case .ambitious: return "Ambitious (driven, has goals)"
        case .sharedInterests: return "Shared interests (things in common)"
        }
    }

    var symbol: String {
        switch self {
        case .attractive: return "sparkles"
        case .sincere: return "hand.raised.fill"
        case .intelligent: return "brain.head.profile"
        case .funny: return "face.smiling"
        case .ambitious: return "flag.fill"
        case .sharedInterests: return "music.note.list"
        }
    }

    /// One-line description used on the result page
    var blurb: String {
        switch self {
        case .attractive: return "that first spark of attraction matters a lot"
        case .sincere: return "honest, reliable people win you over"
        case .intelligent: return "smart, curious people draw you in"
        case .funny: return "someone who makes you laugh gets a yes"
        case .ambitious: return "people with goals and drive catch your eye"
        case .sharedInterests: return "clicking over the same things matters most"
        }
    }
}

/// Weights for the six attributes, summing to 100
typealias Weights = [Attribute: Double]

extension Dictionary where Key == String, Value == Double {
    /// Converts {"attractive": 22.2, ...} from JSON into Weights
    var asWeights: Weights {
        var w: Weights = [:]
        for a in Attribute.allCases { w[a] = self[a.rawValue] ?? 0 }
        return w
    }
}

enum Labels {
    static let interests: [String: String] = [
        "sports": "Sports", "tvsports": "Watching sports", "exercise": "Exercise", "dining": "Dining out",
        "museums": "Museums", "art": "Art", "hiking": "Hiking", "gaming": "Gaming",
        "clubbing": "Clubbing", "reading": "Reading", "tv": "TV", "theater": "Theater",
        "movies": "Movies", "concerts": "Concerts", "music": "Music", "shopping": "Shopping", "yoga": "Yoga",
    ]

    static let fields: [String: String] = [
        "Business": "Business", "Law": "Law", "STEM": "STEM & Medicine", "Social Science": "Social Science",
        "Arts & Humanities": "Arts & Humanities", "Education": "Education", "Other": "Other",
    ]

    static let genders: [String: String] = ["female": "Women", "male": "Men"]

    static func interest(_ key: String) -> String { interests[key] ?? key }
    static func field(_ key: String) -> String { fields[key] ?? key }
    static func gender(_ key: String) -> String { genders[key] ?? key }
}
