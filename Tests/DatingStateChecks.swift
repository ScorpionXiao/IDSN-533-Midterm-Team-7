import Foundation

@main
struct DatingStateChecks {
    @MainActor
    static func main() throws {
        let suite = "vibemate.checks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = DatingAppState(defaults: defaults)
        profileSetupChecks()
        momentFeedChecks()
        for (input, expected) in [("18", 18), ("24", 24), ("100", 100), (" ２８ ", 28)] {
            precondition(ProfileAge.parse(input) == expected, "Typed ages should support whole numbers and full-width IME digits")
        }
        for input in ["", " ", "17", "101", "9999", "-24", "24.5", "twenty", "2a4", "2 4"] {
            precondition(ProfileAge.parse(input) == nil, "Invalid age must not be saved")
        }
        precondition(!state.isSignedIn, "A fresh installation must start at sign-in")
        for invalid in ["", " ", "alex", "alex@", "@example.com", "alex@example", "alex@.com", "a b@example.com", "a@@b.com"] {
            precondition(!state.signIn(email: invalid), "Invalid demo email accepted")
        }
        precondition(state.signIn(email: "  Alex@Example.com  "))
        precondition(state.sessionEmail == "alex@example.com", "Demo sign-in must trim and normalize")
        precondition(DatingAppState(defaults: defaults).isSignedIn, "Demo session should survive relaunch")
        precondition(state.signIn(email: " Ａｌｅｘ＠Ｅｘａｍｐｌｅ．ｃｏｍ "))
        precondition(state.sessionEmail == "alex@example.com", "Full-width IME email characters must normalize")
        precondition(DemoSignIn.isValidEmail("alex+class@example.com"))
        precondition(MomentCatalog.posts.count == 39, "Every character needs three curated moments")
        precondition(Set(MomentCatalog.posts.map(\.id)).count == 39, "Post IDs must be unique")
        precondition(Set(MomentCatalog.posts.map(\.imageName)).count == 39, "Every post needs its own generated image")

        for character in VirtualCharacter.allCharacters {
            let moments = MomentCatalog.recent(for: character.id)
            precondition(moments.count == 3)
            precondition(moments.allSatisfy { $0.character?.id == character.id && !$0.caption.isEmpty && !$0.location.isEmpty })
            precondition(moments.map(\.hoursAgo) == moments.map(\.hoursAgo).sorted())
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
        precondition(!restored.snapshot.likedPosts.contains("victoria"), "Legacy post key should be migrated")
        precondition(restored.snapshot.comments["victoria-1"]?.count == 1, "Older post comments must carry forward")
        precondition(restored.snapshot.likedPosts.contains("victoria-1"), "Older post likes must carry forward")
        restored.toggleLike("victoria-1")
        precondition(!DatingAppState(defaults: defaults).snapshot.likedPosts.contains("victoria-1"), "Migration must not resurrect an unliked post")
        restored.toggleLike("victoria-2")
        restored.comment("A different moment", on: "victoria-2")
        precondition(restored.snapshot.comments["victoria-1"]?.count == 1, "New posts must not share a comment thread")
        restored.leaveIntroduction("   ", for: .joon)
        precondition(restored.conversation(for: "joon") == nil, "Empty notes must not create a connection")
        restored.leaveIntroduction("  Your museum photo caught my eye.  ", for: .joon)
        let introduction = restored.conversation(for: "joon")!
        precondition(introduction.affinity == 30 && !introduction.videoUnlocked, "A note must not bypass video unlock rules")
        precondition(!introduction.unread, "The user's own note must not create an unread notification")
        precondition(introduction.messages.last?.text == "Your museum photo caught my eye.")
        restored.leaveIntroduction("A second hello", for: .joon)
        precondition(restored.snapshot.conversations.filter { $0.characterID == "joon" }.count == 1)
        restored.recordSuperLike(.loid)
        precondition(restored.signals.liked.contains("loid") && restored.superLikedIDs.contains("loid"))
        precondition(restored.conversation(for: "loid") == nil, "Super like must not fabricate a match")
        let reloaded = DatingAppState(defaults: defaults)
        precondition(reloaded.superLikedIDs.contains("loid"), "Super likes must survive relaunch")
        precondition(reloaded.conversation(for: "joon")?.messages.last?.text == "A second hello")
        reloaded.signOut()
        precondition(!reloaded.isSignedIn)
        precondition(reloaded.profile == profile && reloaded.conversation(for: "riven") != nil, "Sign-out must preserve local data")
        precondition(!DatingAppState(defaults: defaults).isSignedIn, "Signed-out session must stay signed out")

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
                    let pool = VirtualCharacter.allCharacters.filter { preference.includes($0) }
                    let recommended = CompatibilityEngine.recommendations(from: pool, profile: candidateProfile, weights: weights)
                    precondition(!recommended.isEmpty, "Every preference combination should have eligible recommendations")
                    precondition(recommended.allSatisfy { CompatibilityEngine.score($0, profile: candidateProfile, weights: weights) >= 80 })
                }
            }
        }
        try recommendationChecks(profile: profile, weights: weights, defaults: defaults)
        try affinityChecks()
        precondition(VirtualCharacter.allCharacters.filter { PreferredCompanion.both.includes($0) }.count == 13)
        precondition(!PreferredCompanion.woman.includes(.riven) && !PreferredCompanion.man.includes(.victoria))

        print("Passed: login/profile confirmation and resume, disjoint personalized/discovery Moments, Both collections/dataset pools, three connection routes, fixed non-refilling cohorts, pending persistence/migration, IME email normalization, profile/history persistence, hybrid ranking, and affinity/video unlock.")
    }

    @MainActor
    static func profileSetupChecks() {
        let suite = "vibemate.setup.checks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = DatingAppState(defaults: defaults)
        precondition(state.needsProfileSetup)
        precondition(state.signIn(email: "demo@example.com") && state.needsProfileSetup)
        var profile = state.profile
        profile.name = "Saved Alex"
        profile.avatarData = Data([7, 8, 9])
        profile.preference = "both"
        profile.communication = "Direct"
        profile.hasOnboarded = true
        state.finishProfileSetup(profile)
        state.accept(.riven)
        let messages = state.conversation(for: "riven")!.messages
        precondition(!state.needsProfileSetup)
        let reloaded = DatingAppState(defaults: defaults)
        precondition(reloaded.isSignedIn && !reloaded.needsProfileSetup, "Ordinary relaunch must not repeat setup")
        reloaded.signOut()
        precondition(!reloaded.signIn(email: "invalid") && !reloaded.requiresProfileSetup, "Invalid login must not mutate setup state")
        precondition(reloaded.signIn(email: "demo@example.com") && reloaded.needsProfileSetup, "Explicit login must confirm an existing profile")
        precondition(reloaded.profile == profile, "Login must prefill, not clear, existing details")
        let interrupted = DatingAppState(defaults: defaults)
        precondition(interrupted.needsProfileSetup, "Interrupted setup must resume on relaunch")
        interrupted.finishProfileSetup(interrupted.profile)
        precondition(!DatingAppState(defaults: defaults).needsProfileSetup)
        precondition(interrupted.conversation(for: "riven")?.messages == messages, "Setup must not erase conversation history")
        defaults.removeObject(forKey: "vibemate.profile.setup.required.v1")
        let upgraded = DatingAppState(defaults: defaults)
        precondition(upgraded.needsProfileSetup && upgraded.profile == profile, "Older installations should confirm once without data loss")
        upgraded.finishProfileSetup(upgraded.profile)
        precondition(!DatingAppState(defaults: defaults).needsProfileSetup, "Upgrade confirmation must not repeat")
    }

    static func momentFeedChecks() {
        let ids = VirtualCharacter.allCharacters.map(\.id)
        let fresh = MomentFeedPolicy.select(rankedIDs: ids, connectedIDs: [], interestedIDs: [], passedIDs: [])
        precondition(fresh.forYouIDs.count == 3 && fresh.exploreIDs.count == 10)
        precondition(Set(fresh.forYouIDs).isDisjoint(with: fresh.exploreIDs), "Both must not produce identical feeds")
        precondition(Set(fresh.forYouIDs + fresh.exploreIDs) == Set(ids))
        let personalized = MomentFeedPolicy.select(rankedIDs: ids + ids, connectedIDs: ["riven", "riven", "missing"],
                                                  interestedIDs: ["victoria", "missing"], passedIDs: ["loid"])
        precondition(personalized.forYouIDs.first == "riven" && personalized.forYouIDs.contains("victoria"))
        precondition(!personalized.forYouIDs.contains("loid") && !personalized.exploreIDs.contains("loid"))
        precondition(Set(personalized.forYouIDs).isDisjoint(with: personalized.exploreIDs))
        precondition(Set(personalized.forYouIDs + personalized.exploreIDs).count == 12, "Invalid/duplicate IDs and passes must be handled")
        let forYouPosts = MomentCatalog.feed(authorIDs: personalized.forYouIDs)
        let explorePosts = MomentCatalog.feed(authorIDs: personalized.exploreIDs)
        precondition(Set(forYouPosts.map(\.id)).isDisjoint(with: explorePosts.map(\.id)), "Posts must not duplicate across feeds")
        precondition(forYouPosts.first?.characterID == "riven", "Related authors break chronological ties first")
        let women = VirtualCharacter.collection(for: .woman).map(\.id)
        let filtered = MomentFeedPolicy.select(rankedIDs: women, connectedIDs: ["riven"], interestedIDs: ["loid"], passedIDs: [])
        precondition(filtered.forYouIDs.contains("riven"), "Existing connections survive preference changes")
        precondition(!filtered.forYouIDs.contains("loid") && filtered.exploreIDs.allSatisfy { women.contains($0) }, "New recommendations respect preference")
        let allConnected = MomentFeedPolicy.select(rankedIDs: ids, connectedIDs: ids, interestedIDs: [], passedIDs: [])
        precondition(allConnected.exploreIDs.isEmpty, "Exhausted Explore must show an empty state, not duplicate For you")
        let empty = MomentFeedPolicy.select(rankedIDs: [], connectedIDs: [], interestedIDs: [], passedIDs: [])
        precondition(empty.forYouIDs.isEmpty && empty.exploreIDs.isEmpty)
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
        precondition(ranked.allSatisfy { (25...95).contains($0.score) && !$0.reason.isEmpty }, "Fit indices stay in range and explain themselves")
        precondition(RecommendationEngine.displayedFit(for: 40) == 55)
        precondition(RecommendationEngine.displayedFit(for: 60) == 70)
        precondition(RecommendationEngine.displayedFit(for: -100) == 25 && RecommendationEngine.displayedFit(for: 200) == 95)
        let connected = Set([ranked[0].id])
        let incoming = CharacterConnectionPolicy.incomingLikes(from: ranked, excluding: connected)
        let incomingIDs = Set(incoming.map(\.id))
        precondition(incoming.count == 1 && !incomingIDs.contains(ranked[0].id), "Only a small subset should be incoming likes")
        for item in incoming {
            precondition(CharacterConnectionPolicy.route(characterID: item.id, hasConversation: false, incomingIDs: incomingIDs) == .instantMatch, "A character in Likes you must skip questions from every entrance")
            precondition(CharacterConnectionPolicy.route(characterID: item.id, hasConversation: true, incomingIDs: incomingIDs) == .existingChat, "Existing chat and its affinity must be preserved")
        }
        let ordinary = ranked.first { !incomingIDs.contains($0.id) && !connected.contains($0.id) }!
        precondition(CharacterConnectionPolicy.route(characterID: ordinary.id, hasConversation: false, incomingIDs: incomingIDs) == .chemistry, "Other characters still need the chemistry check")
        precondition(CharacterConnectionPolicy.route(characterID: "unknown", hasConversation: false, incomingIDs: []) == .chemistry, "An empty incoming list must not fabricate a direct match")
        precondition(CharacterConnectionPolicy.route(characterID: "vivian", hasConversation: false, incomingIDs: [], waitingIDs: ["vivian"]) == .awaitingReply)
        precondition(CharacterConnectionPolicy.route(characterID: "vivian", hasConversation: false, incomingIDs: ["vivian"], hasPendingReply: true) == .awaitingReply, "A saved pending reply must not turn into an instant match")
        precondition(CharacterConnectionPolicy.route(characterID: "vivian", hasConversation: true, incomingIDs: [], waitingIDs: ["vivian"]) == .existingChat)
        let cohortSuite = "vibemate.cohort.checks.\(UUID().uuidString)"
        let cohortDefaults = UserDefaults(suiteName: cohortSuite)!
        defer { cohortDefaults.removePersistentDomain(forName: cohortSuite) }
        let cohortState = DatingAppState(defaults: cohortDefaults)
        cohortState.updateProfile(womanProfile)
        let cohort = cohortState.connectionCohort(from: ranked)
        precondition(cohort.incomingIDs.count == 1 && cohort.waitingIDs.count == 1)
        precondition(Set(cohort.incomingIDs).isDisjoint(with: Set(cohort.waitingIDs)))
        precondition(women.count - cohort.incomingIDs.count - cohort.waitingIDs.count >= 4, "Most profiles must retain their question route")
        let bothRanked = RecommendationEngine.rank(VirtualCharacter.allCharacters, profile: womanProfile, baseWeights: weights, signals: RecommendationSignals(), prior: prior)
        let bothCohort = CharacterConnectionPolicy.makeCohort(from: bothRanked, excluding: [])
        precondition(bothCohort.incomingIDs.count == 2 && bothCohort.waitingIDs.count == 3)
        precondition(13 - bothCohort.incomingIDs.count - bothCohort.waitingIDs.count == 8, "Both keeps eight chemistry profiles")
        cohortState.accept(VirtualCharacter.find(cohort.incomingIDs[0])!)
        let restoredCohort = DatingAppState(defaults: cohortDefaults)
        precondition(restoredCohort.connectionCohort(from: Array(ranked.reversed())) == cohort, "Used incoming likes must never be backfilled on re-ranking or relaunch")
        let pendingCharacter = women.first { $0.id != cohort.incomingIDs[0] }!
        restoredCohort.awaitCharacterReply(pendingCharacter)
        restoredCohort.awaitCharacterReply(pendingCharacter)
        precondition(restoredCohort.snapshot.invitations.filter { $0.characterID == pendingCharacter.id }.count == 1)
        precondition(restoredCohort.conversation(for: pendingCharacter.id) == nil, "Waiting notice must not create a conversation")
        let pendingRestored = DatingAppState(defaults: cohortDefaults)
        precondition(pendingRestored.snapshot.invitations.contains { $0.characterID == pendingCharacter.id && $0.waitsForReply == true })
        precondition(pendingRestored.conversation(for: pendingCharacter.id) == nil, "New pending replies must survive the legacy migration")
        pendingRestored.accept(pendingCharacter, affinity: 30)
        precondition(!pendingRestored.snapshot.invitations.contains { $0.characterID == pendingCharacter.id })
        let source = participants[0]
        let female = Participant(id: 99, gender: "female", age: source.age, field: source.field,
                                 stated: source.stated, revealed: source.revealed, interests: source.interests, type: nil)
        var bothProfile = womanProfile
        bothProfile.preference = "both"
        precondition(RecommendationEngine.neighborPrior(weights: weights, profile: bothProfile, participants: participants + [female])?.poolSize == 3, "Both should use available daters from both gender groups")
        let requestState = DatingAppState(defaults: defaults)
        requestState.selectedTab = .community
        let threadCount = requestState.snapshot.conversations.count
        requestState.requestCharacterLike(.selene)
        precondition(requestState.requestedLikeID == "selene" && requestState.selectedTab == .discover)
        precondition(requestState.snapshot.conversations.count == threadCount, "Routing a Moment Like must not manufacture a match before evaluation")

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
