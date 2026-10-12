import SwiftUI
import AVKit

struct VibeMateFlowView: View {
    @Environment(DataStore.self) private var store
    @State private var session = DemoSession()

    var body: some View {
        ZStack {
            VibeBackground()

            switch session.step {
            case .question:
                OpeningQuestionView()
            case .quickQuestions:
                QuickSignalQuestionsView(store: store)
            case .analyzing:
                MatchingCalculationView(store: store)
            case .discovery:
                CharacterDiscoveryView()
            case .video:
                if let match = session.match {
                    FullScreenMessageVideoView(character: match.character)
                }
            case .chat:
                if let match = session.match {
                    CompanionChatView(match: match)
                }
            }
        }
        .environment(session)
        .preferredColorScheme(.dark)
        .animation(.smooth(duration: 0.42), value: session.step)
    }
}

// MARK: - Shared visual system

private struct VibeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.025, blue: 0.08),
                    Color(red: 0.13, green: 0.045, blue: 0.14),
                    Color(red: 0.028, green: 0.025, blue: 0.065),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.vibePink.opacity(0.17))
                .frame(width: 340, height: 340)
                .blur(radius: 95)
                .offset(x: 180, y: -330)

            Circle()
                .fill(Color.vibePurple.opacity(0.13))
                .frame(width: 360, height: 360)
                .blur(radius: 105)
                .offset(x: -190, y: 340)
        }
        .ignoresSafeArea()
    }
}

private struct VibeWordmark: View {
    var compact = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.vibePink, Color.vibePurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: compact ? 14 : 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: compact ? 34 : 42, height: compact ? 34 : 42)

            Text("VibeMate")
                .font(.system(size: compact ? 21 : 26, weight: .bold, design: .rounded))
        }
    }
}

private struct FilledActionButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [Color.vibePink, Color.vibePurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .shadow(color: Color.vibePink.opacity(0.28), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private extension Color {
    static let vibePink = Color(red: 1.0, green: 0.27, blue: 0.55)
    static let vibePurple = Color(red: 0.57, green: 0.31, blue: 1.0)
    static let vibeCyan = Color(red: 0.28, green: 0.83, blue: 0.94)
}

// MARK: - Step 1: one question

private struct OpeningQuestionView: View {
    @Environment(DemoSession.self) private var session
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VibeWordmark()
                .padding(.top, 14)

            Spacer(minLength: 34)

            VStack(alignment: .leading, spacing: 12) {
                Text("One question.")
                    .font(.subheadline.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.vibePink)

                Text("Who do you want\nto meet tonight?")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .tracking(-1.2)

                Text("Choose once. We’ll take care of the rest.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)

            Spacer(minLength: 34)

            VStack(spacing: 14) {
                ForEach(PreferredCompanion.allCases) { preference in
                    PreferenceButton(preference: preference) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            session.choose(preference)
                        }
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 28)

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Curated from 8,378 real connection moments")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.42))
            .frame(maxWidth: .infinity)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 22)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

private struct PreferenceButton: View {
    let preference: PreferredCompanion
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 17) {
                Image(systemName: preference.symbol)
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(
                            colors: [Color.vibePink.opacity(0.9), Color.vibePurple.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(preference.title)
                        .font(.title3.bold())
                    Text(preference.detail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.07), in: Circle())
            }
            .padding(16)
            .foregroundStyle(.white)
            .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.09))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Two lightweight signals

private struct QuickSignalQuestionsView: View {
    @Environment(DemoSession.self) private var session
    let store: DataStore
    @State private var questionIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    if questionIndex == 0 {
                        session.step = .question
                    } else {
                        withAnimation {
                            questionIndex = 0
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()
                Text("SIGNAL \(questionIndex + 1) OF 2")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Color.clear.frame(width: 42, height: 42)
            }

            HStack(spacing: 7) {
                Capsule()
                    .fill(Color.vibePink)
                Capsule()
                    .fill(questionIndex == 1 ? Color.vibePink : Color.white.opacity(0.16))
            }
            .frame(height: 5)
            .padding(.top, 12)

            Spacer(minLength: 38)

            VStack(alignment: .leading, spacing: 10) {
                Text(questionIndex == 0 ? "How should tonight feel?" : "Pick one small moment.")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                Text(questionIndex == 0
                     ? "Go with your first instinct."
                     : "This helps us tune the match.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.56))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 30)

            VStack(spacing: 13) {
                if questionIndex == 0 {
                    ForEach(CompanionEnergy.allCases) { energy in
                        SignalOptionCard(
                            symbol: energy.symbol,
                            title: energy.title,
                            detail: energy.detail
                        ) {
                            session.selectedEnergy = energy
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                                questionIndex = 1
                            }
                        }
                    }
                } else {
                    ForEach(PerfectMoment.allCases) { moment in
                        SignalOptionCard(
                            symbol: moment.symbol,
                            title: moment.title,
                            detail: moment.detail
                        ) {
                            session.selectedMoment = moment
                            session.finishQuestions(store: store)
                        }
                    }
                }
            }

            Spacer()

            Text("Two taps. No long questionnaire.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
    }
}

private struct SignalOptionCard: View {
    let symbol: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(Color.vibePink)
                    .frame(width: 54, height: 54)
                    .background(Color.vibePink.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.54))
                }

                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(16)
            .foregroundStyle(.white)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(.white.opacity(0.08))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Brief calculation moment

private struct MatchingCalculationView: View {
    @Environment(DemoSession.self) private var session
    let store: DataStore
    @State private var rotate = false
    @State private var pulse = false
    @State private var phase = 0

    private let messages = [
        "Reading your signals",
        "Comparing 15 preference patterns",
        "Curating your four companions",
        "Your matches are ready",
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            ring == 1 ? Color.vibePink.opacity(0.3) : Color.vibePurple.opacity(0.2),
                            lineWidth: 1
                        )
                        .frame(width: CGFloat(155 + ring * 65), height: CGFloat(155 + ring * 65))
                }

                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(index <= phase * 4 ? Color.vibePink : Color.white.opacity(0.24))
                        .frame(width: index.isMultiple(of: 3) ? 9 : 6)
                        .offset(y: index.isMultiple(of: 2) ? -143 : -110)
                        .rotationEffect(.degrees(Double(index) * 30 + (rotate ? 360 : 0)))
                }

                Circle()
                    .fill(LinearGradient(
                        colors: [Color.vibePink, Color.vibePurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 112, height: 112)
                    .scaleEffect(pulse ? 1.08 : 0.93)
                    .shadow(color: Color.vibePink.opacity(0.45), radius: 28)
                    .overlay {
                        Image(systemName: phase == 3 ? "checkmark" : "waveform.path.ecg")
                            .font(.system(size: 37, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            }
            .frame(height: 340)

            VStack(spacing: 9) {
                Text(messages[phase])
                    .font(.title2.bold())
                    .contentTransition(.numericText())
                Text("Powered by \(store.summary?.nDates ?? 8_378) real connection moments")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index <= phase ? Color.vibePink : Color.white.opacity(0.13))
                        .frame(width: index == phase ? 28 : 9, height: 7)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: phase)

            Spacer()
        }
        .task {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotate = true
            }
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                pulse = true
            }

            for nextPhase in 1...3 {
                try? await Task.sleep(for: .milliseconds(480))
                withAnimation(.easeInOut(duration: 0.25)) {
                    phase = nextPhase
                }
            }

            try? await Task.sleep(for: .milliseconds(420))
            if session.step == .analyzing {
                session.step = .discovery
            }
        }
    }
}

// MARK: - Step 2: visual character discovery

private struct CharacterDiscoveryView: View {
    @Environment(DemoSession.self) private var session
    @State private var cardAppeared = false
    @State private var liked = false
    @State private var selectedIndex = 0

    private var candidates: [CompanionCandidate] {
        CompanionCandidate.options(for: session.preferredCompanion)
    }

    private var currentCandidate: CompanionCandidate {
        candidates[min(selectedIndex, candidates.count - 1)]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    session.step = .question
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 42, height: 42)
                        .background(.black.opacity(0.24), in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()
                VibeWordmark(compact: true)
                Spacer()
                Color.clear.frame(width: 42, height: 42)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)

            TabView(selection: $selectedIndex) {
                ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                    DiscoveryCandidateCard(candidate: candidate)
                        .tag(index)
                        .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 595)
            .padding(.top, 10)
            .scaleEffect(cardAppeared ? 1 : 0.94)
            .opacity(cardAppeared ? 1 : 0)

            HStack(spacing: 7) {
                ForEach(candidates.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedIndex ? Color.vibePink : Color.white.opacity(0.2))
                        .frame(width: index == selectedIndex ? 24 : 7, height: 7)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: selectedIndex)
            .padding(.top, 12)

            Spacer(minLength: 4)

            HStack(spacing: 28) {
                Button {
                    moveToNextCandidate()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.74))
                        .frame(width: 62, height: 62)
                        .background(.white.opacity(0.08), in: Circle())
                        .overlay { Circle().stroke(.white.opacity(0.1)) }
                }
                .buttonStyle(.plain)

                Button {
                    if currentCandidate.isFeaturedMatch {
                        liked = true
                        Task {
                            try? await Task.sleep(for: .milliseconds(650))
                            session.likeCandidate()
                        }
                    } else {
                        moveToNextCandidate()
                    }
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 31, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 82, height: 82)
                        .background(
                            LinearGradient(
                                colors: [Color.vibePink, Color.vibePurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .shadow(color: Color.vibePink.opacity(0.48), radius: 22, y: 10)
                        .scaleEffect(liked ? 1.22 : 1)
                }
                .buttonStyle(.plain)

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Color.vibeCyan)
                    .frame(width: 62, height: 62)
                    .background(.white.opacity(0.08), in: Circle())
                    .overlay { Circle().stroke(.white.opacity(0.1)) }
            }
            .padding(.bottom, 4)

            Text(
                currentCandidate.isFeaturedMatch
                    ? "Tap the heart to meet \(currentCandidate.name)"
                    : "Swipe to explore · \(selectedIndex + 1) of \(candidates.count)"
            )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.46))
                .padding(.bottom, 12)
        }
        .overlay {
            if liked {
                ZStack {
                    Color.black.opacity(0.58)
                        .ignoresSafeArea()

                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(Color.vibePink.opacity(0.28))
                                .frame(width: 190, height: 190)
                                .blur(radius: 18)
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.vibePink, Color.vibePurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 112, height: 112)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 46))
                                .foregroundStyle(.white)
                        }

                        Text("It’s a match")
                            .font(.system(size: 35, weight: .bold, design: .rounded))
                        Text("\(currentCandidate.name) sent you a message")
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sensoryFeedback(.success, trigger: liked)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                cardAppeared = true
            }
        }
    }

    private func moveToNextCandidate() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            if selectedIndex < candidates.count - 1 {
                selectedIndex += 1
            } else {
                selectedIndex = 0
            }
        }
    }
}

private struct DiscoveryCandidateCard: View {
    let candidate: CompanionCandidate

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(candidate.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 595)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.08), .black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(candidate.isFeaturedMatch ? Color.vibePink : Color.green)
                        .frame(width: 8, height: 8)
                    Text(candidate.isFeaturedMatch ? "FEATURED SIGNAL MATCH" : "CURATED FOR YOU")
                        .font(.caption2.weight(.bold))
                        .tracking(1.35)
                }
                .foregroundStyle(.white.opacity(0.78))

                Text(candidate.name)
                    .font(.system(size: 42, weight: .bold, design: .rounded))

                Text(candidate.headline)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))

                Text(candidate.vibe)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.12))
        }
        .shadow(color: .black.opacity(0.42), radius: 24, y: 14)
    }
}

// MARK: - Full-screen message video

private struct FullScreenMessageVideoView: View {
    @Environment(DemoSession.self) private var session
    let character: VirtualCharacter
    @State private var player: AVPlayer
    @State private var videoMissing: Bool
    @State private var showVideo = false
    @State private var pulse = false

    init(character: VirtualCharacter) {
        self.character = character
        if let url = Bundle.main.url(forResource: character.videoName, withExtension: "mp4") {
            _player = State(initialValue: AVPlayer(url: url))
            _videoMissing = State(initialValue: false)
        } else {
            _player = State(initialValue: AVPlayer())
            _videoMissing = State(initialValue: true)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showVideo {
                if videoMissing {
                    ContentUnavailableView(
                        "Video unavailable",
                        systemImage: "video.slash",
                        description: Text("You can continue directly to chat.")
                    )
                } else {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                VStack {
                    LinearGradient(
                        colors: [.black.opacity(0.72), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 130)
                    .overlay(alignment: .top) {
                        HStack {
                            Button {
                                player.pause()
                                session.step = .discovery
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .frame(width: 42, height: 42)
                                    .background(.black.opacity(0.38), in: Circle())
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            VStack(spacing: 2) {
                                Text("A MESSAGE FROM")
                                    .font(.caption2.weight(.bold))
                                    .tracking(1.3)
                                    .foregroundStyle(.white.opacity(0.58))
                                Text(character.name)
                                    .font(.headline)
                            }

                            Spacer()
                            Color.clear.frame(width: 42, height: 42)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                    }

                    Spacer()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 150)
                    .overlay(alignment: .bottom) {
                        Button {
                            player.pause()
                            session.step = .chat
                        } label: {
                            Label("Skip video · start chat", systemImage: "message.fill")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 17)
                                .padding(.vertical, 11)
                                .background(.black.opacity(0.5), in: Capsule())
                                .overlay { Capsule().stroke(.white.opacity(0.2)) }
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 18)
                    }
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.vibePink.opacity(0.2))
                            .frame(width: 240, height: 240)
                            .blur(radius: 24)
                            .scaleEffect(pulse ? 1.12 : 0.9)

                        Image(character.discoveryImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 128, height: 128)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.vibePink, Color.vibePurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            }
                            .shadow(color: Color.vibePink.opacity(0.4), radius: 24)

                        Image(systemName: "heart.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(Color.vibePink, in: Circle())
                            .offset(x: 48, y: 48)
                    }

                    VStack(spacing: 7) {
                        Text("You matched with \(character.name)")
                            .font(.system(size: 31, weight: .bold, design: .rounded))
                        Text("Opening a message just for you…")
                            .foregroundStyle(.white.opacity(0.56))
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .task {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulse = true
            }
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeInOut(duration: 0.45)) {
                showVideo = true
            }
            if !videoMissing {
                player.play()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: AVPlayerItem.didPlayToEndTimeNotification,
                object: player.currentItem
            )
        ) { _ in
            player.pause()
            session.step = .chat
        }
        .onDisappear {
            player.pause()
        }
    }
}

// MARK: - Companion chat (live OpenAI API, scripted fallback)

private struct DemoChatMessage: Identifiable, Hashable {
    enum Kind: Hashable { case user, companion, notice }

    let id = UUID()
    var text: String
    let kind: Kind

    var isUser: Bool { kind == .user }
}

private struct CompanionChatView: View {
    @Environment(DemoSession.self) private var session
    @Environment(DataStore.self) private var store
    let match: CompanionMatch
    @State private var messages: [DemoChatMessage]
    @State private var draft = ""
    @State private var isTyping = false
    @State private var usedQuickReply = false
    @State private var replyTask: Task<Void, Never>?
    private let chatService: CompanionChatService?

    private var character: VirtualCharacter { match.character }

    init(match: CompanionMatch) {
        self.match = match
        let service = ChatAPIConfig.load().map { CompanionChatService(config: $0) }
        self.chatService = service
        var initial = [DemoChatMessage(text: match.character.greeting, kind: .companion)]
        if service == nil {
            initial.insert(
                DemoChatMessage(
                    text: "Offline demo mode: add your API key to APIConfig.plist to chat live.",
                    kind: .notice
                ),
                at: 0
            )
        }
        _messages = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    replyTask?.cancel()
                    session.step = .discovery
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)

                Image(character.discoveryImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay { Circle().stroke(.white.opacity(0.18)) }

                VStack(alignment: .leading, spacing: 2) {
                    Text(character.name)
                        .font(.headline)
                    HStack(spacing: 5) {
                        Circle().fill(Color.green).frame(width: 7, height: 7)
                        Text(isTyping ? "typing…" : "online")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "video.fill")
                    .foregroundStyle(.white.opacity(0.68))
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.16))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("Today")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.38))
                            .padding(.vertical, 8)

                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        if isTyping && messages.last?.kind != .companion {
                            HStack {
                                TypingBubble()
                                Spacer(minLength: 100)
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.last?.text) {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            if !usedQuickReply {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(character.replyOptions, id: \.self) { option in
                            Button(option) {
                                usedQuickReply = true
                                send(option)
                            }
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.vibePurple.opacity(0.24), in: Capsule())
                            .overlay { Capsule().stroke(Color.vibePink.opacity(0.35)) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }

            HStack(spacing: 10) {
                TextField("Message \(character.name)…", text: $draft, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button {
                    let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !message.isEmpty, !isTyping else { return }
                    draft = ""
                    usedQuickReply = true
                    send(message)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.headline.weight(.bold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [Color.vibePink, Color.vibePurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .opacity(isTyping ? 0.45 : 1)
                }
                .buttonStyle(.plain)
                .disabled(isTyping)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(.black.opacity(0.18))
        }
        .onDisappear {
            replyTask?.cancel()
        }
    }

    private func send(_ text: String) {
        withAnimation {
            messages.append(DemoChatMessage(text: text, kind: .user))
            isTyping = true
        }

        if let chatService {
            replyTask = Task { await streamLiveReply(using: chatService) }
        } else {
            replyTask = Task { await scriptedReply(to: text) }
        }
    }

    /// Sends the whole conversation to the model and grows one bubble as text streams in.
    private func streamLiveReply(using service: CompanionChatService) async {
        var turns = [ChatTurn(role: .user, text: CompanionPrompt.openingTurn)]
        for message in messages {
            switch message.kind {
            case .user: turns.append(ChatTurn(role: .user, text: message.text))
            case .companion: turns.append(ChatTurn(role: .assistant, text: message.text))
            case .notice: break
            }
        }
        let system = CompanionPrompt.system(for: match, summary: store.summary)

        var bubbleIndex: Int?
        do {
            for try await chunk in service.streamReply(system: system, turns: turns) {
                if let index = bubbleIndex {
                    messages[index].text += chunk
                } else {
                    withAnimation {
                        messages.append(DemoChatMessage(text: chunk, kind: .companion))
                    }
                    bubbleIndex = messages.count - 1
                }
            }
        } catch is CancellationError {
            // The user left the chat; nothing to show.
        } catch {
            withAnimation {
                messages.append(DemoChatMessage(
                    text: "Couldn't reach \(character.name): \(error.localizedDescription)",
                    kind: .notice
                ))
            }
        }
        withAnimation { isTyping = false }
    }

    /// Offline fallback that keeps the classroom demo working without a key.
    private func scriptedReply(to text: String) async {
        try? await Task.sleep(for: .milliseconds(720))
        let reply = character.replies[text]
            ?? "I like where this is going. Add an API key and I can really talk with you."
        withAnimation {
            isTyping = false
            messages.append(DemoChatMessage(text: reply, kind: .companion))
        }
    }
}

private struct ChatBubble: View {
    let message: DemoChatMessage

    var body: some View {
        if message.kind == .notice {
            Text(message.text)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.05), in: Capsule())
                .frame(maxWidth: .infinity)
        } else {
            bubble
        }
    }

    private var bubble: some View {
        HStack {
            if message.isUser { Spacer(minLength: 64) }

            Text(message.text)
                .font(.body)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(
                    message.isUser
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color.vibePink, Color.vibePurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        : AnyShapeStyle(Color.white.opacity(0.09)),
                    in: RoundedRectangle(cornerRadius: 19, style: .continuous)
                )

            if !message.isUser { Spacer(minLength: 64) }
        }
    }
}

private struct TypingBubble: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(0.65))
                    .frame(width: 7, height: 7)
                    .scaleEffect(pulse ? 1 : 0.65)
                    .animation(
                        .easeInOut(duration: 0.55)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.14),
                        value: pulse
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.white.opacity(0.09), in: Capsule())
        .onAppear { pulse = true }
    }
}
