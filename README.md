# VibeMate — IDSN-533 Midterm Team 7

VibeMate is an iOS course demo for discovering and talking with fictional AI companions. This version builds on the team's database, hybrid recommendation algorithm, character personas, streaming chat API, and affinity system. Those existing resources serve the current VibeMate experience; they are not a separate product to restore over it.

## Current experience

1. **Welcome / demo sign-in:** enter an email to continue. A native UIKit input preserves hardware-keyboard/IME composition, offers an inline @ insert button at the cursor, and accepts normalized full-width email characters. This is a local classroom simulation, not verified email authentication. No password, OTP, server account, or cloud synchronization is implemented.
2. **A short profile setup:** after explicit sign-in, three lightweight screens confirm name/adult age/optional photo, who to meet (Women / Men / Both) and preferred energy, then interests. Existing details are prefilled, not erased. Login fades/slides into setup; steps crossfade and slide; completion flows through the matching animation into Discover. Reduced Motion uses shorter fades. Both includes all 13 video-ready characters and uses available dataset participants from both gender groups, with neutral initial trait weights. No long questionnaire; interests are preselected and can be changed or cleared. Ordinary relaunch with a completed, signed-in session skips setup; interrupted setup resumes. Existing installs confirm once when upgrading to this flow. Profile, photo, custom settings, and conversation history remain intact.
3. **Discover:** an edge-to-edge portrait replaces the old brand/header/settings rows. Profile text and five actions float over a graduated frosted/dark lower image; preferences remain in Profile. Swipe left to pass and right to like, with corresponding icon scaling and a pink LIKE glow. Tap the image for the character's profile and three recent Moments.
4. **Three connection routes:** existing incoming likes match immediately; a bounded subset of higher-fit characters shows a translucent waiting-for-reply notice (fade in, then automatically fade out and advance, with no confirmation tap); other new characters enter two persona-specific questions. A total of at least 3/4 starts the match animation and full-screen prerecorded video, then chat. Less aligned answers open a lower-affinity chat with video locked. Existing conversations reopen without resetting affinity.
5. **Keep connecting:** Messages restores conversation history; Likes you offers compatible recommendations; Moments shows characters' everyday lives; Profile edits the user's details, preferences, photo, and learning signals.

Discover's five controls, left to right:

- **Rewind:** revisit the previous choice and undo its recommendation learning while the current Discover view is active. Returning from chat can revisit a previous card without deleting the chat.
- **Pass:** move on and adjust future recommendations away from that character's traits.
- **Super like:** record a stronger positive preference, then use the same chemistry and affinity rules. It does not guarantee acceptance.
- **Like:** use the shared instant / awaiting reply / chemistry policy from every entrance, or reopen an existing conversation.
- **Leave a note:** send a short introduction (up to 280 characters), saved in Messages. A new note conversation starts at affinity 30 with video locked. The note itself does not automatically call the chat API.

The 13 active characters all have bundled videos and personas:

- Women: Victoria, Vivian, Lily, Selene, Charlie, Vaggie.
- Men: Riven, Loid, Dorian, Nightwing, Angel, Joon, Alastor.

Video-less placeholder characters are not shown; their original assets remain untouched. Discover order is algorithmic, not fixed to put Victoria or Riven fourth.

## Moments and character profiles

Each character has three curated posts written for their established personality: **39 distinct posts and 39 newly AI-generated scene images**. For example, Victoria shares gallery and flower-market moments; Riven shares his studio and record store; Selene shares the Lunaris archive. Images depict what the character might photograph, rather than reusing their profile portrait.

Moments has two distinct feeds, including when Both is selected:

- **For you:** existing conversations, pending/liked characters, plus a small number of profile-based picks from the same database-backed hybrid ranking used in Discover. New users start with up to three recommended authors. Recent conversations have priority when post timestamps tie.
- **Explore:** other, not-yet-featured authors within the user's companion preferences. Author/post pools do not overlap with For you. Passed characters are excluded from new suggestions; existing conversations stay in For you even after a preference change. If discovery is exhausted, an explicit empty state appears instead of duplicating For you. These bundled demo posts are not a live feed.

Tap an author's avatar/name to open their detail page: background/personality, interests/tags, location, and three recent posts. A sticky footer always offers **Like** and **DM**, including when opened from Discover. Like uses the same incoming-interest/chemistry rules as Discover; DM opens the same short-note composer and saves to Messages, without automatically unlocking video.

The feed and character detail page share post IDs, so likes and comments stay in sync. Old character-keyed likes and comments are migrated to the first post, preserving interactions and comment IDs.

These are bundled fictional demo posts, not a real social network or runtime image-generation service. Post times are illustrative relative times. Likes are local, with no fabricated public popularity counts.

Asset prompts and captions are recorded in **Design/MomentImagePrompts.json**. Generated assets are in **Data Sets/Data Sets/Assets.xcassets/Moment*.imageset/**. Generation used the built-in image-generation tool; no external fallback CLI was used.

## Matching and the original database

The original JSON datasets are preserved:

- **cards.json:** individual speed-date partner ratings.
- **participants.json:** participant profiles, interests, stated priorities, and revealed choices.
- **types.json:** aggregate preference types derived from the original interactions.

The six traits are attractiveness, sincerity, intelligence, humor, ambition, and shared interests. Profile preference and desired energy establish the starting weights; the selected interests also suggest a shared moment (coffee, music, or a city walk). DemoSession normalizes the weights and finds the closest dataset type.

The latest teammate's hybrid recommender remains active:

- **45% dataset prior:** find up to 25 similar participants and average their revealed preference weights.
- **35% personal fit:** profile-derived weights, adapted by likes, passes, matches, and engaged conversations.
- **20% interest overlap:** compare user interests with the character's curated interests.
- Item-to-item feedback further raises characters similar to liked ones and lowers those similar to passed ones. Super likes add a stronger positive learning update.

Displayed percentages are demo ranking heuristics, not calibrated probabilities or scientific predictions of romantic compatibility. The historical dataset's heterosexual speed-dating structure is a dataset limitation; the app asks who the user prefers, not the user's gender.

The displayed fit index now uses **clamp(25 + 0.75 × ranking value, 25…95)** instead of the old 60-point floor. Ranking components and their 45/35/20 shares are unchanged. Lower-fit profiles are not automatically excluded: answering their chemistry questions well can still produce a match.

A connection cohort is seeded and persisted per preference/energy/moment/communication/interests setup. Only a small incoming subset (one for a six/seven-person collection, two for Both) goes into Likes you. Used incoming likes are **not backfilled**. The next higher-ranked subset (up to one quarter of the original collection, max three) takes the awaiting-reply route. The remaining majority retains chemistry. With all profiles fresh, Both gives two incoming likes, three waiting-for-reply candidates, and eight chemistry candidates; this prevents similar scores or consumed likes from eliminating the questions.

The two card-back questions are curated local rules. Each answer contributes 0, 1, or 2. Totals 0/1/2/3/4 start affinity at 15/30/45/65/80 respectively. Editing a persona does not automatically regenerate these questions or the Moments.

## Chat, affinity, and video

The existing streaming API receives the character's structured persona, conversation history, user conversational profile, and affinity tone guidance. User avatar bytes and sign-in email are not sent in chat context.

The app owns affinity (0–100). The model can suggest a per-message change, clamped to -5…+10; reaching 60 unlocks the character's bundled video and preserves the unlock. Without API configuration, scripted replies and local fallback affinity changes keep the demo usable. Network errors do not discard prior messages.

Likes you simulates incoming interest, not autonomous character decisions. Every Like entrance uses the same saved cohort, evaluated before learning from the new swipe. Liking back starts affinity at 70 and goes directly to the video. Full-screen video supports a small Skip button; completion or skipping opens chat.

Awaiting reply saves a pending invitation in Messages, without fabricating a reply, conversation, affinity, or unlocked video. The notice takes approximately 2.25 seconds including fade-out, then advances automatically. New pending replies survive relaunch; legacy invitations still migrate to low-affinity chats as before. No timed acceptance or background reply service exists in this demo. Sending a deliberate DM can start a low-affinity conversation using the existing DM rules.

The temporary chat-header sliders button opens Character content. Background, personality, relationship dynamic, speaking style, habits, and boundaries are saved locally and used in subsequent model prompts. Set **PersonaEditorAccess.isEnabled = false** to hide direct editing later.

## Local data and demo limitations

Profile/photo, conversations, pending replies, connection cohorts, affinity, post interactions, recommendation feedback, and demo sign-in are stored on the device using Codable and UserDefaults. Persona edits use the existing local store. Normal relaunch restores them; deleting the app removes them. Sign-out only hides the local experience and retains profile and history.

Tap the avatar / **Add your photo** / **Change photo** directly on Profile to choose from the system photo picker or Files. The selected image is downsampled to a 400-pixel JPEG before saving, with image orientation respected. The original remains untouched. This local avatar is not uploaded to the chat API. Onboarding and Edit profile retain their existing photo picker too.

All entered demo emails share this installation's local profile. **This is not secure multi-user authentication or account separation.** Production needs verified sign-in, per-user backend storage, server-side API credentials, rate limits, reporting/moderation, privacy controls, and account deletion before public release. APIConfig is a development convenience, not a safe way to distribute a production secret.

Videos are prerecorded supplied content, not real-time generation. Moments are curated and generated in advance. No background character activity, real distance/location tracking, cloud chat sync, or actual dating service is implemented.

## Run in Xcode

1. Open **Data Sets/Data Sets.xcodeproj**.
2. Choose the **Data Sets** scheme and an iPhone simulator.
3. Run with **⌘R**.

Requires iOS 17+. All features except live model replies work locally. Explicit demo sign-in confirms a short, prefilled profile; ordinary relaunch skips completed setup. Age can be typed directly in onboarding and Edit profile, with whole-number validation from 18 to 100.

Run the local model checks on macOS with Xcode installed: `bash Tests/run-state-checks.sh`. Checks cover both match outcomes, old-data migration, login/logout, note persistence, unique Moment IDs, thread deduplication, recommendation behavior, and affinity/video unlock rules.

## Local API configuration

Copy **Data Sets/APIConfig.example.plist** to **Data Sets/Data Sets/APIConfig.plist**, beside FindYourTypeApp.swift, and fill in your own API key and model. Xcode automatically bundles it. **APIConfig.plist is gitignored and must never be committed.** An OPENAI_API_KEY scheme environment variable is also supported. Existing local configuration is retained.

## Main files

All Models and Views paths below are relative to **Data Sets/Data Sets/**.

- **Views/DatingWelcomeViews.swift:** demo login and short profile onboarding.
- **Views/EmailAddressInput.swift:** native keyboard/IME-safe email input and @ insertion.
- **Views/ProfilePhotoControl.swift:** Profile avatar import from Photos or Files, with downsampling.
- **Views/DatingAppViews.swift:** tabs, Discover gestures/actions, chemistry, Likes you, Messages, profile editing.
- **Views/CharacterMomentViews.swift:** shared Moments feed/posts/comments, character introduction, note composer.
- **Views/VibeMateDemo.swift:** root routing, calculation, video, live chat, persona editor.
- **Models/DatingAppState.swift:** local profile/auth state, conversations, community interactions, character gates.
- **Models/CharacterMoments.swift:** 39 stable post records.
- **Models/RecommendationEngine.swift:** teammate's dataset/personal/interest hybrid ranking and learning.
- **Models/AffinityRules.swift:** affinity changes, chat tone, video unlock threshold.
- **Models/DemoModels.swift:** character catalog, flow state, initial weighting.
- **Models/PersonaContent.swift**, **Models/CompanionChatService.swift:** character content and streaming API.
- **Resources/Personas/**, **Resources/Videos/**, **Assets.xcassets/**: original and new character media.
- **Design/MomentImagePrompts.json**, **Tests/DatingStateChecks.swift**: image prompt manifest and local regression checks.

## Guidance for AI coding assistants

Treat this sign-in → short profile → five-tab VibeMate flow as the current product. Build on the latest recommendation and affinity code. Preserve original datasets, team media, user history, ignored API configuration, and unrelated local signing changes. Do not restore the old long quiz, fabricate historical conversations, or silently replace model-backed chat. Distinguish recommendation score from affinity and video-unlock state. Keep demo auth limitations explicit and API keys untracked.
