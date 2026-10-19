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
    let character: VirtualCharacter
    var id: String { character.id }
    var name: String { character.name }
    var imageName: String { character.discoveryImageName }
    var headline: String { character.headline }
    var vibe: String { character.tags.joined(separator: " · ") }
    var isFeaturedMatch: Bool { character.id == "victoria" || character.id == "riven" }

    static func options(for preference: PreferredCompanion?) -> [CompanionCandidate] {
        VirtualCharacter.collection(for: preference ?? .woman).map { CompanionCandidate(character: $0) }
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

    // MARK: Expanded female character collection

    static let vivian = catalogCharacter(
        id: "vivian",
        name: "Vivian",
        companion: .woman,
        imageName: "CandidateVivian",
        videoName: "vivian-heartbeat",
        headline: "Bookish warmth with a quietly fearless heart",
        location: "Los Angeles · in the stacks",
        greeting: "You found me between chapters. Tell me—what kind of story has your attention tonight?",
        signature: "I notice the sentence people almost say. Books just taught me how to wait for it.",
        scores: [.attractive: 8.4, .sincere: 9.3, .intelligent: 9.4, .funny: 7.2, .ambitious: 8.1, .sharedInterests: 8.8]
    )

    static let lily = catalogCharacter(
        id: "lily",
        name: "Lily",
        companion: .woman,
        imageName: "CandidateLily",
        videoName: "lily-heartbeat",
        headline: "Bright curiosity with an otherworldly spark",
        location: "Neon City · online now",
        greeting: "Hi—you actually stayed. Good. I have about a hundred questions, but you can choose the first one.",
        signature: "I make strange things feel easy and ordinary nights feel a little impossible.",
        scores: [.attractive: 8.9, .sincere: 8.6, .intelligent: 8.7, .funny: 9.4, .ambitious: 7.9, .sharedInterests: 8.8]
    )

    static let selene = catalogCharacter(
        id: "selene",
        name: "Selene",
        companion: .woman,
        imageName: "CandidateSelene",
        videoName: "selene-pv",
        headline: "Mystic calm, sharp intuition, hidden tenderness",
        location: "Lunaris · after dusk",
        greeting: "The crystal was quieter before you arrived. I am taking that as a good sign—what are you hoping to find?",
        signature: "Mystery is more interesting when it reveals something true instead of hiding it.",
        scores: [.attractive: 9.2, .sincere: 8.1, .intelligent: 9.5, .funny: 6.8, .ambitious: 8.7, .sharedInterests: 8.0]
    )

    static let charlie = catalogCharacter(
        id: "charlie",
        name: "Charlie",
        companion: .woman,
        imageName: "CandidateCharlie",
        videoName: "charlie-pv",
        headline: "Radiant optimism that refuses to give up on you",
        location: "Pentagram City · always welcoming",
        greeting: "Okay, this is exciting. I promise not to overwhelm you—but I really want to know what made you smile today.",
        signature: "I believe hope works best when it comes with a plan and someone willing to stay.",
        scores: [.attractive: 8.5, .sincere: 9.7, .intelligent: 8.2, .funny: 8.7, .ambitious: 9.1, .sharedInterests: 8.4]
    )

    static let vaggie = catalogCharacter(
        id: "vaggie",
        name: "Vaggie",
        companion: .woman,
        imageName: "CandidateVaggie",
        videoName: "vaggie-pv",
        headline: "Protective honesty with a fiercely loyal core",
        location: "Pentagram City · keeping watch",
        greeting: "You made it. I respect that. Just be honest with me and we will get along—what is on your mind?",
        signature: "I am not interested in perfect answers. I care whether you mean them.",
        scores: [.attractive: 8.4, .sincere: 9.6, .intelligent: 8.8, .funny: 6.9, .ambitious: 9.0, .sharedInterests: 7.8]
    )

    // MARK: Expanded male character collection

    static let loid = catalogCharacter(
        id: "loid",
        name: "Loid",
        companion: .man,
        imageName: "CandidateLoid",
        videoName: "loid-pv",
        headline: "Controlled intensity with a protective instinct",
        location: "Midnight District · nearby",
        greeting: "The rain usually keeps people away. You do not seem easily discouraged—should I be impressed or concerned?",
        signature: "I plan for every possibility, except the rare person who makes me forget the plan.",
        scores: [.attractive: 9.3, .sincere: 8.0, .intelligent: 9.4, .funny: 7.1, .ambitious: 9.2, .sharedInterests: 8.0]
    )

    static let dorian = catalogCharacter(
        id: "dorian",
        name: "Dorian",
        companion: .man,
        imageName: "CandidateDorian",
        videoName: "dorian-pv",
        headline: "Dark elegance, direct attention, old-soul gravity",
        location: "Los Angeles · after hours",
        greeting: "Most people fill silence because it unsettles them. You do not have to. What would you rather talk about?",
        signature: "I prefer one honest conversation to a room full of impressive ones.",
        scores: [.attractive: 9.5, .sincere: 7.9, .intelligent: 9.0, .funny: 7.3, .ambitious: 8.8, .sharedInterests: 8.2]
    )

    static let nightwing = catalogCharacter(
        id: "nightwing",
        name: "Nightwing",
        companion: .man,
        imageName: "CandidateNightwing",
        videoName: "nightwing-pv",
        headline: "Heroic confidence with an easy, human smile",
        location: "Blüdhaven · on patrol",
        greeting: "Good timing—I was about to take the scenic route across the city. What kind of trouble are we avoiding tonight?",
        signature: "I take the work seriously. Myself? Only when absolutely necessary.",
        scores: [.attractive: 9.1, .sincere: 9.0, .intelligent: 8.6, .funny: 9.1, .ambitious: 8.8, .sharedInterests: 8.5]
    )

    static let angel = catalogCharacter(
        id: "angel",
        name: "Angel",
        companion: .man,
        imageName: "CandidateAngel",
        videoName: "angel-pv",
        headline: "Spotlight energy with softness behind the jokes",
        location: "Pentagram City · center stage",
        greeting: "Well, look who wandered into my spotlight. Relax—I only bite bad conversation. What have you got for me?",
        signature: "The jokes arrive first. The honest answer takes a little longer, but it is worth waiting for.",
        scores: [.attractive: 9.2, .sincere: 7.8, .intelligent: 8.1, .funny: 9.7, .ambitious: 8.0, .sharedInterests: 8.7]
    )

    static let joon = catalogCharacter(
        id: "joon",
        name: "Joon",
        companion: .man,
        imageName: "CandidateJoon",
        videoName: "joon-pv",
        headline: "Understated elegance and quietly playful confidence",
        location: "Seoul · between meetings",
        greeting: "I escaped a very formal evening for five quiet minutes. Tell me something worth staying late for.",
        signature: "I like people who can laugh softly and still say exactly what they mean.",
        scores: [.attractive: 9.0, .sincere: 8.7, .intelligent: 8.9, .funny: 8.0, .ambitious: 9.1, .sharedInterests: 8.3]
    )

    static let alastor = catalogCharacter(
        id: "alastor",
        name: "Alastor",
        companion: .man,
        imageName: "CandidateAlastor",
        videoName: "alastor-pv",
        headline: "Vintage theatrical charm with razor-sharp wit",
        location: "Pentagram City · on air",
        greeting: "Ah, a new voice in the audience. Let us make this interesting—what sort of conversation keeps you listening?",
        signature: "Good manners sharpen a dangerous sense of humor; they do not soften it.",
        scores: [.attractive: 8.3, .sincere: 6.9, .intelligent: 9.5, .funny: 9.3, .ambitious: 9.0, .sharedInterests: 7.8]
    )

    private static func catalogCharacter(
        id: String,
        name: String,
        companion: PreferredCompanion,
        imageName: String,
        videoName: String,
        headline: String,
        location: String,
        greeting: String,
        signature: String,
        scores: Weights
    ) -> VirtualCharacter {
        let options = ["Tell me about you", "Set the scene", "Why did we match?"]
        return VirtualCharacter(
            id: id,
            name: name,
            companion: companion,
            discoveryImageName: imageName,
            profileImageName: imageName,
            videoName: videoName,
            headline: headline,
            location: location,
            greeting: greeting,
            replyOptions: options,
            replies: [
                options[0]: signature,
                options[1]: "Picture the right music, nowhere we need to rush to, and a conversation that gets better after midnight.",
                options[2]: "Your answers pointed toward someone with my kind of energy. The data made the introduction; we decide whether it was right.",
            ],
            scores: scores
        )
    }
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

    /// A score from RecommendationEngine keeps the chat in step with the number shown on the card.
    func likeCandidate(_ character: VirtualCharacter, profile: DatingProfile? = nil, score: Int? = nil) {
        let currentMatch = match
        let weightedScore = Attribute.allCases.reduce(0.0) { partial, attribute in
            partial + (weights[attribute] ?? 0) / 100 * (character.scores[attribute] ?? 0) * 10
        }
        match = CompanionMatch(
            character: character,
            type: currentMatch?.type,
            score: score
                ?? profile.map { CompatibilityEngine.score(character, profile: $0, weights: weights) }
                ?? min(max(Int(weightedScore.rounded()), 0), 100),
            topAttributes: currentMatch?.topAttributes ?? Array(TypeCalculator.ranked(weights).prefix(3))
        )
        step = .video
    }

    func applyProfile(_ profile: DatingProfile, store: DataStore) {
        preferredCompanion = PreferredCompanion(rawValue: profile.preference) ?? .woman
        selectedEnergy = CompanionEnergy(rawValue: profile.energy) ?? .calm
        selectedMoment = PerfectMoment(rawValue: profile.moment) ?? .coffee
        buildMatch(store: store)
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
