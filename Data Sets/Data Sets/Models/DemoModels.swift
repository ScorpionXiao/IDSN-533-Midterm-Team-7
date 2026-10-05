import Foundation
import Observation

enum DemoStep: Hashable {
    case question
    case quickQuestions
    case analyzing
    case discovery
    case video
    case chat
}

enum PreferredCompanion: String, CaseIterable, Identifiable {
    case woman
    case man

    var id: String { rawValue }

    var title: String {
        switch self {
        case .woman: return "A woman"
        case .man: return "A man"
        }
    }

    var detail: String {
        switch self {
        case .woman: return "Warm, thoughtful energy"
        case .man: return "Playful, magnetic energy"
        }
    }

    var symbol: String {
        switch self {
        case .woman: return "sparkles"
        case .man: return "moon.stars.fill"
        }
    }
}

enum CompanionEnergy: String, CaseIterable, Identifiable {
    case calm
    case playful
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm"
        case .playful: return "Playful"
        case .deep: return "A little deeper"
        }
    }

    var detail: String {
        switch self {
        case .calm: return "Someone who makes the noise disappear"
        case .playful: return "Easy chemistry and unexpected fun"
        case .deep: return "A conversation that forgets the time"
        }
    }

    var symbol: String {
        switch self {
        case .calm: return "moon.stars.fill"
        case .playful: return "sparkles"
        case .deep: return "bubble.left.and.bubble.right.fill"
        }
    }
}

enum PerfectMoment: String, CaseIterable, Identifiable {
    case coffee
    case music
    case city

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coffee: return "Late coffee"
        case .music: return "Music and rain"
        case .city: return "A city walk"
        }
    }

    var detail: String {
        switch self {
        case .coffee: return "Quiet, warm, no rush"
        case .music: return "One song becomes an entire night"
        case .city: return "No plan—just follow the lights"
        }
    }

    var symbol: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .music: return "music.note"
        case .city: return "building.2.fill"
        }
    }
}

struct CompanionCandidate: Identifiable, Hashable {
    let id: String
    let name: String
    let imageName: String
    let headline: String
    let vibe: String
    let isFeaturedMatch: Bool

    static func options(for preference: PreferredCompanion?) -> [CompanionCandidate] {
        if preference == .man {
            return [
                CompanionCandidate(
                    id: "kai",
                    name: "Kai",
                    imageName: "CandidateKai",
                    headline: "Calm focus, quiet confidence",
                    vibe: "Architect · late-night city walks",
                    isFeaturedMatch: false
                ),
                CompanionCandidate(
                    id: "malik",
                    name: "Malik",
                    imageName: "CandidateMalik",
                    headline: "Warm humor with an old-soul playlist",
                    vibe: "Music lover · effortless conversation",
                    isFeaturedMatch: false
                ),
                CompanionCandidate(
                    id: "adrian",
                    name: "Adrian",
                    imageName: "CandidateAdrian",
                    headline: "Curious, composed and unexpectedly romantic",
                    vibe: "Reader · rainy-night energy",
                    isFeaturedMatch: false
                ),
                CompanionCandidate(
                    id: "riven",
                    name: "Riven",
                    imageName: "DiscoveryRiven",
                    headline: "Magnetic energy with a playful edge",
                    vibe: "Your featured signal match",
                    isFeaturedMatch: true
                ),
            ]
        }

        return [
            CompanionCandidate(
                id: "sora",
                name: "Sora",
                imageName: "CandidateSora",
                headline: "Quiet confidence with a curious mind",
                vibe: "Designer · rooftop conversations",
                isFeaturedMatch: false
            ),
            CompanionCandidate(
                id: "amara",
                name: "Amara",
                imageName: "CandidateAmara",
                headline: "Warm, soulful and effortlessly magnetic",
                vibe: "Music lover · vinyl after dark",
                isFeaturedMatch: false
            ),
            CompanionCandidate(
                id: "leila",
                name: "Leila",
                imageName: "CandidateLeila",
                headline: "Creative energy with thoughtful depth",
                vibe: "Artist · notices the little things",
                isFeaturedMatch: false
            ),
            CompanionCandidate(
                id: "victoria",
                name: "Victoria",
                imageName: "DiscoveryVictoria",
                headline: "Thoughtful confidence with a warm spark",
                vibe: "Your featured signal match",
                isFeaturedMatch: true
            ),
        ]
    }
}

struct VirtualCharacter: Identifiable, Hashable {
    let id: String
    let name: String
    let companion: PreferredCompanion
    let discoveryImageName: String
    let profileImageName: String
    let videoName: String
    let headline: String
    let location: String
    let greeting: String
    let replyOptions: [String]
    let replies: [String: String]
    let scores: Weights

    static let victoria = VirtualCharacter(
        id: "victoria",
        name: "Victoria",
        companion: .woman,
        discoveryImageName: "DiscoveryVictoria",
        profileImageName: "VictoriaCharacter",
        videoName: "victoria-heartbeat",
        headline: "Thoughtful confidence with a warm spark",
        location: "Los Angeles · online now",
        greeting: "You made it. I was hoping the signal would lead you here. How is your night going?",
        replyOptions: ["Better now ✨", "A little chaotic", "Tell me about you"],
        replies: [
            "Better now ✨": "That is a dangerously charming answer. I think we are going to get along.",
            "A little chaotic": "Then stay here for a minute. No pressure, no fixing—just tell me what happened.",
            "Tell me about you": "I collect small beautiful moments: quiet galleries, late coffee, and conversations that forget the time. Your turn.",
        ],
        scores: [
            .attractive: 9.0, .sincere: 8.5, .intelligent: 9.2,
            .funny: 7.8, .ambitious: 9.0, .sharedInterests: 8.4,
        ]
    )

    static let riven = VirtualCharacter(
        id: "riven",
        name: "Riven",
        companion: .man,
        discoveryImageName: "DiscoveryRiven",
        profileImageName: "RivenCharacter",
        videoName: "riven-heartbeat",
        headline: "Magnetic energy with a playful edge",
        location: "Los Angeles · online now",
        greeting: "There you are. I had a feeling you would choose the heart. What kind of night are we having?",
        replyOptions: ["Surprise me", "Keep it low-key", "Tell me your secret"],
        replies: [
            "Surprise me": "Bold choice. Give me ten minutes and one song—you can decide if I understood the assignment.",
            "Keep it low-key": "Perfect. Rain outside, music on, nowhere else we need to be.",
            "Tell me your secret": "I act spontaneous, but I remember every tiny detail people tell me. Now you owe me one.",
        ],
        scores: [
            .attractive: 9.2, .sincere: 7.7, .intelligent: 8.3,
            .funny: 8.9, .ambitious: 8.5, .sharedInterests: 8.6,
        ]
    )
}

struct CompanionMatch: Hashable {
    let character: VirtualCharacter
    let type: TypeInfo?
    let score: Int
    let topAttributes: [Attribute]
}

@MainActor
@Observable
final class DemoSession {
    var step: DemoStep = .question
    var preferredCompanion: PreferredCompanion?
    var selectedEnergy: CompanionEnergy?
    var selectedMoment: PerfectMoment?
    private(set) var match: CompanionMatch?
    private(set) var weights: Weights = [:]

    var candidate: VirtualCharacter {
        preferredCompanion == .man ? .riven : .victoria
    }

    func choose(_ preference: PreferredCompanion) {
        preferredCompanion = preference
        step = .quickQuestions
    }

    func finishQuestions(store: DataStore) {
        buildMatch(store: store)
        step = .analyzing
    }

    func likeCandidate() {
        step = .video
    }

    func reset() {
        preferredCompanion = nil
        selectedEnergy = nil
        selectedMoment = nil
        match = nil
        weights = [:]
        step = .question
    }

    private func buildMatch(store: DataStore) {
        let character = candidate

        switch preferredCompanion {
        case .man:
            weights = [
                .attractive: 18, .sincere: 14, .intelligent: 15,
                .funny: 20, .ambitious: 16, .sharedInterests: 17,
            ]
        case .woman, .none:
            weights = [
                .attractive: 16, .sincere: 18, .intelligent: 22,
                .funny: 12, .ambitious: 17, .sharedInterests: 15,
            ]
        }

        switch selectedEnergy {
        case .calm:
            weights[.sincere, default: 0] += 9
            weights[.sharedInterests, default: 0] += 5
        case .playful:
            weights[.funny, default: 0] += 10
            weights[.attractive, default: 0] += 4
        case .deep:
            weights[.intelligent, default: 0] += 9
            weights[.sincere, default: 0] += 5
        case .none:
            break
        }

        switch selectedMoment {
        case .coffee:
            weights[.sincere, default: 0] += 5
            weights[.intelligent, default: 0] += 4
        case .music:
            weights[.funny, default: 0] += 5
            weights[.sharedInterests, default: 0] += 6
        case .city:
            weights[.ambitious, default: 0] += 6
            weights[.attractive, default: 0] += 4
        case .none:
            break
        }

        let total = max(weights.values.reduce(0, +), 1)
        weights = weights.mapValues { $0 / total * 100 }

        let nearestType = store.types.min { first, second in
            distance(from: weights, to: first.revealed.asWeights)
                < distance(from: weights, to: second.revealed.asWeights)
        }

        let weightedScore = Attribute.allCases.reduce(0.0) { partial, attribute in
            partial + (weights[attribute] ?? 0) / 100 * (character.scores[attribute] ?? 0) * 10
        }

        match = CompanionMatch(
            character: character,
            type: nearestType,
            score: min(max(Int(weightedScore.rounded()), 84), 96),
            topAttributes: Array(TypeCalculator.ranked(weights).prefix(3))
        )
    }

    private func distance(from lhs: Weights, to rhs: Weights) -> Double {
        Attribute.allCases.reduce(0) { partial, attribute in
            let delta = (lhs[attribute] ?? 0) - (rhs[attribute] ?? 0)
            return partial + delta * delta
        }.squareRoot()
    }
}
