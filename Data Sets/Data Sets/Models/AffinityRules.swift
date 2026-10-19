import Foundation

/// Affinity (0-100) is how warm a character feels toward the user.
/// The app owns the number and its rules; the chat model only suggests a small
/// change for each message, which is clamped here so no single message can jump it.
enum AffinityRules {
    static let range = 0...100
    static let unlockThreshold = 60
    static let deltaRange = -5...10
    /// A direct "Like back" from Likes you starts warm and unlocks the video.
    static let likesYouStart = 70

    /// Starting affinity from the two chemistry answers (each option is worth 0, 1, or 2).
    /// Totals of 3 or more match as before and start unlocked.
    static func initial(answerTotal: Int) -> Int {
        switch answerTotal {
        case ..<1: return 15
        case 1: return 30
        case 2: return 45
        case 3: return 65
        default: return 80
        }
    }

    static func clampedDelta(_ delta: Int) -> Int {
        min(deltaRange.upperBound, max(deltaRange.lowerBound, delta))
    }

    static func apply(_ delta: Int, to affinity: Int) -> Int {
        min(range.upperBound, max(range.lowerBound, affinity + clampedDelta(delta)))
    }

    /// Used when there is no API key or the rating request fails, so the demo can still progress.
    static func fallbackDelta(for message: String) -> Int {
        let words = message.split { $0.isWhitespace }.count
        let characters = message.trimmingCharacters(in: .whitespacesAndNewlines).count
        return words >= 4 || characters >= 12 ? 4 : 2
    }

    /// How the character should sound at this affinity, added to the system prompt.
    static func toneGuide(for affinity: Int) -> String {
        switch affinity {
        case ..<30: return "You are polite but guarded and a little distant. Short answers; the user has to earn your interest."
        case ..<unlockThreshold: return "You are warming up: curious and friendly, but still holding something back."
        case ..<80: return "You feel a real connection: warm, open, and a little flirtatious in a classroom-appropriate way."
        default: return "You are clearly fond of the user: affectionate, playful, and personal, while staying appropriate."
        }
    }
}

/// The chat model's verdict on one user message.
struct AffinityJudgement: Equatable {
    let delta: Int
    let reason: String
}
