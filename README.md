# VibeMate — IDSN-533 Midterm Team 7

VibeMate is an iOS course demo for discovering and talking with virtual AI companions. The current version is a five-tab app with personality-aware matching, prerecorded character videos, persistent conversations, editable user profiles, and a character community feed.

## Current experience

First launch asks who the user wants to meet and two quick preference questions. Later launches restore the user's profile and open Discover directly.

- **Discover:** swipe through video-ready characters. Tap Like to flip a card into two character-specific questions. Answers with an affinity total of at least 3 out of 4 unlock the match animation, full-screen video, and chat. Less compatible answers show an animated waiting state and save a pending invitation in Messages.
- **Likes you:** high-compatibility AI recommendations (at least 80% in the demo scoring rules), excluding existing connections and pending invitations. Liking one goes directly to the match video without the questions.
- **Messages:** saved conversations, searchable by character name, plus pending invitations. Existing connections reopen the same chat history. Video replay is available in chat.
- **Moments:** a sample feed of posts written in each character's voice. Local likes and comments persist between launches; users can view the preferred collection or everyone.
- **Profile:** editable name, adult age, city, bio, local photo, companion preference, desired energy, ideal shared moment, communication style, and interests.

The six old discovery-only placeholders (Sora, Amara, Leila, Kai, Malik, Adrian) are no longer shown. Their original images remain in the repository. All 13 active characters have a bundled video and persona:

- Women: Victoria, Vivian, Lily, Selene, Charlie, Vaggie.
- Men: Riven, Loid, Dorian, Nightwing, Angel, Joon, Alastor.

The old requirement to keep Victoria and Riven fourth is superseded by removing the video-less placeholders. They now begin their respective collections.

## Matching and the original database

The original JSON datasets are preserved:

- **cards.json:** individual speed-date partner ratings.
- **participants.json:** participant profiles and preferences.
- **types.json:** 15 aggregate preference types derived from 8,378 interactions.

The original six traits are attractiveness, sincerity, intelligence, humor, ambition, and shared interests. The two onboarding signals weight these traits; DemoSession normalizes the vector and finds the closest dataset type by Euclidean distance.

CompatibilityEngine combines the character's weighted trait scores (55%), desired energy (30%), and the user's communication style (15%). The displayed percentage is a demo heuristic, not a calibrated probability or a scientific prediction of romantic compatibility. Profile preference changes immediately update the collection and recommendations.

The two card-back questions are authored for each character's personality. Each option has an affinity of 0, 1, or 2. Two completed answers totaling at least 3 produce a match; lower totals remain pending. This is deterministic, local logic rather than an API model deciding acceptance. Persona content controls chat voice; changing a persona in the editor does not automatically rewrite the curated questions or temperament mappings.

The Likes you screen is a simulated incoming-interest feature populated from compatible AI recommendations. Characters do not autonomously send likes. Pending invitations remain pending in this demo; no background service or delayed acceptance is implemented.

## Chat and persona content

Chat uses the existing OpenAI streaming client. Every request includes the character's structured persona and conversation history. The user's display name, bio, interests, and communication style are provided as user context. Avatar images remain on the device and are not sent to the chat API.

Without an API configuration, the local scripted mode still works. With a configuration, messages stream from the API; connection errors are shown without discarding earlier messages.

The temporary sliders button in the chat header opens Character content. Each character has background, personality, relationship dynamic, speaking style, interests and habits, and boundaries. Edits are saved locally and apply to subsequent replies. Set PersonaEditorAccess.isEnabled to false to hide this temporary entrance without removing persona loading.

The persona instruction structure follows [OpenAI's prompt engineering guidance](https://developers.openai.com/api/docs/guides/prompt-engineering) on separating instructions and contextual data.

## Persistence and demo scope

Profile details, a compressed avatar image, conversation messages, invitations, post likes, and comments are saved locally using Codable and UserDefaults. Character-content edits use their own existing local store. These survive normal app relaunches, but not app deletion, and are not synchronized across devices. No login or backend account is implemented.

Videos are supplied prerecorded content, not real-time generation. Community posts, timestamps, and baseline like counts are curated demo content; comments and extra likes belong only to this device. The existing matching dataset and earlier technical experiments support this app; the legacy long quiz is not the main interface.

The supplied Sample-pv and Sample-heartbeat media is bundled with the app. Existing Victoria and Riven videos are reused rather than duplicated.

## Run in Xcode

1. Open **Data Sets/Data Sets.xcodeproj**.
2. Choose the **Data Sets** scheme and an iPhone simulator.
3. Run with **⌘R**.

Requires iOS 17+. All features other than live chat work locally.

Run the local model checks on macOS with Xcode installed: `bash Tests/run-state-checks.sh`.

## Local API configuration

Copy **Data Sets/APIConfig.example.plist** to **Data Sets/Data Sets/APIConfig.plist**, beside FindYourTypeApp.swift, and fill in your own OpenAI key and model. Xcode automatically bundles it. APIConfig.plist is gitignored and must never be committed. An OPENAI_API_KEY scheme environment variable is also supported. The existing local configuration is retained.

## Main files

- **Models/DatingAppState.swift:** profile, persistent conversations/invitations/community state, character collections, compatibility rules, and per-character questions.
- **Views/DatingAppViews.swift:** five-tab shell, adaptive discovery card and flip, questions, pending animation, Likes you, Messages, Moments, and profile/photo editor.
- **Views/VibeMateDemo.swift:** onboarding, calculation, full-screen video, live chat, and persona editor.
- **Models/DemoModels.swift:** characters, dataset weighting, match model, and flow state.
- **Models/PersonaContent.swift:** structured persona content and temporary editor access.
- **Models/CompanionChatService.swift:** streaming API client and persona prompt.
- **Resources/Personas/**, **Resources/Videos/**, **Assets.xcassets/**: character content and media.
- **Tests/DatingStateChecks.swift:** local checks for character gates, invitation isolation, persisted chats/profile/community state, and recommendation coverage.

All Models and Views paths above are relative to **Data Sets/Data Sets/**.

## Guidance for AI coding assistants

Treat the five-tab VibeMate flow as the current product. Preserve the original JSON data and team assets. Do not restore video-less placeholders or the old long questionnaire. Keep pending and matched states distinct; only matching or a direct Likes you acceptance unlocks video/chat. Do not fabricate historical conversations. Keep API keys untracked, and preserve unrelated teammate changes.
