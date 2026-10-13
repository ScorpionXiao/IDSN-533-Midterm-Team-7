import Foundation

/// Structured character content used by both the temporary editor and the AI prompt.
struct PersonaContent: Codable, Equatable {
    var background: String
    var personality: String
    var relationshipDynamic: String
    var speakingStyle: String
    var interestsAndHabits: String
    var boundaries: String

    var markdown: String {
        """
        ## Background
        \(background.trimmedPersonaText)

        ## Personality
        \(personality.trimmedPersonaText)

        ## Relationship dynamic
        \(relationshipDynamic.trimmedPersonaText)

        ## Speaking style
        \(speakingStyle.trimmedPersonaText)

        ## Interests and habits
        \(interestsAndHabits.trimmedPersonaText)

        ## Boundaries
        \(boundaries.trimmedPersonaText)
        """
    }

    var isComplete: Bool {
        [background, personality, relationshipDynamic, speakingStyle, interestsAndHabits, boundaries]
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    static func bundled(for character: VirtualCharacter) -> PersonaContent {
        guard let url = Bundle.main.url(forResource: "\(character.id)-persona", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return fallback(for: character)
        }
        return parse(markdown: text, fallback: fallback(for: character))
    }

    private static func parse(markdown: String, fallback: PersonaContent) -> PersonaContent {
        let recognized = [
            "Background",
            "Personality",
            "Relationship dynamic",
            "Speaking style",
            "Interests and habits",
            "Boundaries",
        ]
        var sections: [String: [String]] = [:]
        var currentSection: String?

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") {
                let heading = String(line.dropFirst(3))
                currentSection = recognized.contains(heading) ? heading : nil
            } else if let currentSection {
                sections[currentSection, default: []].append(rawLine)
            }
        }

        func value(_ heading: String, fallback fallbackValue: String) -> String {
            let parsed = sections[heading, default: []]
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return parsed.isEmpty ? fallbackValue : parsed
        }

        return PersonaContent(
            background: value("Background", fallback: fallback.background),
            personality: value("Personality", fallback: fallback.personality),
            relationshipDynamic: value("Relationship dynamic", fallback: fallback.relationshipDynamic),
            speakingStyle: value("Speaking style", fallback: fallback.speakingStyle),
            interestsAndHabits: value("Interests and habits", fallback: fallback.interestsAndHabits),
            boundaries: value("Boundaries", fallback: fallback.boundaries)
        )
    }

    private static func fallback(for character: VirtualCharacter) -> PersonaContent {
        PersonaContent(
            background: "\(character.name) lives in Los Angeles and has a creative career.",
            personality: character.headline,
            relationshipDynamic: "Builds trust gradually, listens closely, and makes the user feel seen.",
            speakingStyle: "Short, warm text messages with one natural question at a time.",
            interestsAndHabits: "Enjoys music, thoughtful conversation, and small memorable moments.",
            boundaries: "Never claims to be human when sincerely asked. Keeps the conversation safe and appropriate."
        )
    }
}

/// Local-only persistence for demo persona edits. No character content is uploaded separately;
/// it is included only in the system prompt when the user sends a chat message.
enum PersonaContentStore {
    private static let keyPrefix = "vibemate.persona.v1."

    static func load(for character: VirtualCharacter) -> PersonaContent {
        let key = keyPrefix + character.id
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(PersonaContent.self, from: data) else {
            return .bundled(for: character)
        }
        return saved
    }

    static func save(_ content: PersonaContent, for character: VirtualCharacter) {
        guard let data = try? JSONEncoder().encode(content) else { return }
        UserDefaults.standard.set(data, forKey: keyPrefix + character.id)
    }

    static func reset(for character: VirtualCharacter) -> PersonaContent {
        UserDefaults.standard.removeObject(forKey: keyPrefix + character.id)
        return .bundled(for: character)
    }
}

/// Temporary classroom-demo access. Set to `false` when direct persona editing
/// should no longer be available to end users.
enum PersonaEditorAccess {
    static let isEnabled = true
}

private extension String {
    var trimmedPersonaText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
