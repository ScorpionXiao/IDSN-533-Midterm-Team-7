import Foundation

@main
struct DatingStateChecks {
    @MainActor
    static func main() throws {
        let suite = "vibemate.checks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = DatingAppState(defaults: defaults)

        for character in VirtualCharacter.allCharacters {
            let questions = ChemistryQuestions.forCharacter(character)
            precondition(questions.count == 2, "Every character needs two questions")
            let aligned = questions.map { $0.options.first { $0.affinity == 2 }! }
            let conflicting = questions.map { $0.options.first { $0.affinity == 0 }! }
            precondition(CompatibilityEngine.chemistryMatches(aligned), "Aligned answers must match")
            precondition(!CompatibilityEngine.chemistryMatches(conflicting), "Conflicting answers must wait")
            precondition(!CompatibilityEngine.chemistryMatches(Array(aligned.prefix(1))), "Incomplete answers cannot match")
        }

        state.completeOnboarding(preference: .man, energy: .playful, moment: .music)
        var profile = state.profile
        profile.name = "Persistence check"
        profile.avatarData = Data([1, 2, 3])
        profile.communication = "Direct"
        state.updateProfile(profile)
        precondition(!profile.chatContext.contains("avatar"), "Avatar must not be sent in chat context")

        state.waitForReply(from: .riven, answers: ["A", "B"])
        state.waitForReply(from: .riven, answers: ["C", "D"])
        precondition(state.snapshot.invitations.count == 1, "Invitations must not duplicate")
        precondition(state.conversation(for: "riven") == nil, "Pending invites must not unlock chat")
        state.accept(.riven)
        state.accept(.riven)
        precondition(state.snapshot.invitations.isEmpty, "Matching clears an old invitation")
        precondition(state.snapshot.conversations.count == 1, "Matching cannot create duplicate threads")
        precondition(state.unreadCount == 1)

        let message = DemoChatMessage(text: "A message that survives relaunch", kind: .user)
        state.saveMessages([message], for: .riven)
        state.markRead("riven")
        state.accept(.victoria)
        state.toggleLike("victoria")
        state.comment("A saved comment", on: "victoria")
        state.comment("   ", on: "victoria")

        let restored = DatingAppState(defaults: defaults)
        precondition(restored.profile == profile, "Profile and avatar must survive relaunch")
        precondition(restored.conversation(for: "riven")?.messages == [message], "History and IDs must survive relaunch")
        precondition(restored.conversation(for: "victoria")?.messages.first?.text == VirtualCharacter.victoria.greeting)
        precondition(restored.conversation(for: "riven")?.unread == false)
        precondition(restored.snapshot.likedPosts.contains("victoria"))
        precondition(restored.snapshot.comments["victoria"]?.count == 1)

        let weights: Weights = [.attractive: 16, .sincere: 18, .intelligent: 22, .funny: 12, .ambitious: 17, .sharedInterests: 15]
        let session = DemoSession()
        session.likeCandidate(.riven, profile: profile)
        precondition(session.step == .video)
        precondition(session.match?.score == CompatibilityEngine.score(.riven, profile: profile, weights: session.weights))
        for energy in CompanionEnergy.allCases {
            for style in ["Thoughtful", "Playful", "Direct"] {
                var candidateProfile = profile
                candidateProfile.energy = energy.rawValue
                candidateProfile.communication = style
                for preference in PreferredCompanion.allCases {
                    let pool = VirtualCharacter.allCharacters.filter { $0.companion == preference }
                    let recommended = CompatibilityEngine.recommendations(from: pool, profile: candidateProfile, weights: weights)
                    precondition(!recommended.isEmpty, "Every preference combination should have eligible recommendations")
                    precondition(recommended.allSatisfy { CompatibilityEngine.score($0, profile: candidateProfile, weights: weights) >= 80 })
                }
            }
        }
        print("Passed: 13 character gates, both outcomes, incomplete answers, invitation isolation, thread deduplication, persistence, profile privacy, community storage, and recommendation coverage.")
    }
}
