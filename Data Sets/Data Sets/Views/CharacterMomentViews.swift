import SwiftUI

struct CharacterMomentsView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(DemoSession.self) private var session
    @Environment(DataStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showAll = false
    @State private var selectedCharacter: VirtualCharacter?
    @State private var likeAfterDismiss: VirtualCharacter?
    private var feeds: MomentFeedSelection {
        appState.momentFeeds(baseWeights: session.weights, participants: store.participants)
    }
    private var posts: [CharacterMoment] {
        MomentCatalog.feed(authorIDs: showAll ? feeds.exploreIDs : feeds.forYouIDs)
    }

    var body: some View {
        ScrollViewReader { scroll in
          ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                DatingPageHeader(eyebrow: "LIFE BETWEEN HELLOS", title: "Moments", subtitle: "A little more of the person behind the profile.")
                    .id("moments-top")
                HStack(spacing: 10) {
                    filter("For you", selected: !showAll) { showAll = false }
                    filter("Explore", selected: showAll) { showAll = true }
                    Spacer()
                    Image(systemName: "sparkle").foregroundStyle(Color.vibePink.opacity(0.7))
                }
                VStack(alignment: .leading, spacing: 7) {
                    Label(showAll ? "Outside your usual circle" : "Closer to your world",
                          systemImage: showAll ? "safari" : "heart.text.clipboard")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
                    Text(showAll ? "New faces in your preferences, with stories you haven't seen in For you."
                         : "Your connections, people you've liked, and a few picks based on your profile.")
                        .font(.caption).foregroundStyle(.white.opacity(0.45)).fixedSize(horizontal: false, vertical: true)
                }
                .id("intro-\(showAll)").transition(.opacity)
                if posts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: showAll ? "checkmark.seal" : "sparkles").font(.title).foregroundStyle(Color.vibePink)
                        Text(showAll ? "You're all caught up." : "Your world starts with a hello.").font(.headline)
                        Text(showAll ? "Your current circle is in For you. Adjust your preferences to discover more people."
                             : "Meet someone in Discover, or update your preferences to find your people.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 45)
                } else {
                    LazyVStack(spacing: 23) {
                        ForEach(posts) { post in
                            MomentPostRow(post: post) { selectedCharacter = post.character }
                        }
                    }
                    .id("posts-\(showAll)").transition(.opacity)
                }
                Text("Fictional moments · AI-created imagery")
                    .font(.caption2).foregroundStyle(.white.opacity(0.3)).frame(maxWidth: .infinity).padding(.vertical, 8)
            }.padding(20)
          }
          .onChange(of: showAll) { scroll.scrollTo("moments-top", anchor: .top) }
        }
        .animation(.easeInOut(duration: reduceMotion ? 0.1 : 0.25), value: showAll)
        .sheet(item: $selectedCharacter, onDismiss: {
            if let character = likeAfterDismiss {
                likeAfterDismiss = nil
                appState.requestCharacterLike(character)
            }
        }) { character in
            CharacterProfileDetailView(character: character) { likeAfterDismiss = character }
        }
    }

    private func filter(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(.semibold)).padding(.horizontal, 18).padding(.vertical, 11)
                .foregroundStyle(selected ? .white : .white.opacity(0.45))
                .background(selected ? Color.vibePink.opacity(0.22) : .white.opacity(0.04), in: Capsule())
                .overlay { Capsule().stroke(selected ? Color.vibePink.opacity(0.3) : .clear) }
        }.buttonStyle(.plain)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The feed and profile share one post model, so likes and comments stay in sync.
struct MomentPostRow: View {
    @Environment(DatingAppState.self) private var appState
    let post: CharacterMoment
    var openProfile: (() -> Void)?
    @State private var commenting = false
    @State private var viewingImage = false
    private var liked: Bool { appState.snapshot.likedPosts.contains(post.id) }
    private var comments: [MomentComment] { appState.snapshot.comments[post.id, default: []] }

    var body: some View {
        if let character = post.character {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 11) {
                    if let openProfile {
                        Button(action: openProfile) { author(character) }
                    } else { author(character) }
                    Spacer()
                    Text("AI").font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.4))
                        .padding(7).background(.white.opacity(0.06), in: Capsule())
                }
                Text(post.caption).font(.subheadline).lineSpacing(4).foregroundStyle(.white.opacity(0.87))
                    .fixedSize(horizontal: false, vertical: true)
                Button { viewingImage = true } label: {
                    Image(post.imageName).resizable().scaledToFit()
                        .frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 18))
                }.accessibilityLabel("View photo: \(post.location)")
                Label(post.location, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.37))
                HStack(spacing: 22) {
                    Button { withAnimation(.spring(response: 0.3)) { appState.toggleLike(post.id) } } label: {
                        Label(liked ? "Liked" : "Like", systemImage: liked ? "heart.fill" : "heart")
                            .foregroundStyle(liked ? Color.vibePink : .white.opacity(0.5))
                            .symbolEffect(.bounce, value: liked)
                    }.accessibilityLabel(liked ? "Unlike moment" : "Like moment")
                    Button { commenting = true } label: {
                        Label(comments.isEmpty ? "Comment" : "\(comments.count)", systemImage: "bubble.right")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                }.font(.caption).padding(.top, 2)
            }.padding(17).datingSurface().buttonStyle(.plain)
                .sheet(isPresented: $commenting) { MomentCommentsView(post: post) }
                .sheet(isPresented: $viewingImage) { MomentPhotoView(post: post) }
        }
    }

    private func author(_ character: VirtualCharacter) -> some View {
        HStack(spacing: 11) {
            CharacterAvatar(character: character, size: 41)
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Text(post.hoursAgo < 24 ? "\(post.hoursAgo)h ago" : "\(post.hoursAgo / 24)d ago")
                    .font(.caption2).foregroundStyle(.white.opacity(0.38))
            }
        }
    }
}

private struct MomentPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    let post: CharacterMoment
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 25) {
                HStack {
                    Text(post.character?.name ?? "").font(.headline)
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.white.opacity(0.6)) }
                        .accessibilityLabel("Close photo")
                }.padding(.horizontal, 22)
                Spacer(minLength: 0)
                Image(post.imageName).resizable().scaledToFit()
                Text(post.caption).font(.subheadline).foregroundStyle(.white.opacity(0.7)).padding(.horizontal, 24)
                Spacer(minLength: 0)
            }.padding(.vertical, 25)
        }.preferredColorScheme(.dark)
    }
}

private struct MomentCommentsView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let post: CharacterMoment
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            ZStack {
                VibeBackground()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            Text(post.caption).font(.subheadline).foregroundStyle(.white.opacity(0.7)).padding(17).datingSurface()
                            if appState.snapshot.comments[post.id, default: []].isEmpty {
                                Text("Be the first to leave a thought.").font(.subheadline).foregroundStyle(.white.opacity(0.4)).padding(.top, 20)
                            }
                            ForEach(appState.snapshot.comments[post.id, default: []]) { comment in
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
                            appState.comment(draft, on: post.id)
                            draft = ""
                        } label: { Image(systemName: "arrow.up.circle.fill").font(.title).foregroundStyle(Color.vibePink) }
                            .accessibilityLabel("Post comment")
                            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }.padding(18).background(.white.opacity(0.05))
                }
            }
            .navigationTitle("\(post.character?.name ?? "Their")'s moment").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}

struct CharacterProfileDetailView: View {
    @Environment(DatingAppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let character: VirtualCharacter
    let onLike: () -> Void
    @State private var expandedAbout = false
    @State private var showingDM = false
    @State private var sentDM = false
    private var persona: PersonaContent { PersonaContentStore.load(for: character) }
    private func readable(_ text: String) -> String {
        text.components(separatedBy: .newlines).map {
            $0.hasPrefix("- ") ? String($0.dropFirst(2)) : $0
        }.filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VibeBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        GeometryReader { geometry in
                            ZStack(alignment: .bottomLeading) {
                                Image(character.profileImageName).resizable().scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top).clipped()
                                LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                                VStack(alignment: .leading, spacing: 10) {
                                    Label("AI COMPANION", systemImage: "sparkles").font(.system(size: 9, weight: .bold)).tracking(1.5).foregroundStyle(Color.vibeCyan)
                                    Text(character.name).font(.system(size: 37, weight: .bold, design: .rounded))
                                    Text(character.headline).font(.subheadline).foregroundStyle(.white.opacity(0.8))
                                }.padding(23)
                            }.clipShape(RoundedRectangle(cornerRadius: 27))
                        }.frame(height: 390)
                        VStack(alignment: .leading, spacing: 15) {
                            Label(String(character.location.components(separatedBy: " · ").first ?? character.location), systemImage: "mappin.circle")
                                .font(.caption).foregroundStyle(.white.opacity(0.55))
                            Text("About \(character.name)").font(.title3.bold())
                            Text(readable(persona.background)).font(.subheadline).lineSpacing(5)
                                .foregroundStyle(.white.opacity(0.67)).lineLimit(expandedAbout ? nil : 5)
                            Button(expandedAbout ? "A little less" : "Get to know me") { withAnimation { expandedAbout.toggle() } }
                                .font(.caption.weight(.semibold)).foregroundStyle(Color.vibePink)
                            HStack(spacing: 7) {
                                ForEach(character.tags, id: \.self) { tag in
                                    Text(tag).font(.system(size: 10, weight: .medium)).padding(.horizontal, 10).padding(.vertical, 8)
                                        .background(Color.vibePink.opacity(0.12), in: Capsule())
                                }
                            }
                            Text("My energy").font(.headline).padding(.top, 7)
                            Text(readable(persona.personality).components(separatedBy: "\n\n").first ?? character.headline)
                                .font(.subheadline).lineSpacing(4).foregroundStyle(.white.opacity(0.65))
                        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).datingSurface()
                        HStack(alignment: .firstTextBaseline) {
                            Text("Life lately").font(.title2.bold())
                            Spacer()
                            Text("3 recent moments").font(.caption).foregroundStyle(.white.opacity(0.4))
                        }
                        ForEach(MomentCatalog.recent(for: character.id).prefix(3)) { MomentPostRow(post: $0) }
                        Text("A fictional character. A new kind of connection.")
                            .font(.caption2).foregroundStyle(.white.opacity(0.3)).frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.padding(20)
                }
            }
            .navigationTitle("Get to know \(character.name)").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Close profile") }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if sentDM {
                        Label("Your DM is saved in Messages", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(Color.vibeCyan)
                    }
                    HStack(spacing: 12) {
                        Button { dismiss(); onLike() } label: {
                            Label("Like", systemImage: "heart.fill").font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity).padding(.vertical, 17)
                                .background(LinearGradient(colors: [.vibePink, .vibePurple], startPoint: .leading, endPoint: .trailing), in: Capsule())
                        }.accessibilityLabel("Like \(character.name)")
                        Button { showingDM = true } label: {
                            Label("DM", systemImage: "paperplane.fill").font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vibeCyan)
                                .frame(maxWidth: .infinity).padding(.vertical, 17)
                                .background(.white.opacity(0.07), in: Capsule())
                                .overlay { Capsule().stroke(Color.vibeCyan.opacity(0.25)) }
                        }.accessibilityLabel("Send \(character.name) a DM")
                    }
                }
                .buttonStyle(.plain).padding(.horizontal, 22).padding(.vertical, 13).background(.ultraThinMaterial)
            }
            .sheet(isPresented: $showingDM) {
                CharacterNoteComposer(character: character) { text in
                    appState.leaveIntroduction(text, for: character)
                    appState.recordLike(character)
                    sentDM = true
                }
            }
        }.preferredColorScheme(.dark)
    }
}

struct CharacterNoteComposer: View {
    @Environment(\.dismiss) private var dismiss
    let character: VirtualCharacter
    let send: (String) -> Void
    @State private var draft = ""
    private var cleaned: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ZStack {
                VibeBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 23) {
                        HStack(spacing: 14) {
                            CharacterAvatar(character: character, size: 66)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("A note for \(character.name)").font(.title3.bold())
                                Text("A small hello goes a long way.").font(.caption).foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        TextField("What caught your attention?", text: $draft, axis: .vertical).lineLimit(5...8)
                            .padding(18).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
                            .onChange(of: draft) { if draft.count > 280 { draft = String(draft.prefix(280)) } }
                            .accessibilityIdentifier("character-note")
                        HStack {
                            Text("Your note will be saved in Messages.").font(.caption).foregroundStyle(.white.opacity(0.45))
                            Spacer()
                            Text("\(draft.count)/280").font(.caption2.monospacedDigit()).foregroundStyle(.white.opacity(0.3))
                        }
                        FilledActionButton(title: "Send a little hello", symbol: "paperplane.fill") { send(cleaned); dismiss() }
                            .disabled(cleaned.isEmpty).opacity(cleaned.isEmpty ? 0.4 : 1)
                        Text("A note starts a conversation, not an instant match. Grow your connection in chat to unlock their video.")
                            .font(.caption).lineSpacing(4).foregroundStyle(.white.opacity(0.35))
                    }.padding(24)
                }.scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Leave a note").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}
