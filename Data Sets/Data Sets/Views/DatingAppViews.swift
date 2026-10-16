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
        .background { Color(red: 0.055, green: 0.035, blue: 0.085).ignoresSafeArea(edges: .bottom) }
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.07)).frame(height: 1) }
    }
}

private struct DatingDiscoverView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(DemoSession.self) private var session
    @State private var index = 0
    @State private var phase: CardPhase = .front
    @State private var rotation = 0.0
    @State private var questionIndex = 0
    @State private var answers: [ChemistryOption] = []
    @State private var dragOffset = CGSize.zero
    @State private var showingPreferences = false

    private enum CardPhase: String { case front, questions, evaluating, waiting, success }
    private var characters: [VirtualCharacter] { appState.characters }
    private var character: VirtualCharacter? {
        characters.isEmpty ? nil : characters[index % characters.count]
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("VibeMate").font(.system(size: 27, weight: .bold, design: .rounded)).tracking(-0.8)
                    Text("A little curiosity. Real chemistry.").font(.caption).foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Button { showingPreferences = true } label: {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 19))
                        .frame(width: 44, height: 44).background(.white.opacity(0.07), in: Circle())
                }
                .accessibilityLabel("Discovery preferences")
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)

            if let character {
                HStack {
                    Label(appState.profile.preference == "man" ? "Meeting men" : "Meeting women", systemImage: "sparkles")
                    Spacer()
                    Text("\(index % characters.count + 1) / \(characters.count)").monospacedDigit()
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.horizontal, 24)

                GeometryReader { geometry in
                    ZStack {
                        RoundedRectangle(cornerRadius: 30).fill(Color.vibePurple.opacity(0.1))
                            .padding(.horizontal, 9).offset(y: 9)
                        card(for: character)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
                            .offset(x: dragOffset.width, y: abs(dragOffset.width) * 0.05)
                            .rotationEffect(.degrees(Double(dragOffset.width / 30)))
                            .gesture(DragGesture(minimumDistance: 25)
                                .onChanged { value in
                                    if phase == .front { dragOffset = value.translation }
                                }
                                .onEnded { value in
                                    guard phase == .front else { return }
                                    if value.translation.width > 90 { beginQuestions(character) }
                                    else if value.translation.width < -90 { advance() }
                                    withAnimation(.spring(response: 0.4)) { dragOffset = .zero }
                                })
                    }
                }
                .padding(.horizontal, 20)

                controls(for: character)
                    .padding(.top, 5)
                    .padding(.bottom, 9)
            } else {
                ContentUnavailableView("More stories soon", systemImage: "sparkles", description: Text("No videos are available for this collection yet."))
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPreferences) { ProfileEditorView() }
        .onChange(of: appState.profile) { resetCard() }
        .task(id: phase) {
            guard let character else { return }
            if phase == .evaluating {
                do { try await Task.sleep(for: .milliseconds(1100)) } catch { return }
                if CompatibilityEngine.chemistryMatches(answers) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        phase = .success
                        rotation = 360
                    }
                } else {
                    appState.waitForReply(from: character, answers: answers.map(\.text))
                    withAnimation { phase = .waiting }
                }
            } else if phase == .success {
                do { try await Task.sleep(for: .milliseconds(750)) } catch { return }
                appState.accept(character)
                session.likeCandidate(character, profile: appState.profile)
            }
        }
    }

    private func card(for character: VirtualCharacter) -> some View {
        ZStack {
            if phase == .front || phase == .success {
                CharacterPortraitCard(character: character) {
                    HStack(spacing: 6) {
                        Image(systemName: phase == .success ? "heart.fill" : "sparkles")
                        Text(phase == .success ? "It's mutual" : "\(CompatibilityEngine.score(character, profile: appState.profile, weights: session.weights))% in tune")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(phase == .success ? Color.vibePink : .black.opacity(0.35), in: Capsule())
                }
            } else {
                cardBack(character)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.1), lineWidth: 1) }
        .shadow(color: .black.opacity(0.22), radius: 20, y: 12)
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
                }
            } else {
                WaitingResponseContent(character: character, evaluating: phase == .evaluating)
            }
        }
    }

    private func controls(for character: VirtualCharacter) -> some View {
        VStack(spacing: 10) {
            if phase == .front {
                HStack(spacing: 30) {
                    Button { advance() } label: {
                        Image(systemName: "xmark").font(.system(size: 22, weight: .medium))
                            .frame(width: 56, height: 56).background(.white.opacity(0.07), in: Circle())
                    }
                    .accessibilityLabel("Pass \(character.name)")
                    Button { beginQuestions(character) } label: {
                        Image(systemName: "heart.fill").font(.system(size: 29))
                            .frame(width: 74, height: 74)
                            .background(LinearGradient(colors: [.vibePink, .vibePurple], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                            .shadow(color: Color.vibePink.opacity(0.25), radius: 18, y: 6)
                    }
                    .accessibilityLabel("Like \(character.name)")
                    Button { appState.selectedTab = .likes } label: {
                        Image(systemName: "sparkles").font(.system(size: 21)).foregroundStyle(Color.vibeCyan)
                            .frame(width: 56, height: 56).background(.white.opacity(0.07), in: Circle())
                    }
                    .accessibilityLabel("See who likes you")
                }
                Text("Swipe to explore · tap ♥ to see if it clicks")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.38))
            } else if phase == .waiting {
                Button { advance() } label: {
                    Label("Keep exploring", systemImage: "arrow.right").font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity).padding(16).background(.white.opacity(0.08), in: Capsule())
                }.padding(.horizontal, 28)
                Text("Your invitation is saved in Messages").font(.caption2).foregroundStyle(.white.opacity(0.4))
            } else if phase == .questions {
                Button("Back to their profile") { resetCard() }.font(.caption).foregroundStyle(.white.opacity(0.55)).padding(18)
            } else {
                Text(phase == .success ? "Something clicked. Meet \(character.name)." : "Finding your rhythm together…")
                    .font(.caption).foregroundStyle(.white.opacity(0.5)).padding(24)
            }
        }
    }

    private func beginQuestions(_ character: VirtualCharacter) {
        if appState.conversation(for: character.id) != nil {
            session.likeCandidate(character, profile: appState.profile)
            session.step = .chat
            return
        }
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
    }

    private func advance() {
        resetCard()
        withAnimation(.easeInOut(duration: 0.25)) { index = characters.isEmpty ? 0 : (index + 1) % characters.count }
    }
}

private struct CharacterPortraitCard<Badge: View>: View {
    let character: VirtualCharacter
    @ViewBuilder var badge: () -> Badge

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Image(character.discoveryImageName).resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                LinearGradient(stops: [.init(color: .clear, location: 0.35), .init(color: .black.opacity(0.92), location: 1)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 7) {
                        Circle().fill(Color.vibeCyan).frame(width: 6, height: 6)
                        Text("AI COMPANION").font(.system(size: 9, weight: .bold)).tracking(1.7)
                    }.foregroundStyle(.white.opacity(0.8))
                    Text(character.name).font(.system(size: 38, weight: .bold, design: .rounded)).tracking(-0.9)
                    Text(character.headline).font(.subheadline).foregroundStyle(.white.opacity(0.78)).lineLimit(2)
                    HStack(spacing: 6) {
                        ForEach(character.tags.prefix(3), id: \.self) { tag in
                            Text(tag).font(.system(size: 10, weight: .medium)).padding(.horizontal, 9).padding(.vertical, 6)
                                .background(.white.opacity(0.12), in: Capsule())
                        }
                    }
                }.padding(22)
            }
            .overlay(alignment: .topLeading) { badge().padding(18) }
        }
    }
}

private struct WaitingResponseContent: View {
    let character: VirtualCharacter
    var evaluating = false
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
                Text(evaluating ? "Feeling out the chemistry" : "A little space for a spark")
                    .font(.system(size: 25, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
                Text(evaluating ? "Seeing how your worlds fit together…" : "Your invitation is with \(character.name).\nWaiting for their response.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.55)).multilineTextAlignment(.center)
                if !evaluating {
                    Text("Some connections take a little longer.").font(.caption).foregroundStyle(.white.opacity(0.35)).padding(.top, 4)
                }
            }
            if evaluating { ProgressView().tint(.vibePink) }
        }
        .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { pulse = true } }
    }
}

private struct LikesYouView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(DemoSession.self) private var session
    private var recommendations: [VirtualCharacter] {
        CompatibilityEngine.recommendations(from: appState.characters, profile: appState.profile, weights: session.weights)
            .filter { character in
                appState.conversation(for: character.id) == nil
                    && !appState.snapshot.invitations.contains { $0.characterID == character.id }
            }
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
                    }
                }.padding(17).datingSurface()
                if recommendations.isEmpty {
                    ContentUnavailableView("You're all caught up", systemImage: "heart", description: Text("Explore more profiles or adjust your preferences for a different kind of connection."))
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 16) {
                    ForEach(recommendations) { character in
                        VStack(alignment: .leading, spacing: 10) {
                            Image(character.discoveryImageName).resizable().scaledToFill()
                                .frame(height: 205).frame(maxWidth: .infinity).clipped()
                                .overlay(alignment: .topLeading) {
                                    Text("\(CompatibilityEngine.score(character, profile: appState.profile, weights: session.weights))% in tune")
                                        .font(.system(size: 10, weight: .semibold)).padding(8).background(.black.opacity(0.5), in: Capsule()).padding(10)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            Text(character.name).font(.headline)
                            Text(character.tags.prefix(2).joined(separator: " · ")).font(.caption2).foregroundStyle(.white.opacity(0.5))
                            Button {
                                appState.accept(character)
                                session.likeCandidate(character, profile: appState.profile)
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
                                    session.likeCandidate(character, profile: appState.profile)
                                    session.step = .chat
                                } label: {
                                    HStack(spacing: 13) {
                                        CharacterAvatar(character: character, size: 58)
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(character.name).font(.subheadline.weight(.semibold))
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
            ZStack { VibeBackground(); WaitingResponseContent(character: character) }
                .presentationDetents([.medium]).presentationDragIndicator(.visible)
        }
    }
}

private struct CharacterMomentsView: View {
    @Environment(DatingAppState.self) private var appState
    @State private var showAll = false
    @State private var commentingOn: VirtualCharacter?
    private var characters: [VirtualCharacter] { showAll ? VirtualCharacter.allCharacters : appState.characters }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DatingPageHeader(eyebrow: "LIFE BETWEEN HELLOS", title: "Moments", subtitle: "A glimpse into their world.")
                HStack(spacing: 10) {
                    feedFilter("For you", selected: !showAll) { showAll = false }
                    feedFilter("Everyone", selected: showAll) { showAll = true }
                    Spacer()
                }
                LazyVStack(spacing: 22) {
                    ForEach(Array(characters.enumerated()), id: \.element.id) { index, character in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 10) {
                                CharacterAvatar(character: character, size: 40)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(character.name).font(.subheadline.weight(.semibold))
                                    Text("\(index + 1)h ago · \(character.tags.first ?? "A small moment")").font(.caption2).foregroundStyle(.white.opacity(0.38))
                                }
                                Spacer()
                                Text("AI").font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.4))
                                    .padding(6).background(.white.opacity(0.06), in: Capsule())
                            }
                            Text(character.momentText).font(.subheadline).lineSpacing(4).foregroundStyle(.white.opacity(0.87))
                            Image(character.discoveryImageName).resizable().scaledToFill().frame(height: 290)
                                .frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 20))
                            HStack(spacing: 23) {
                                Button { appState.toggleLike(character.id) } label: {
                                    Label("\(24 + index * 7 + (appState.snapshot.likedPosts.contains(character.id) ? 1 : 0))", systemImage: appState.snapshot.likedPosts.contains(character.id) ? "heart.fill" : "heart")
                                        .foregroundStyle(appState.snapshot.likedPosts.contains(character.id) ? Color.vibePink : .white.opacity(0.5))
                                }
                                Button { commentingOn = character } label: {
                                    Label("\(appState.snapshot.comments[character.id, default: []].count)", systemImage: "bubble.right")
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                Text("\(character.tags.last ?? "A thought")").font(.caption2).foregroundStyle(.white.opacity(0.3))
                            }.font(.caption).buttonStyle(.plain)
                        }.padding(17).datingSurface()
                    }
                }
            }.padding(20)
        }
        .sheet(item: $commentingOn) { character in MomentCommentsView(character: character) }
    }

    private func feedFilter(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(.medium)).padding(.horizontal, 18).padding(.vertical, 10)
                .foregroundStyle(selected ? .white : .white.opacity(0.45))
                .background(selected ? Color.vibePink.opacity(0.2) : .white.opacity(0.04), in: Capsule())
        }.buttonStyle(.plain)
    }
}

private struct MomentCommentsView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let character: VirtualCharacter
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            ZStack {
                VibeBackground()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(character.momentText).font(.subheadline).foregroundStyle(.white.opacity(0.7)).padding(16).datingSurface()
                            if appState.snapshot.comments[character.id, default: []].isEmpty {
                                Text("Start the conversation.").font(.subheadline).foregroundStyle(.white.opacity(0.4)).padding(.top, 20)
                            }
                            ForEach(appState.snapshot.comments[character.id, default: []]) { comment in
                                HStack(alignment: .top, spacing: 12) {
                                    ProfileAvatar(profile: appState.profile, size: 34)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(comment.author).font(.caption.weight(.semibold))
                                        Text(comment.text).font(.subheadline).foregroundStyle(.white.opacity(0.8))
                                    }
                                    Spacer()
                                }
                            }
                        }.padding(20)
                    }
                    HStack {
                        TextField("Leave a thought…", text: $draft, axis: .vertical).lineLimit(1...3)
                        Button {
                            appState.comment(draft, on: character.id)
                            draft = ""
                        } label: { Image(systemName: "arrow.up.circle.fill").font(.title).foregroundStyle(Color.vibePink) }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }.padding(18).background(.white.opacity(0.05))
                }
            }
            .navigationTitle("\(character.name)'s moment").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}

private struct DatingProfileView: View {
    @Environment(DatingAppState.self) private var appState
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DatingPageHeader(eyebrow: "YOUR SIDE OF THE STORY", title: "Profile", subtitle: "Make space for the kind of connection you want.")
                VStack(spacing: 15) {
                    ProfileAvatar(profile: appState.profile, size: 100)
                        .overlay { Circle().stroke(Color.vibePink.opacity(0.5), lineWidth: 2).padding(-5) }
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
                    profileRow("Looking to meet", value: appState.profile.preference == "man" ? "Men" : "Women", icon: "heart")
                    profileRow("The energy", value: CompanionEnergy(rawValue: appState.profile.energy)?.title ?? "Calm", icon: "sparkles")
                    profileRow("Your style", value: appState.profile.communication, icon: "bubble.left")
                    profileRow("Ideal moment", value: PerfectMoment(rawValue: appState.profile.moment)?.title ?? "Late coffee", icon: "moon.stars")
                }.padding(20).datingSurface()

                VStack(alignment: .leading, spacing: 13) {
                    Text("Little things you love").font(.headline)
                    Text(appState.profile.interests.isEmpty ? "Add a few interests to your profile." : appState.profile.interests.joined(separator: "   ·   "))
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6)).lineSpacing(6)
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading).datingSurface()

                HStack {
                    Label("\(appState.snapshot.conversations.count) \(appState.snapshot.conversations.count == 1 ? "connection" : "connections")", systemImage: "heart.text.square")
                    Spacer()
                    Text("Your story is just beginning")
                }.font(.system(size: 10)).foregroundStyle(.white.opacity(0.35))
            }.padding(20)
        }
        .sheet(isPresented: $showingEditor) { ProfileEditorView() }
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
                    Stepper("Age: \(draft.age)", value: $draft.age, in: 18...100)
                    TextField("City", text: $draft.city)
                    TextField("Your bio", text: $draft.bio, axis: .vertical).lineLimit(3...5)
                }
                Section("Connection preferences") {
                    Picker("I'd like to meet", selection: $draft.preference) {
                        Text("Women").tag("woman"); Text("Men").tag("man")
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
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft.hasOnboarded = true
                        appState.updateProfile(draft)
                        session.applyProfile(draft, store: store)
                        dismiss()
                    }.fontWeight(.semibold)
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loadingPhoto)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { draft = appState.profile }
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

private struct CharacterAvatar: View {
    let character: VirtualCharacter
    let size: CGFloat
    var body: some View {
        Image(character.discoveryImageName).resizable().scaledToFill().frame(width: size, height: size).clipShape(Circle())
            .overlay { Circle().stroke(.white.opacity(0.12)) }
    }
}

private struct ProfileAvatar: View {
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

private struct DatingPageHeader: View {
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

private extension View {
    func datingSurface() -> some View {
        background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.065)) }
    }
    func sectionEyebrow() -> some View {
        font(.system(size: 10, weight: .semibold)).tracking(1.4).foregroundStyle(.white.opacity(0.4))
    }
}
