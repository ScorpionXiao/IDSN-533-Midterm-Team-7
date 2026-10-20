import SwiftUI
import PhotosUI
import UIKit

struct DatingTabShell: View {
    @Environment(DatingAppState.self) private var appState

    var body: some View {
        Group {
            switch appState.selectedTab {
            case .discover: DatingDiscoverView()
            case .likes: LikesYouView()
            case .messages: DatingMessagesView()
            case .community: CharacterMomentsView()
            case .profile: DatingProfileView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(DatingTab.allCases, id: \.self) { tab in
                Button {
                    appState.selectedTab = tab
                } label: {
                    VStack(spacing: 5) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 21, weight: appState.selectedTab == tab ? .semibold : .regular))
                                .frame(width: 34, height: 24)
                            if tab == .messages && appState.unreadCount > 0 {
                                Circle().fill(Color.vibePink).frame(width: 7, height: 7).offset(x: 3, y: -3)
                            }
                        }
                        Text(tab.title).font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(appState.selectedTab == tab ? Color.vibePink : Color.white.opacity(0.42))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(appState.selectedTab == tab ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 6)
        .background {
            if appState.selectedTab == .discover {
                Rectangle().fill(.ultraThinMaterial).overlay(.black.opacity(0.55)).ignoresSafeArea(edges: .bottom)
            } else {
                Color(red: 0.055, green: 0.035, blue: 0.085).ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

private struct DatingDiscoverView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(DemoSession.self) private var session
    @Environment(DataStore.self) private var store
    @State private var deck: [VirtualCharacter] = []
    @State private var lastChoice: (name: String, liked: Bool)?
    @State private var rerankNote: String?
    @State private var index = 0
    @State private var phase: CardPhase = .front
    @State private var rotation = 0.0
    @State private var questionIndex = 0
    @State private var answers: [ChemistryOption] = []
    @State private var dragOffset = CGSize.zero
    @State private var showingCharacter: VirtualCharacter?
    @State private var profileLike: VirtualCharacter?
    @State private var leavingNoteFor: VirtualCharacter?
    @State private var departure: SwipeChoice?
    @State private var history: [DiscoveryCheckpoint] = []
    @State private var isInstantMatch = false
    @State private var instantMatchScore: Int?
    @State private var showReplyNotice = false

    private enum SwipeChoice { case pass, like, superLike }
    private struct DiscoveryCheckpoint {
        let deck: [VirtualCharacter]
        let index: Int
        let signals: RecommendationSignals
        let superLikes: Set<String>
    }
    private var likeProgress: CGFloat { min(max(dragOffset.width / 115, 0), 1) }
    private var passProgress: CGFloat { min(max(-dragOffset.width / 115, 0), 1) }

    private enum CardPhase: String { case front, questions, evaluating, waiting, awaitingReply, success }
    private var characters: [VirtualCharacter] { deck.isEmpty ? appState.characters : deck }
    private var character: VirtualCharacter? {
        characters.isEmpty ? nil : characters[index % characters.count]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                if let character {
                    Color.black.opacity(0.45)
                    Rectangle()
                        .fill(Color.vibePink.opacity(Double(likeProgress) * 0.65))
                        .blur(radius: 28).accessibilityHidden(true)
                    card(for: character)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(alignment: dragOffset.width >= 0 ? .topLeading : .topTrailing) {
                            if phase == .front && abs(dragOffset.width) > 12 {
                                Text(dragOffset.width > 0 ? "LIKE" : "PASS")
                                    .font(.system(size: 30, weight: .black, design: .rounded)).tracking(3)
                                    .foregroundStyle(dragOffset.width > 0 ? Color.vibePink : .white)
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .overlay { RoundedRectangle(cornerRadius: 10).stroke(dragOffset.width > 0 ? Color.vibePink : .white, lineWidth: 3) }
                                    .rotationEffect(.degrees(dragOffset.width > 0 ? -13 : 13))
                                    .padding(.top, 125).padding(.horizontal, 28)
                                    .opacity(Double(max(likeProgress, passProgress)))
                                    .allowsHitTesting(false)
                            }
                        }
                        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
                        .offset(x: dragOffset.width, y: abs(dragOffset.width) * 0.03)
                        .rotationEffect(.degrees(Double(dragOffset.width / 38)))
                        .gesture(DragGesture(minimumDistance: 25)
                            .onChanged { value in
                                if phase == .front && departure == nil { dragOffset = value.translation }
                            }
                            .onEnded { value in
                                guard phase == .front && departure == nil else { return }
                                if value.translation.width > 90 { choose(.like) }
                                else if value.translation.width < -90 { choose(.pass) }
                                else { withAnimation(.spring(response: 0.4)) { dragOffset = .zero } }
                            })
                        .simultaneousGesture(TapGesture().onEnded {
                            if phase == .front && departure == nil { showingCharacter = character }
                        })
                        .accessibilityIdentifier("discover-card")
                        .accessibilityAction(named: "View character profile") {
                            if phase == .front { showingCharacter = character }
                        }

                    controls(for: character)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 22).padding(.bottom, 13)
                        .background {
                            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                                .allowsHitTesting(false)
                        }
                } else {
                    ContentUnavailableView("More stories soon", systemImage: "sparkles", description: Text("No videos are available for this collection yet."))
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay {
                if showReplyNotice, let character {
                    ZStack {
                        Color.black.opacity(0.14)
                        AwaitingCharacterReplyView(character: character)
                            .frame(maxWidth: 330).padding(24)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .top) {
                if let rerankNote {
                    Label(rerankNote, systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 70)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .clipped()
        }
        .ignoresSafeArea(.container, edges: .top)
        .buttonStyle(.plain)
        .sheet(item: $showingCharacter, onDismiss: {
            if let character = profileLike {
                profileLike = nil
                beginQuestions(character)
            }
        }) { character in
            CharacterProfileDetailView(character: character) { profileLike = character }
        }
        .sheet(item: $leavingNoteFor) { character in
            CharacterNoteComposer(character: character) { text in
                checkpoint()
                appState.leaveIntroduction(text, for: character)
                appState.recordLike(character)
                advance()
                rerankNote = "Your hello is saved in Messages"
            }
        }
        .sensoryFeedback(.selection, trigger: departure)
        .task(id: departure) {
            guard let choice = departure, let character else { return }
            do { try await Task.sleep(for: .milliseconds(190)) } catch { return }
            dragOffset = .zero
            if choice == .pass { pass(character) }
            else { beginQuestions(character, superLike: choice == .superLike) }
            departure = nil
        }
        .onAppear {
            if deck.isEmpty { restoreDeck() }
            consumeRequestedLike()
        }
        .onChange(of: appState.requestedLikeID) { consumeRequestedLike() }
        .task(id: rerankNote) {
            guard rerankNote != nil else { return }
            do { try await Task.sleep(for: .seconds(2.5)) } catch { return }
            withAnimation { rerankNote = nil }
        }
        .onChange(of: appState.profile) {
            history = []
            resetCard()
            rebuildDeck()
        }
        .onChange(of: session.weights) { history = []; rebuildDeck() }
        .task(id: phase) {
            guard let character else { return }
            if phase == .awaitingReply {
                withAnimation(.easeIn(duration: 0.35)) { showReplyNotice = true }
                do { try await Task.sleep(for: .milliseconds(1750)) } catch { return }
                withAnimation(.easeOut(duration: 0.5)) { showReplyNotice = false }
                do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
                lastChoice = nil
                advance()
            } else if phase == .evaluating {
                do { try await Task.sleep(for: .milliseconds(1100)) } catch { return }
                if CompatibilityEngine.chemistryMatches(answers) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        phase = .success
                        rotation = 360
                    }
                } else {
                    // A weak answer no longer blocks the chat; it starts with low affinity instead.
                    appState.accept(character, affinity: AffinityRules.initial(answerTotal: answerTotal))
                    withAnimation { phase = .waiting }
                }
            } else if phase == .success {
                do { try await Task.sleep(for: .milliseconds(750)) } catch { return }
                appState.recordMatch(character)
                appState.accept(character, affinity: isInstantMatch ? AffinityRules.likesYouStart : AffinityRules.initial(answerTotal: answerTotal))
                // Coming back from the video or chat continues with the next card.
                appState.discoverIndex = index + 1
                if appState.discoverIndex >= deck.count { appState.discoverDeckIDs = [] }
                session.likeCandidate(character, profile: appState.profile, score: instantMatchScore ?? recommendation(for: character)?.score)
            }
        }
    }

    private var answerTotal: Int { answers.reduce(0) { $0 + $1.affinity } }

    private func recommendation(for character: VirtualCharacter) -> Recommendation? {
        appState.recommendation(for: character, baseWeights: session.weights, participants: store.participants)
    }

    private func card(for character: VirtualCharacter) -> some View {
        ZStack {
            if phase == .front || phase == .success || phase == .awaitingReply {
                CharacterPortraitCard(character: character) {
                    let recommended = recommendation(for: character)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 6) {
                            Image(systemName: phase == .success ? "heart.fill" : "sparkles")
                            Text(phase == .success ? "It's mutual" : "\(recommended?.score ?? CompatibilityEngine.score(character, profile: appState.profile, weights: session.weights))% in tune")
                            if phase == .front && appState.likeRoute(for: character, baseWeights: session.weights, participants: store.participants) == .instantMatch {
                                Text("· Likes you").foregroundStyle(Color.vibePink)
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(phase == .success ? Color.vibePink : .black.opacity(0.35), in: Capsule())
                        if phase == .front, let recommended {
                            Text(recommended.reason).lineLimit(1)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(.black.opacity(0.35), in: Capsule())
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "info.circle.fill").font(.title3).foregroundStyle(.white.opacity(0.85))
                        .padding(.trailing, 25).padding(.bottom, 138).accessibilityHidden(true)
                }
            } else {
                cardBack(character)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .clipped()
    }

    private func cardBack(_ character: VirtualCharacter) -> some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.19, green: 0.09, blue: 0.24), Color(red: 0.08, green: 0.055, blue: 0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)
            if phase == .questions {
                ScrollView {
                    VStack(alignment: .leading, spacing: 19) {
                        HStack {
                            CharacterAvatar(character: character, size: 44)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("A LITTLE CHEMISTRY CHECK").font(.system(size: 9, weight: .bold)).tracking(1.4).foregroundStyle(Color.vibePink)
                                Text("\(character.name) is curious").font(.headline)
                            }
                            Spacer()
                            Text("\(questionIndex + 1)/2").font(.caption).foregroundStyle(.white.opacity(0.4))
                        }
                        let questions = ChemistryQuestions.forCharacter(character)
                        let question = questions[min(questionIndex, questions.count - 1)]
                        Text(question.text).font(.system(size: 24, weight: .semibold, design: .rounded)).tracking(-0.4)
                        Text("No perfect answers. Just your first instinct.").font(.caption).foregroundStyle(.white.opacity(0.48))
                        VStack(spacing: 10) {
                            ForEach(question.options) { option in
                                Button { answer(option) } label: {
                                    HStack(spacing: 12) {
                                        Text(option.text).font(.subheadline.weight(.medium)).multilineTextAlignment(.leading)
                                        Spacer(minLength: 4)
                                        Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Color.vibePink)
                                    }
                                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 17))
                                    .overlay { RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.09)) }
                                }
                                .accessibilityIdentifier("chemistry-option-\(option.id)")
                            }
                        }
                    }
                    .padding(22)
                    .padding(.top, 65).padding(.bottom, 105)
                }
            } else {
                WaitingResponseContent(
                    character: character,
                    evaluating: phase == .evaluating,
                    affinity: appState.conversation(for: character.id)?.affinity
                )
                .padding(.top, 65).padding(.bottom, 125)
            }
        }
    }

    private func controls(for character: VirtualCharacter) -> some View {
        VStack(spacing: 10) {
            if phase == .front || phase == .awaitingReply {
                HStack(spacing: 0) {
                    discoverAction("Rewind", symbol: "arrow.uturn.backward", size: 43, color: .white.opacity(0.55)) { rewind() }
                        .disabled(history.isEmpty && index == 0)
                        .opacity(history.isEmpty && index == 0 ? 0.35 : 1)
                    Spacer(minLength: 10)
                    discoverAction("Pass \(character.name)", symbol: "xmark", size: 59, color: .white, emphasis: passProgress) { choose(.pass) }
                    Spacer(minLength: 10)
                    discoverAction("Super like \(character.name)", symbol: "star.fill", size: 48, color: .vibeCyan) { choose(.superLike) }
                    Spacer(minLength: 10)
                    discoverAction("Like \(character.name)", symbol: "heart.fill", size: 59, color: .vibePink, emphasis: likeProgress) { choose(.like) }
                    Spacer(minLength: 10)
                    discoverAction("Leave \(character.name) a note", symbol: "paperplane.fill", size: 43, color: .vibeCyan) { leavingNoteFor = character }
                }
                .padding(.horizontal, 23)
                .disabled(departure != nil || phase == .awaitingReply)
                Text("← Pass  ·  Like →  ·  Tap the card for their story")
                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.38))
            } else if phase == .waiting {
                Button { openLowAffinityChat(character) } label: {
                    Label("Chat with \(character.name)", systemImage: "message.fill").font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity).padding(16)
                        .background(LinearGradient(colors: [.vibePink, .vibePurple], startPoint: .leading, endPoint: .trailing), in: Capsule())
                }.padding(.horizontal, 28)
                Button("Keep exploring") { advance() }
                    .font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.6))
                Text("The conversation is saved in Messages").font(.caption2).foregroundStyle(.white.opacity(0.4))
            } else if phase == .questions {
                Button("Back to their profile") { resetCard() }.font(.caption).foregroundStyle(.white.opacity(0.55)).padding(18)
            } else {
                Text(phase == .success ? "Something clicked. Meet \(character.name)." : "Finding your rhythm together…")
                    .font(.caption).foregroundStyle(.white.opacity(0.5)).padding(24)
            }
        }
    }

    private func discoverAction(_ label: String, symbol: String, size: CGFloat, color: Color, emphasis: CGFloat = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size > 50 ? 26 : 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(.black.opacity(0.4), in: Circle())
                .background(color.opacity(0.07 + Double(emphasis) * 0.13), in: Circle())
                .overlay { Circle().stroke(color.opacity(0.3 + Double(emphasis) * 0.35), lineWidth: 1) }
                .shadow(color: color.opacity(Double(emphasis) * 0.25), radius: 15)
                .scaleEffect(1 + emphasis * 0.16)
        }
        .accessibilityLabel(label)
        .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.7), value: emphasis)
    }

    private func choose(_ choice: SwipeChoice) {
        guard phase == .front && departure == nil else { return }
        departure = choice
        withAnimation(.easeIn(duration: 0.19)) {
            dragOffset = CGSize(width: choice == .pass ? -430 : 430, height: 0)
        }
    }

    private func checkpoint() {
        history.append(DiscoveryCheckpoint(deck: deck, index: index, signals: appState.signals, superLikes: appState.superLikedIDs))
        if history.count > 20 { history.removeFirst() }
    }

    /// Undo preference learning as well as the card movement; never delete a conversation.
    private func rewind() {
        guard departure == nil else { return }
        resetCard()
        if let previous = history.popLast() {
            deck = previous.deck
            index = previous.index
            appState.signals = previous.signals
            appState.superLikedIDs = previous.superLikes
        } else if index > 0 { index -= 1 }
        rerankNote = "One more look"
        saveDeck()
    }

    private func beginQuestions(_ character: VirtualCharacter, superLike: Bool = false) {
        // Decide before recording a swipe: learning can reorder Likes you.
        let route = appState.likeRoute(for: character, baseWeights: session.weights, participants: store.participants)
        let score = recommendation(for: character)?.score
        checkpoint()
        if superLike { appState.recordSuperLike(character) }
        else { appState.recordLike(character) }
        if route == .existingChat {
            appState.discoverIndex = index + 1
            if appState.discoverIndex >= deck.count { appState.discoverDeckIDs = [] }
            session.likeCandidate(character, profile: appState.profile, score: score)
            session.step = .chat
            return
        }
        if route == .instantMatch {
            isInstantMatch = true
            instantMatchScore = score
            withAnimation(.spring(response: 0.45)) { phase = .success }
            return
        }
        if route == .awaitingReply {
            appState.awaitCharacterReply(character)
            appState.discoverIndex = index + 1
            if appState.discoverIndex >= deck.count { appState.discoverDeckIDs = [] }
            phase = .awaitingReply
            return
        }
        lastChoice = (character.name, true)
        answers = []
        questionIndex = 0
        withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) { rotation = 180; phase = .questions }
    }

    private func answer(_ option: ChemistryOption) {
        answers.append(option)
        withAnimation(.easeInOut(duration: 0.2)) {
            if questionIndex == 0 { questionIndex = 1 }
            else { phase = .evaluating }
        }
    }

    private func resetCard() {
        rotation = 0
        phase = .front
        answers = []
        questionIndex = 0
        dragOffset = .zero
        isInstantMatch = false
        instantMatchScore = nil
        showReplyNotice = false
    }

    private func consumeRequestedLike() {
        guard let id = appState.requestedLikeID else { return }
        appState.requestedLikeID = nil
        guard let requested = VirtualCharacter.find(id) else { return }
        if deck.isEmpty { restoreDeck() }
        resetCard()
        if let position = deck.firstIndex(where: { $0.id == id }) { index = position }
        else { deck.insert(requested, at: 0); index = 0 }
        saveDeck()
        beginQuestions(requested)
    }

    /// Skips the video: it stays locked until affinity reaches the threshold in chat.
    private func openLowAffinityChat(_ character: VirtualCharacter) {
        appState.discoverIndex = index + 1
        if appState.discoverIndex >= deck.count { appState.discoverDeckIDs = [] }
        session.likeCandidate(character, profile: appState.profile, score: recommendation(for: character)?.score)
        session.step = .chat
    }

    private func pass(_ character: VirtualCharacter) {
        checkpoint()
        appState.recordPass(character)
        lastChoice = (character.name, false)
        advance()
    }

    /// Moves to the next card and re-ranks the cards not yet shown in this round,
    /// so a like or pass changes what comes next. A finished round starts a fresh order.
    private func advance() {
        resetCard()
        withAnimation(.easeInOut(duration: 0.25)) {
            let next = index + 1
            if next >= deck.count {
                rebuildDeck()
            } else {
                let shown = Array(deck.prefix(next))
                let remainingOrder = deck.dropFirst(next).map(\.id)
                let remaining = Set(remainingOrder)
                let reranked = appState.discoverDeck(baseWeights: session.weights, participants: store.participants)
                    .filter { remaining.contains($0.id) }
                if reranked.map(\.id) != remainingOrder, let lastChoice {
                    rerankNote = lastChoice.liked
                        ? "More like \(lastChoice.name) coming up"
                        : "Fewer like \(lastChoice.name) coming up"
                }
                deck = shown + reranked
                index = next
            }
        }
        saveDeck()
    }

    private func rebuildDeck() {
        deck = appState.discoverDeck(baseWeights: session.weights, participants: store.participants)
        index = 0
        saveDeck()
    }

    /// Continues the round in progress if it still matches the current collection.
    private func restoreDeck() {
        let saved = appState.discoverDeckIDs.compactMap { VirtualCharacter.find($0) }
        guard !saved.isEmpty, Set(saved.map(\.id)) == Set(appState.characters.map(\.id)) else {
            rebuildDeck()
            return
        }
        deck = saved
        index = min(appState.discoverIndex, saved.count - 1)
    }

    private func saveDeck() {
        appState.discoverDeckIDs = deck.map(\.id)
        appState.discoverIndex = index
    }
}

private struct CharacterPortraitCard<Badge: View>: View {
    let character: VirtualCharacter
    @ViewBuilder var badge: () -> Badge

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Image(character.discoveryImageName).resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top).clipped()
                Rectangle().fill(.ultraThinMaterial)
                    .mask {
                        LinearGradient(stops: [
                            .init(color: .clear, location: 0.40),
                            .init(color: .white.opacity(0.15), location: 0.58),
                            .init(color: .white.opacity(0.8), location: 0.83),
                            .init(color: .white, location: 1),
                        ], startPoint: .top, endPoint: .bottom)
                    }
                LinearGradient(stops: [.init(color: .clear, location: 0.35), .init(color: .black.opacity(0.94), location: 1)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 7) {
                        Circle().fill(Color.vibeCyan).frame(width: 6, height: 6)
                        Text("AI COMPANION").font(.system(size: 9, weight: .bold)).tracking(1.7)
                    }.foregroundStyle(.white.opacity(0.8))
                    Text(character.name).font(.system(size: 38, weight: .bold, design: .rounded)).tracking(-0.9)
                    badge()
                    Text(character.headline).font(.subheadline).foregroundStyle(.white.opacity(0.78)).lineLimit(2)
                    HStack(spacing: 6) {
                        ForEach(character.tags.prefix(3), id: \.self) { tag in
                            Text(tag).font(.system(size: 10, weight: .medium)).padding(.horizontal, 9).padding(.vertical, 6)
                                .background(.white.opacity(0.12), in: Capsule())
                        }
                    }
                }.padding(.horizontal, 25).padding(.bottom, 132)
            }
        }
    }
}

private struct WaitingResponseContent: View {
    let character: VirtualCharacter
    var evaluating = false
    /// Set when a weak answer opened a low-affinity chat.
    var affinity: Int?
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle().stroke(Color.vibePink.opacity(pulse ? 0.04 : 0.22), lineWidth: 1)
                    .frame(width: pulse ? 180 : 130, height: pulse ? 180 : 130)
                Circle().fill(Color.vibePurple.opacity(0.15)).frame(width: 130, height: 130)
                CharacterAvatar(character: character, size: 94)
                Image(systemName: evaluating ? "sparkles" : "clock.fill")
                    .font(.system(size: 18)).padding(11).background(Color.vibePink, in: Circle()).offset(x: 36, y: 36)
            }.frame(height: 185)
            VStack(spacing: 12) {
                Text(evaluating ? "Feeling out the chemistry" : "Not quite a spark yet")
                    .font(.system(size: 25, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
                Text(evaluating ? "Seeing how your worlds fit together…" : "\(character.name) is a little unsure about you.\nWin them over in chat.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.55)).multilineTextAlignment(.center)
                if !evaluating {
                    if let affinity {
                        AffinityMeter(affinity: affinity).frame(maxWidth: 220).padding(.top, 4)
                    }
                    Text("Reach \(AffinityRules.unlockThreshold) ❤ to unlock \(character.name)'s video.")
                        .font(.caption).foregroundStyle(.white.opacity(0.35)).padding(.top, 4)
                }
            }
            if evaluating { ProgressView().tint(.vibePink) }
        }
        .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { pulse = true } }
    }
}

/// Display-only: the Discover notice fades automatically; it never accepts on
/// behalf of a character or creates a chat/video unlock.
private struct AwaitingCharacterReplyView: View {
    let character: VirtualCharacter

    var body: some View {
        VStack(spacing: 17) {
            CharacterAvatar(character: character, size: 69)
                .overlay { Circle().stroke(Color.vibePink.opacity(0.65), lineWidth: 2).padding(-5) }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "clock.fill").font(.caption).padding(7)
                        .background(Color.vibePurple, in: Circle())
                }
            Text("Waiting for \(character.name)'s reply")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
            Text("Your like is saved. Keep exploring while the spark finds its way.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center).lineSpacing(3)
            Label("Saved in Messages", systemImage: "checkmark.circle")
                .font(.caption).foregroundStyle(Color.vibeCyan)
        }
        .padding(28).frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.13)) }
        .shadow(color: .black.opacity(0.25), radius: 25, y: 12)
        .accessibilityIdentifier("awaiting-reply-notice")
    }
}

private struct LikesYouView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(DemoSession.self) private var session
    @Environment(DataStore.self) private var store
    private var recommendations: [Recommendation] {
        appState.likesYouRecommendations(baseWeights: session.weights, participants: store.participants)
    }
    private var prior: NeighborPrior? {
        appState.neighborPrior(baseWeights: session.weights, participants: store.participants)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DatingPageHeader(eyebrow: "YOUR NEXT SPARK", title: "Likes you", subtitle: "A few personalities already in your orbit.")
                HStack(spacing: 12) {
                    Image(systemName: "heart.circle.fill").font(.system(size: 32)).foregroundStyle(Color.vibePink)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The feeling could be mutual").font(.subheadline.weight(.semibold))
                        Text("These recommendations fit your preferences. Like one to meet them right away.")
                            .font(.caption).foregroundStyle(.white.opacity(0.5))
                        if let prior {
                            Text("Based on the \(prior.neighborCount) real speed daters most like you, who actually said yes most for \(prior.topAttributes.map { $0.label.lowercased() }.joined(separator: " and ")).")
                                .font(.caption2).foregroundStyle(Color.vibeCyan.opacity(0.8))
                        }
                    }
                }.padding(17).datingSurface()
                if recommendations.isEmpty {
                    ContentUnavailableView("You're all caught up", systemImage: "heart", description: Text("Explore more profiles or adjust your preferences for a different kind of connection."))
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 16) {
                    ForEach(recommendations) { recommendation in
                        let character = recommendation.character
                        VStack(alignment: .leading, spacing: 10) {
                            Image(character.discoveryImageName).resizable().scaledToFill()
                                .frame(height: 205).frame(maxWidth: .infinity).clipped()
                                .overlay(alignment: .topLeading) {
                                    Text("\(recommendation.score)% in tune")
                                        .font(.system(size: 10, weight: .semibold)).padding(8).background(.black.opacity(0.5), in: Capsule()).padding(10)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            Text(character.name).font(.headline)
                            Text(recommendation.reason).font(.caption2).foregroundStyle(.white.opacity(0.5)).lineLimit(2)
                            Button {
                                appState.recordLike(character)
                                appState.recordMatch(character)
                                appState.accept(character, affinity: AffinityRules.likesYouStart)
                                session.likeCandidate(character, profile: appState.profile, score: recommendation.score)
                            } label: {
                                Label("Like back", systemImage: "heart.fill").font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity).padding(.vertical, 11)
                                    .background(Color.vibePink.opacity(0.19), in: Capsule()).foregroundStyle(Color.vibePink)
                            }.buttonStyle(.plain)
                        }
                        .padding(10).datingSurface()
                    }
                }
                Text("Curated AI recommendations based on your signals.")
                    .font(.caption2).foregroundStyle(.white.opacity(0.3)).frame(maxWidth: .infinity)
            }.padding(20)
        }
    }
}

private struct DatingMessagesView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(DemoSession.self) private var session
    @Environment(DataStore.self) private var store
    @State private var search = ""
    @State private var pendingCharacter: VirtualCharacter?

    private var conversations: [DatingConversation] {
        appState.snapshot.conversations.sorted { $0.updatedAt > $1.updatedAt }.filter {
            search.isEmpty || (VirtualCharacter.find($0.characterID)?.name.localizedCaseInsensitiveContains(search) ?? false)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DatingPageHeader(eyebrow: "KEEP THE SPARK GOING", title: "Messages", subtitle: "Your people. Your conversations.")
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.4))
                    TextField("Find a connection", text: $search).font(.subheadline)
                }.padding(14).datingSurface()

                if !appState.snapshot.invitations.isEmpty {
                    Text("WAITING FOR A REPLY").sectionEyebrow()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(appState.snapshot.invitations) { invitation in
                                if let character = VirtualCharacter.find(invitation.characterID) {
                                    Button { pendingCharacter = character } label: {
                                        VStack(spacing: 7) {
                                            CharacterAvatar(character: character, size: 62)
                                                .overlay(alignment: .bottomTrailing) {
                                                    Image(systemName: "clock.fill").font(.caption).padding(4).background(Color(red: 0.17, green: 0.1, blue: 0.22), in: Circle()).foregroundStyle(.white.opacity(0.7))
                                                }
                                            Text(character.name).font(.caption)
                                            Text("Pending").font(.system(size: 9)).foregroundStyle(.white.opacity(0.4))
                                        }
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                if conversations.isEmpty {
                    ContentUnavailableView(search.isEmpty ? "Your next hello starts here" : "No conversations found", systemImage: "bubble.left.and.bubble.right", description: Text(search.isEmpty ? "Match with someone in Discover or Likes you. Your conversations will stay here." : "Try another name."))
                    if search.isEmpty {
                        Button("Explore connections") { appState.selectedTab = .discover }
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.vibePink).frame(maxWidth: .infinity)
                    }
                } else {
                    Text("CONVERSATIONS").sectionEyebrow()
                    LazyVStack(spacing: 0) {
                        ForEach(conversations) { conversation in
                            if let character = VirtualCharacter.find(conversation.characterID) {
                                Button {
                                    let score = appState.recommendation(for: character, baseWeights: session.weights, participants: store.participants)?.score
                                    session.likeCandidate(character, profile: appState.profile, score: score)
                                    session.step = .chat
                                } label: {
                                    HStack(spacing: 13) {
                                        CharacterAvatar(character: character, size: 58)
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(character.name).font(.subheadline.weight(.semibold))
                                                Label("\(conversation.affinity)", systemImage: conversation.isVideoLocked ? "lock.fill" : "heart.fill")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundStyle(conversation.isVideoLocked ? .white.opacity(0.45) : Color.vibePink)
                                                Spacer()
                                                Text(conversation.updatedAt, style: .relative).font(.system(size: 10)).foregroundStyle(.white.opacity(0.35))
                                            }
                                            Text(conversation.messages.last(where: { $0.kind != .notice })?.text ?? "Say hello")
                                                .font(.caption).foregroundStyle(.white.opacity(0.5)).lineLimit(2).multilineTextAlignment(.leading)
                                        }
                                        if conversation.unread { Circle().fill(Color.vibePink).frame(width: 7, height: 7) }
                                    }.padding(.vertical, 17)
                                }.buttonStyle(.plain)
                                Divider().overlay(.white.opacity(0.04))
                            }
                        }
                    }
                }
            }.padding(22)
        }
        .sheet(item: $pendingCharacter) { character in
            ZStack { VibeBackground(); AwaitingCharacterReplyView(character: character).padding(24) }
                .presentationDetents([.medium]).presentationDragIndicator(.visible)
        }
    }
}


private struct DatingProfileView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(DemoSession.self) private var session
    @Environment(DataStore.self) private var store
    @State private var showingEditor = false
    @State private var confirmingSignOut = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DatingPageHeader(eyebrow: "YOUR SIDE OF THE STORY", title: "Profile", subtitle: "Make space for the kind of connection you want.")
                VStack(spacing: 15) {
                    ProfilePhotoControl(displayName: appState.profile.name, avatarData: Binding(
                        get: { appState.profile.avatarData },
                        set: { data in
                            var profile = appState.profile
                            profile.avatarData = data
                            appState.updateProfile(profile)
                        }
                    ))
                    VStack(spacing: 5) {
                        Text("\(appState.profile.name), \(appState.profile.age)").font(.title2.bold())
                        Label(appState.profile.city, systemImage: "mappin.circle").font(.caption).foregroundStyle(.white.opacity(0.45))
                    }
                    Text(appState.profile.bio).font(.subheadline).foregroundStyle(.white.opacity(0.6)).multilineTextAlignment(.center)
                    Button { showingEditor = true } label: {
                        Label("Edit profile", systemImage: "pencil").font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(13).background(.white.opacity(0.08), in: Capsule())
                    }.buttonStyle(.plain)
                }.padding(23).frame(maxWidth: .infinity).datingSurface()

                VStack(alignment: .leading, spacing: 17) {
                    HStack { Text("Your preferences").font(.headline); Spacer(); Button("Edit") { showingEditor = true }.font(.caption).foregroundStyle(Color.vibePink) }
                    profileRow("Looking to meet", value: (PreferredCompanion(rawValue: appState.profile.preference) ?? .woman).collectionTitle, icon: "heart")
                    profileRow("The energy", value: CompanionEnergy(rawValue: appState.profile.energy)?.title ?? "Calm", icon: "sparkles")
                    profileRow("Your style", value: appState.profile.communication, icon: "bubble.left")
                    profileRow("Ideal moment", value: PerfectMoment(rawValue: appState.profile.moment)?.title ?? "Late coffee", icon: "moon.stars")
                }.padding(20).datingSurface()

                VStack(alignment: .leading, spacing: 13) {
                    Text("Little things you love").font(.headline)
                    Text(appState.profile.interests.isEmpty ? "Add a few interests to your profile." : appState.profile.interests.joined(separator: "   ·   "))
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6)).lineSpacing(6)
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading).datingSurface()

                recommendationInsight

                VStack(spacing: 12) {
                    Text(appState.sessionEmail ?? "Local demo profile").font(.caption).foregroundStyle(.white.opacity(0.4))
                    Button("Sign out") { confirmingSignOut = true }
                        .font(.subheadline.weight(.medium)).foregroundStyle(Color.vibePink)
                    Text("Demo sign-in · profile and chats stay on this device.")
                        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.3))
                }.frame(maxWidth: .infinity).padding(.vertical, 12)

                HStack {
                    Label("\(appState.snapshot.conversations.count) \(appState.snapshot.conversations.count == 1 ? "connection" : "connections")", systemImage: "heart.text.square")
                    Spacer()
                    Text("Your story is just beginning")
                }.font(.system(size: 10)).foregroundStyle(.white.opacity(0.35))
            }.padding(20)
        }
        .sheet(isPresented: $showingEditor) { ProfileEditorView() }
        .confirmationDialog("Sign out of the local demo?", isPresented: $confirmingSignOut, titleVisibility: .visible) {
            Button("Sign out") { appState.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Your profile, connections and messages will stay on this device.") }
    }

    /// Shows what the recommender is using, so the ranking is explainable in a demo.
    private var recommendationInsight: some View {
        let prior = appState.neighborPrior(baseWeights: session.weights, participants: store.participants)
        let learned = RecommendationEngine.learnedWeights(base: session.weights, signals: appState.signals)
        let actions = appState.signals.liked.count + appState.signals.passed.count + appState.signals.matched.count
        return VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("How we pick for you").font(.headline)
                Spacer()
                if actions > 0 {
                    Button("Reset") { appState.resetRecommendationLearning() }.font(.caption).foregroundStyle(Color.vibePink)
                }
            }
            if let prior {
                profileRow("Similar real daters chose", value: prior.topAttributes.map(\.label).joined(separator: " & "), icon: "person.3")
            }
            profileRow("Your picks lean toward", value: TypeCalculator.ranked(learned).prefix(2).map(\.label).joined(separator: " & "), icon: "chart.line.uptrend.xyaxis")
            Text(actions == 0 ? "Like or pass in Discover and your recommendations will adapt." : "Learned from \(actions) \(actions == 1 ? "choice" : "choices") in Discover and your chats.")
                .font(.caption2).foregroundStyle(.white.opacity(0.4))
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).datingSurface()
    }

    private func profileRow(_ title: String, value: String, icon: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon).foregroundStyle(Color.vibePink).frame(width: 20)
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value).font(.caption.weight(.medium))
        }
    }
}

private struct ProfileEditorView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(DemoSession.self) private var session
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft = DatingProfile()
    @State private var ageText = "24"
    @State private var photo: PhotosPickerItem?
    @State private var photoError: String?
    @State private var loadingPhoto = false
    private let interests = ["Music", "Art", "Coffee", "Books", "Gaming", "Travel", "Design", "Film", "Nature", "Food", "Fantasy", "Fitness"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $photo, matching: .images) {
                        HStack(spacing: 16) {
                            ProfileAvatar(profile: draft, size: 65)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(loadingPhoto ? "Loading photo…" : "Choose your photo").foregroundStyle(.primary)
                                Text("A little more you").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "photo.badge.plus").foregroundStyle(Color.vibePink)
                        }.padding(.vertical, 8)
                    }
                    if let photoError { Text(photoError).font(.caption).foregroundStyle(.red) }
                }
                Section("About you") {
                    TextField("Name", text: $draft.name).textContentType(.nickname)
                    HStack {
                        Text("Age")
                        Spacer()
                        ProfileAgeField(text: $ageText)
                    }
                    TextField("City", text: $draft.city)
                    TextField("Your bio", text: $draft.bio, axis: .vertical).lineLimit(3...5)
                }
                Section("Connection preferences") {
                    Picker("I'd like to meet", selection: $draft.preference) {
                        Text("Women").tag("woman"); Text("Men").tag("man")
                        Text("Both").tag("both")
                    }
                    Picker("Energy", selection: $draft.energy) {
                        ForEach(CompanionEnergy.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    Picker("Ideal moment", selection: $draft.moment) {
                        ForEach(PerfectMoment.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    Picker("I connect through", selection: $draft.communication) {
                        Text("Thoughtful conversation").tag("Thoughtful")
                        Text("Playful banter").tag("Playful")
                        Text("Direct, honest words").tag("Direct")
                    }
                }
                Section("Interests") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(interests, id: \.self) { interest in
                            Button {
                                if draft.interests.contains(interest) { draft.interests.removeAll { $0 == interest } }
                                else { draft.interests.append(interest) }
                            } label: {
                                Text(interest).font(.caption.weight(.medium)).frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(draft.interests.contains(interest) ? Color.vibePink.opacity(0.24) : .white.opacity(0.05), in: Capsule())
                                    .foregroundStyle(draft.interests.contains(interest) ? Color.vibePink : .white.opacity(0.55))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.vertical, 8)
                }
            }
            .tint(.vibePink)
            .scrollContentBackground(.hidden)
            .background { VibeBackground() }
            .navigationTitle("Make it yours").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let age = ProfileAge.parse(ageText) else { return }
                        draft.age = age
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft.hasOnboarded = true
                        appState.updateProfile(draft)
                        session.applyProfile(draft, store: store)
                        dismiss()
                    }.fontWeight(.semibold)
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ProfileAge.parse(ageText) == nil || loadingPhoto)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { draft = appState.profile; ageText = String(draft.age) }
        .task(id: photo) {
            guard let photo else { return }
            loadingPhoto = true
            defer { loadingPhoto = false }
            do {
                guard let data = try await photo.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    photoError = "This photo couldn't be opened. Please choose another."
                    return
                }
                guard !Task.isCancelled else { return }
                let thumbnail = image.preparingThumbnail(of: CGSize(width: 400, height: 400)) ?? image
                draft.avatarData = thumbnail.jpegData(compressionQuality: 0.8)
                photoError = nil
            } catch {
                if !Task.isCancelled { photoError = "Couldn't load this photo. Try another one." }
            }
        }
    }
}

struct CharacterAvatar: View {
    let character: VirtualCharacter
    let size: CGFloat
    var body: some View {
        Image(character.discoveryImageName).resizable().scaledToFill().frame(width: size, height: size, alignment: .top).clipShape(Circle())
            .overlay { Circle().stroke(.white.opacity(0.12)) }
    }
}

struct ProfileAvatar: View {
    let profile: DatingProfile
    let size: CGFloat
    var body: some View {
        Group {
            if let data = profile.avatarData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [Color.vibePink.opacity(0.7), .vibePurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(String(profile.name.prefix(1)).uppercased()).font(.system(size: size * 0.36, weight: .medium, design: .rounded)).foregroundStyle(.white)
                }
            }
        }.frame(width: size, height: size).clipShape(Circle())
    }
}

struct DatingPageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow).sectionEyebrow().foregroundStyle(Color.vibePink)
            Text(title).font(.system(size: 34, weight: .bold, design: .rounded)).tracking(-1)
            Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.45))
        }.padding(.top, 9)
    }
}

extension View {
    func datingSurface() -> some View {
        background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.065)) }
    }
    func sectionEyebrow() -> some View {
        font(.system(size: 10, weight: .semibold)).tracking(1.4).foregroundStyle(.white.opacity(0.4))
    }
}

/// A compact heart meter with a tick at the unlock threshold.
struct AffinityMeter: View {
    let affinity: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: "heart.fill").foregroundStyle(Color.vibePink)
                Text("\(affinity)").monospacedDigit()
                Spacer()
                if affinity < AffinityRules.unlockThreshold {
                    Label("Video at \(AffinityRules.unlockThreshold)", systemImage: "lock.fill").foregroundStyle(.white.opacity(0.45))
                } else {
                    Label("Video unlocked", systemImage: "lock.open.fill").foregroundStyle(Color.vibeCyan)
                }
            }
            .font(.system(size: 10, weight: .semibold))
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(colors: [.vibePink, .vibePurple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * CGFloat(affinity) / 100)
                    Rectangle().fill(.white.opacity(0.5))
                        .frame(width: 1.5)
                        .offset(x: geometry.size.width * CGFloat(AffinityRules.unlockThreshold) / 100)
                }
            }
            .frame(height: 5)
            .animation(.spring(response: 0.5), value: affinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Affinity \(affinity) of 100")
    }
}
