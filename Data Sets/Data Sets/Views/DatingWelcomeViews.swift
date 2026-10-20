import SwiftUI
import PhotosUI
import UIKit

struct DatingLoginView: View {
    @Environment(DatingAppState.self) private var appState
    @State private var email = ""
    @State private var error: String?
    @State private var editingEmail = false
    @State private var emailController = EmailInputController()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VibeWordmark(compact: true).padding(.top, 18)
                if !editingEmail {
                    ZStack {
                        Circle().fill(Color.vibePink.opacity(0.15)).frame(width: 235, height: 235).blur(radius: 35)
                        welcomePortrait("DiscoveryRiven", angle: -12).offset(x: -65, y: 10)
                        welcomePortrait("DiscoveryVictoria", angle: 10).offset(x: 68, y: -2)
                        Image(systemName: "heart.fill").font(.title2).foregroundStyle(.white)
                            .frame(width: 56, height: 56).background(Color.vibePink, in: Circle()).offset(y: 100)
                    }.frame(maxWidth: .infinity).frame(height: 260).padding(.top, 18)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("A spark starts\nwith hello.")
                        .font(.system(size: 43, weight: .bold, design: .rounded)).tracking(-1.4)
                    Text("Meet a personality, not just a profile.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.55))
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR EMAIL").font(.system(size: 10, weight: .semibold)).tracking(1.8).foregroundStyle(.white.opacity(0.45))
                    HStack(spacing: 10) {
                        EmailAddressInput(text: $email, controller: emailController,
                                          editingChanged: { editingEmail = $0 }, submit: continueToApp)
                        Button { emailController.insertAtSign() } label: {
                            Text("@").font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(Color.vibePink).frame(width: 38, height: 34)
                                .background(Color.vibePink.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                        }
                        .buttonStyle(.plain).accessibilityLabel("Insert @")
                        .accessibilityIdentifier("insert-email-at-sign")
                    }
                    .padding(15).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                    .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.12)) }
                    if let error { Text(error).font(.caption).foregroundStyle(Color.vibePink) }
                    FilledActionButton(title: "Continue with email", symbol: "arrow.right", action: continueToApp)
                        .accessibilityIdentifier("login-continue")
                    Text("An AI companion experience for your kind of connection.")
                        .font(.caption).foregroundStyle(.white.opacity(0.4)).frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 5)
                }
                Text("CLASS DEMO · Local sign-in, no password required")
                    .font(.system(size: 9, weight: .medium)).tracking(0.5)
                    .foregroundStyle(.white.opacity(0.3)).frame(maxWidth: .infinity).padding(.vertical, 14)
            }.padding(.horizontal, 25)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: email) { error = nil }
    }

    private func welcomePortrait(_ image: String, angle: Double) -> some View {
        Image(image).resizable().scaledToFill().frame(width: 145, height: 208).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 25)).overlay { RoundedRectangle(cornerRadius: 25).stroke(.white.opacity(0.14)) }
            .rotationEffect(.degrees(angle)).shadow(color: .black.opacity(0.3), radius: 15, y: 10)
    }

    private func continueToApp() {
        if let committed = emailController.commit() { email = committed }
        guard appState.signIn(email: email) else { error = "Enter an email address to continue."; return }
        editingEmail = false
    }
}

struct DatingProfileOnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(DatingAppState.self) private var appState
    @Environment(DemoSession.self) private var session
    @Environment(DataStore.self) private var store
    @State private var draft = DatingProfile()
    @State private var ageText = "24"
    @State private var step = 0
    @State private var movingForward = true
    @State private var photo: PhotosPickerItem?
    @State private var loadingPhoto = false
    @State private var photoError: String?
    private let interests = ["Music", "Art", "Coffee", "Books", "Gaming", "Travel", "Design", "Film", "Nature", "Food", "Fantasy", "Fitness"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    if step > 0 { changeStep(to: step - 1) }
                    else { appState.signOut() }
                } label: {
                    Image(systemName: "chevron.left").frame(width: 40, height: 40).background(.white.opacity(0.07), in: Circle())
                }.accessibilityLabel("Previous step")
                Spacer()
                Text("YOUR PROFILE · \(step + 1) OF 3").font(.system(size: 10, weight: .semibold)).tracking(1.4).foregroundStyle(.white.opacity(0.5))
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }.padding(.horizontal, 22).padding(.top, 12)
            HStack(spacing: 6) {
                ForEach(0..<3) { position in Capsule().fill(position <= step ? Color.vibePink : .white.opacity(0.1)).frame(height: 3) }
            }.padding(22)

            ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch step {
                        case 0: aboutYou
                        case 1: connectionPreferences
                        default: interestChoices
                        }
                    }.padding(.horizontal, 25).padding(.bottom, 25)
                }
                .scrollDismissesKeyboard(.interactively)
                .id(step)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .offset(x: movingForward ? 35 : -35).combined(with: .opacity),
                    removal: .offset(x: movingForward ? -35 : 35).combined(with: .opacity)
                ))
            }.clipped()

            VStack(spacing: 12) {
                FilledActionButton(title: step == 2 ? "Find my people" : "Continue", symbol: step == 2 ? "sparkles" : "arrow.right") {
                    if step < 2 { changeStep(to: step + 1) }
                    else { finish() }
                }
                .accessibilityIdentifier("onboarding-continue")
                .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ProfileAge.parse(ageText) == nil || loadingPhoto)
                .opacity(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ProfileAge.parse(ageText) == nil ? 0.4 : 1)
                Text(step == 2 ? "You can change these anytime." : "A few small details. A better first hello.")
                    .font(.caption2).foregroundStyle(.white.opacity(0.35))
            }.padding(22)
        }
        .buttonStyle(.plain)
        .onAppear {
            draft = appState.profile
            ageText = String(draft.age)
            if !draft.hasOnboarded { draft.name = "" }
        }
        .task(id: photo) {
            guard let photo else { return }
            loadingPhoto = true
            defer { loadingPhoto = false }
            do {
                guard let data = try await photo.loadTransferable(type: Data.self), let image = UIImage(data: data) else { photoError = "Try another photo, or add one later."; return }
                guard !Task.isCancelled else { return }
                draft.avatarData = (image.preparingThumbnail(of: CGSize(width: 400, height: 400)) ?? image).jpegData(compressionQuality: 0.8)
                photoError = nil
            } catch { if !Task.isCancelled { photoError = "You can add a photo later." } }
        }
    }

    private var aboutYou: some View {
        VStack(alignment: .leading, spacing: 22) {
            onboardingTitle(draft.hasOnboarded ? "Good to have\nyou back." : "Let's start\nwith you.",
                            subtitle: draft.hasOnboarded ? "A quick check of your details before your next hello." : "Just the basics. The rest can come naturally.")
            PhotosPicker(selection: $photo, matching: .images) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(.white.opacity(0.07))
                        if let data = draft.avatarData, let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else { Image(systemName: "camera.fill").font(.title2).foregroundStyle(Color.vibePink) }
                    }.frame(width: 76, height: 76).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 5) {
                        Text(loadingPhoto ? "Loading…" : draft.avatarData == nil ? "Add a photo" : "Change photo").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        Text("Optional · make it feel like you").font(.caption).foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            if let photoError { Text(photoError).font(.caption).foregroundStyle(Color.vibePink) }
            VStack(alignment: .leading, spacing: 8) {
                Text("What should we call you?").font(.subheadline.weight(.medium))
                TextField("Your first name", text: $draft.name).textContentType(.givenName).submitLabel(.done)
                    .padding(17).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 17))
                    .accessibilityIdentifier("onboarding-name")
            }
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your age").font(.subheadline.weight(.medium))
                    Text("Type your age · 18–100").font(.caption).foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                ProfileAgeField(text: $ageText)
            }.padding(17).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 17))
        }
    }

    private var connectionPreferences: some View {
        VStack(alignment: .leading, spacing: 16) {
            onboardingTitle("Your kind\nof connection.", subtitle: "Who would you like to get to know?")
            HStack(spacing: 12) {
                selectionTile("Women", symbol: "sparkles", selected: draft.preference == "woman") { draft.preference = "woman" }
                selectionTile("Men", symbol: "moon.stars", selected: draft.preference == "man") { draft.preference = "man" }
                selectionTile("Both", symbol: "heart.circle", selected: draft.preference == "both") { draft.preference = "both" }
            }
            Text("What sounds good right now?").font(.headline).padding(.top, 8)
            ForEach(CompanionEnergy.allCases) { energy in
                Button { draft.energy = energy.rawValue } label: {
                    HStack(spacing: 13) {
                        Image(systemName: energy.symbol).foregroundStyle(Color.vibePink).frame(width: 25)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(energy.title).font(.subheadline.weight(.semibold))
                            Text(energy.detail).font(.caption).foregroundStyle(.white.opacity(0.45))
                        }
                        Spacer()
                        Image(systemName: draft.energy == energy.rawValue ? "checkmark.circle.fill" : "circle").foregroundStyle(draft.energy == energy.rawValue ? Color.vibePink : .white.opacity(0.2))
                    }.padding(13).background(.white.opacity(draft.energy == energy.rawValue ? 0.09 : 0.04), in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    private var interestChoices: some View {
        VStack(alignment: .leading, spacing: 22) {
            onboardingTitle("The little things\nyou love.", subtitle: "Pick a few. Good conversations start here.")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                ForEach(interests, id: \.self) { interest in
                    Button {
                        if draft.interests.contains(interest) { draft.interests.removeAll { $0 == interest } }
                        else { draft.interests.append(interest) }
                    } label: {
                        Text(interest).font(.subheadline.weight(.medium)).frame(maxWidth: .infinity).padding(.vertical, 15)
                            .foregroundStyle(draft.interests.contains(interest) ? .white : .white.opacity(0.5))
                            .background(draft.interests.contains(interest) ? Color.vibePink.opacity(0.3) : .white.opacity(0.05), in: Capsule())
                            .overlay { Capsule().stroke(draft.interests.contains(interest) ? Color.vibePink.opacity(0.6) : .white.opacity(0.08)) }
                    }
                    .accessibilityAddTraits(draft.interests.contains(interest) ? .isSelected : [])
                }
            }
            Label("A few favorites help us curate your first matches.", systemImage: "sparkles")
                .font(.caption).foregroundStyle(.white.opacity(0.4)).padding(.top, 12)
        }
    }

    private func onboardingTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 38, weight: .bold, design: .rounded)).tracking(-1.1)
            Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.5))
        }
    }

    private func selectionTile(_ title: String, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 13) { Image(systemName: symbol).font(.title2); Text(title).font(.headline) }
                .frame(maxWidth: .infinity).padding(.vertical, 17)
                .foregroundStyle(selected ? .white : .white.opacity(0.5))
                .background(selected ? Color.vibePink.opacity(0.2) : .white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22))
                .overlay { RoundedRectangle(cornerRadius: 22).stroke(selected ? Color.vibePink.opacity(0.6) : .white.opacity(0.08)) }
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func finish() {
        guard let age = ProfileAge.parse(ageText) else { return }
        draft.age = age
        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Confirming an existing profile must not silently reset custom settings.
        if !draft.hasOnboarded || draft.energy != appState.profile.energy {
            draft.communication = draft.energy == "playful" ? "Playful" : "Thoughtful"
        }
        if !draft.hasOnboarded || draft.interests != appState.profile.interests {
            draft.moment = draft.interests.contains("Coffee") ? "coffee" : draft.interests.contains("Music") ? "music" : "city"
        }
        draft.hasOnboarded = true
        session.applyProfile(draft, store: store)
        session.step = .analyzing
        appState.selectedTab = .discover
        appState.finishProfileSetup(draft)
    }

    private func changeStep(to next: Int) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        movingForward = next > step
        withAnimation(.smooth(duration: reduceMotion ? 0.15 : 0.38)) { step = next }
    }
}
