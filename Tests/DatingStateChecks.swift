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
        try recommendationChecks(profile: profile, weights: weights, defaults: defaults)
        try affinityChecks()

        print("Passed: 13 character gates, both outcomes, incomplete answers, invitation isolation, thread deduplication, persistence, profile privacy, community storage, recommendation coverage, the hybrid recommender, and affinity.")
    }

    @MainActor
    static func recommendationChecks(profile: DatingProfile, weights: Weights, defaults: UserDefaults) throws {
        let json = """
        [
          {"id": 1, "gender": "male", "age": 22, "field": "Law",
           "stated": {"attractive": 15, "sincere": 20, "intelligent": 20, "funny": 15, "ambitious": 15, "shared_interests": 15},
           "revealed": {"attractive": 30, "sincere": 5, "intelligent": 10, "funny": 30, "ambitious": 5, "shared_interests": 20},
           "interests": {"music": 9, "art": 8, "dining": 7}, "type": null},
          {"id": 2, "gender": "male", "age": 25, "field": "STEM",
           "stated": {"attractive": 40, "sincere": 10, "intelligent": 10, "funny": 10, "ambitious": 20, "shared_interests": 10},
           "revealed": {"attractive": 10, "sincere": 40, "intelligent": 30, "funny": 5, "ambitious": 10, "shared_interests": 5},
           "interests": {"music": 2, "art": 1, "dining": 3}, "type": null},
          {"id": 3, "gender": "female", "age": 23, "field": "Business",
           "stated": {"attractive": 10, "sincere": 30, "intelligent": 20, "funny": 20, "ambitious": 10, "shared_interests": 10},
           "revealed": null,
           "interests": {"music": 5}, "type": null}
        ]
        """
        let participants = try JSONDecoder().decode([Participant].self, from: Data(json.utf8))
        var womanProfile = profile
        womanProfile.preference = "woman"
        womanProfile.interests = ["Music", "Art", "Coffee"]

        let nearest = RecommendationEngine.neighborPrior(weights: weights, profile: womanProfile, participants: participants, k: 1)
        precondition(nearest?.neighborCount == 1 && nearest?.poolSize == 2, "Only men with revealed weights rate women")
        precondition(nearest?.topAttributes.contains(.funny) == true, "The closest participant should be the music-loving one")

        let women = VirtualCharacter.allCharacters.filter { $0.companion == .woman }
        let prior = RecommendationEngine.neighborPrior(weights: weights, profile: womanProfile, participants: participants)
        let ranked = RecommendationEngine.rank(women, profile: womanProfile, baseWeights: weights, signals: RecommendationSignals(), prior: prior)
        precondition(ranked.count == women.count, "Every character is ranked")
        precondition(zip(ranked, ranked.dropFirst()).allSatisfy { $0.rankValue >= $1.rankValue }, "Ranking is sorted")
        precondition(ranked.allSatisfy { (60...98).contains($0.score) && !$0.reason.isEmpty }, "Scores stay in range and explain themselves")

        var signals = RecommendationSignals()
        let before = ranked.first { $0.id == "lily" }!.personalScore
        RecommendationEngine.update(&signals, toward: .lily, in: women, rate: RecommendationEngine.likeRate)
        let after = RecommendationEngine.rank(women, profile: womanProfile, baseWeights: weights, signals: signals, prior: prior)
            .first { $0.id == "lily" }!.personalScore
        precondition(after > before, "Liking a character raises similar characters")
        for _ in 0..<20 { RecommendationEngine.update(&signals, toward: .lily, in: women, rate: RecommendationEngine.likeRate) }
        precondition(signals.weightDeltas.values.allSatisfy { abs($0) <= RecommendationEngine.maxDelta }, "Learning is capped")

        let means = RecommendationEngine.poolMeans(women)
        let closest = women.filter { $0.id != "victoria" }
            .max { RecommendationEngine.similarity(.victoria, $0, means: means) < RecommendationEngine.similarity(.victoria, $1, means: means) }!
        var passSignals = RecommendationSignals()
        passSignals.passed = ["victoria"]
        let afterPass = RecommendationEngine.rank(women, profile: womanProfile, baseWeights: weights, signals: passSignals, prior: prior)
        precondition(afterPass.first { $0.id == closest.id }!.rankValue < ranked.first { $0.id == closest.id }!.rankValue, "Passing lowers similar characters")
        var likeSignals = RecommendationSignals()
        likeSignals.liked = ["victoria"]
        let afterLike = RecommendationEngine.rank(women, profile: womanProfile, baseWeights: weights, signals: likeSignals, prior: prior)
        precondition(afterLike.first { $0.id == closest.id }!.rankValue > ranked.first { $0.id == closest.id }!.rankValue, "Liking raises similar characters")

        var deckSignals = RecommendationSignals()
        deckSignals.passed = [ranked[0].id]
        let deck = RecommendationEngine.deckOrder(ranked, signals: deckSignals, connected: [ranked[1].id])
        precondition(deck.count == women.count, "The deck keeps every character")
        precondition(deck.last?.id == ranked[1].id, "Existing connections go last")
        precondition(deck[deck.count - 2].id == ranked[0].id, "Passed profiles come after fresh ones")

        let state = DatingAppState(defaults: defaults)
        state.resetRecommendationLearning()
        state.recordPass(.victoria)
        state.recordLike(.lily)
        state.recordLike(.lily)
        let restored = DatingAppState(defaults: defaults)
        precondition(restored.signals.passed == ["victoria"] && restored.signals.liked == ["lily"], "Signals survive relaunch without duplicates")
        precondition(restored.snapshot.conversations.count == state.snapshot.conversations.count, "Signals do not touch saved conversations")
    }

    @MainActor
    static func affinityChecks() throws {
        precondition((0...2).allSatisfy { AffinityRules.initial(answerTotal: $0) < AffinityRules.unlockThreshold }, "Weak answers start locked")
        precondition((3...4).allSatisfy { AffinityRules.initial(answerTotal: $0) >= AffinityRules.unlockThreshold }, "Matching answers start unlocked")
        precondition(AffinityRules.apply(50, to: 10) == 20 && AffinityRules.apply(-50, to: 3) == 0 && AffinityRules.apply(9, to: 98) == 100, "Changes are clamped")

        let suite = "vibemate.affinity.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = DatingAppState(defaults: defaults)
        state.accept(.vivian, affinity: 30)
        precondition(state.conversation(for: "vivian")?.isVideoLocked == true, "Low affinity keeps the video locked")
        precondition(state.applyAffinity(10, for: .vivian)?.unlockedNow == false)
        precondition(state.applyAffinity(10, for: .vivian)?.unlockedNow == false)
        precondition(state.applyAffinity(10, for: .vivian)?.unlockedNow == true, "Reaching the threshold unlocks once")
        precondition(state.applyAffinity(-5, for: .vivian)?.unlockedNow == false, "Unlocking happens only once")
        precondition(DatingAppState(defaults: defaults).conversation(for: "vivian")?.videoUnlocked == true, "Unlock survives relaunch")
        precondition(state.applyAffinity(5, for: .lily) == nil, "No conversation, no affinity")

        let legacy = Data(#"{"characterID":"riven","messages":[],"updatedAt":0,"unread":false}"#.utf8)
        let decoded = try JSONDecoder().decode(DatingConversation.self, from: legacy)
        precondition(decoded.videoUnlocked && decoded.affinity == AffinityRules.unlockThreshold, "Older conversations stay unlocked")

        var snapshot = DatingSnapshot()
        snapshot.invitations = [PendingInvitation(characterID: "loid", createdAt: Date(), answers: ["A", "B"])]
        defaults.set(try JSONEncoder().encode(snapshot), forKey: "vibemate.dating.v2")
        let migrated = DatingAppState(defaults: defaults)
        precondition(migrated.snapshot.invitations.isEmpty, "Pending invitations are migrated")
        precondition(migrated.conversation(for: "loid")?.isVideoLocked == true, "Migrated invitations become low-affinity chats")
    }
}
