# ForgeIQ — Phase 1 Session Prompts
# All 10 sessions ready to copy-paste into Claude Code
# alviz.ai | Kevin | May 2026

---

## HOW TO USE THESE PROMPTS

1. Open terminal in your ForgeIQ-Project folder
2. Run: `claude`
3. **Start EVERY session with this ritual line first:**

```
Read CLAUDE.md first, confirm you have loaded the project context,
then proceed with the session below.
```

4. Then paste the session prompt below
5. Do not move to the next session until ALL Definition of Done items pass
6. Each session is approximately 3–5 hours of Claude Code work

---

## SESSION 1 — Project Scaffold: iOS + Node.js
**Estimated time: 3–4 hours | Requires: Xcode 16, Node.js 20**

```
Create a new Xcode iOS project called ForgeIQ with SwiftUI, 
Bundle ID ai.alviz.forgeiq, targeting iOS 17+.

Create all folders from the iOS FOLDER CONVENTION in CLAUDE.md 
including empty placeholder folders for IdeaVault, SigmaVault, 
SalesForge, DOEOptimiser, ApexScript. Add .gitkeep to empty folders.

Create Constants.swift in Shared/ with:
- All colour hex values (FORGE #1C2B2B, ForgeGreen #00C853, Navy #1F4E79)
- API_BASE_URL as a static let (http://localhost:3001 for debug)
- All Auth0 config keys as static let properties
- A Color extension that accepts hex strings

Create ForgeIQApp.swift with @main entry point.
Create a root ContentView with a TabView with 3 tabs:
  Tab 1: placeholder HomeView (microphone icon)
  Tab 2: placeholder FilesTabView (doc icon)
  Tab 3: placeholder ProfileTabView (person icon)
Use ForgeGreen as the tab tint colour. Dark background throughout.

Create the forgeiq-api Node.js project:
- npm init with package name forgeiq-api
- Install: express pg express-jwt jwks-rsa cors helmet morgan dotenv
- Create src/app.js with Express, CORS (allow all in dev), helmet, morgan
- Create src/server.js that starts HTTP server on PORT from env (default 3001)
- Create GET /health returning { success: true, data: { status: 'ok', version: '1.0.0' } }
- Create .env.example with all key names from CLAUDE.md and no values
- Create .gitignore covering .env, node_modules, .DS_Store, *.xcuserstate
- Create render.yaml (see RENDER DEPLOYMENT section in CLAUDE.md)

Definition of Done:
[ ] Xcode project opens and builds with 0 errors and 0 warnings
[ ] App runs in iOS Simulator — 3-tab structure, ForgeGreen tint, dark background
[ ] Node.js starts with npm start on port 3001
[ ] curl http://localhost:3001/health returns { success: true, data: { status: 'ok' } }
[ ] All folders from CLAUDE.md iOS FOLDER CONVENTION exist in Xcode project
[ ] Constants.swift contains all three brand colours
```

---

## SESSION 2 — AVFoundation Audio Recording Engine
**Estimated time: 3–4 hours | Test on real iPhone — Simulator cannot record**

```
Build AudioRecordingManager.swift in Core/Audio/.
Implement as ObservableObject class with these @Published properties:
  isRecording: Bool
  isPaused: Bool
  currentDuration: TimeInterval (updates every second)
  audioLevel: Float (0.0 to 1.0 — for waveform visualisation)

Implement these methods:
  requestMicrophonePermission() async -> Bool
  startRecording() — saves to app Documents directory as [UUID].m4a
  stopRecording() -> URL? — returns the saved file URL
  pauseRecording()
  resumeRecording()
  deleteRecording(url: URL)

Use AVAudioSession category .playAndRecord with option .defaultToSpeaker.
Use AVAudioRecorder with AVFormatIDKey = kAudioFormatMPEG4AAC.
Update audioLevel on a 0.1-second Timer using recorder.averagePower(forChannel: 0).
Convert from dB (-160 to 0) to a normalised 0.0–1.0 Float for the UI.

Add to Info.plist:
  NSMicrophoneUsageDescription: 
  "ForgeIQ uses your microphone to record and transcribe conversations."

Build WaveformView.swift in Shared/Components/:
  Takes audioLevel: Float as input (0.0–1.0)
  Shows 12 vertical bars that scale with the audio level
  Bars are ForgeGreen (#00C853) with rounded corners
  Uses TimelineView(.animation) for smooth 60fps animation
  Spring animation on bar height changes
  All bars at minimum height (4pt) when audioLevel is 0

Wire WaveformView into HomeView temporarily to verify it works.

Definition of Done:
[ ] App requests microphone permission on first launch
[ ] startRecording() creates a valid .m4a file in Documents directory
[ ] WaveformView bars animate visibly while speaking and go flat when silent
[ ] stopRecording() returns a valid file URL
[ ] Recorded .m4a plays back correctly in the iOS Files app
[ ] currentDuration increments correctly in real time
[ ] pauseRecording/resumeRecording work without crashing
```

---

## SESSION 3 — Apple Speech Framework: Real-Time Transcription
**Estimated time: 3–4 hours | Test on real iPhone — Simulator STT is unreliable**

```
Build SpeechTranscriptionManager.swift in Core/Speech/.
Implement as ObservableObject with @Published:
  transcriptText: String (updates live as speech is recognised)
  isTranscribing: Bool
  confidence: Float

Implement:
  requestSpeechPermission() async -> Bool
  startTranscribing(locale: Locale) — streams live text updates
  stopTranscribing() -> String — finalises and returns complete transcript

Use SFSpeechAudioBufferRecognitionRequest with shouldReportPartialResults = true.
Tap into the AVAudioEngine that AudioRecordingManager is already running.
Install an audio tap on the input node and feed PCM buffers to the recogniser.
Both managers must start and stop together cleanly.

Handle these error cases with user-facing messages (not crashes):
  - Permission denied
  - Recogniser not available for locale
  - Recognition request failed
  - Task timeout after silence

Add to Info.plist:
  NSSpeechRecognitionUsageDescription:
  "ForgeIQ transcribes your conversations to create searchable text files."

Build TranscriptView.swift in Modules/VoiceCore/Views/:
  A ScrollView showing transcriptText, auto-scrolling to bottom as text arrives
  Text in white on FORGE dark background
  A subtle blinking cursor in ForgeGreen to show live transcription is active
  Fades in each new word as it appears

Integrate: AudioRecordingManager.startRecording() triggers
SpeechTranscriptionManager.startTranscribing() in parallel.
AudioRecordingManager.stopRecording() calls stopTranscribing() and 
returns both the audio URL and the final transcript String.

Definition of Done:
[ ] App requests speech recognition permission on first use
[ ] Speaking clearly shows words appearing in TranscriptView in real time
[ ] Final transcript is accurate and complete after stopping
[ ] Works correctly on a real iPhone in a room with background noise
[ ] Error states show user-friendly messages — no crashes
[ ] Both managers start and stop cleanly together
```

---

## SESSION 4 — ElevenLabs TTS: Streaming Voice Playback
**Estimated time: 3–4 hours | Reference Kevin's pothole app for the streaming pattern**

```
Build ElevenLabsTTSManager.swift in Core/ElevenLabs/.
Implement as ObservableObject with @Published:
  isPlaying: Bool
  isSynthesising: Bool
  currentVoiceId: String (persisted in UserDefaults)

Implement:
  synthesise(text: String, voiceId: String) async throws
  stop()
  pause()
  resume()

The iOS app calls POST /api/v1/voice/tts on the Node.js backend.
The backend holds the ElevenLabs API key and streams audio back to iOS.
iOS receives the audio stream and plays it using AVPlayer.
Use the same streaming architecture as Kevin's existing pothole sales app.

Build the Node.js route POST /api/v1/voice/tts in voice.routes.js:
  - Validate JWT
  - Extract voice_id and text from request body
  - Call ElevenLabs: POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
  - Headers: xi-api-key: [ELEVEN_LABS_API_KEY], Content-Type: application/json
  - Body: { text, model_id: "eleven_multilingual_v2", voice_settings: { stability: 0.5, similarity_boost: 0.75 } }
  - Stream the audio/mpeg response directly back to iOS
  - Never log the text content — may contain sensitive call information

Build VoicePickerView.swift in Modules/VoiceCore/Views/:
  List of 6 ElevenLabs voices with name and language label
  A play sample button for each (synthesises "Hello, I am ForgeIQ.")
  Selected voice highlighted with ForgeGreen border
  Selected voiceId saved to UserDefaults

Definition of Done:
[ ] POST /api/v1/voice/tts returns audio stream without errors
[ ] iPhone speaks a full paragraph clearly through the speaker
[ ] VoicePickerView shows 6 voices, play sample works for each
[ ] Selected voice persists after app is killed and restarted
[ ] ElevenLabs API key is never visible in iOS code, logs, or network inspector
[ ] stop() immediately halts playback with no audio artefact
```

---

## SESSION 5 — Apple Translation Framework
**Estimated time: 2–3 hours | Test on real iPhone — on-device models need to download first**

```
Build TranslationManager.swift in Core/Translation/.
Implement as ObservableObject with @Published:
  isTranslating: Bool
  detectedLanguage: String?

Implement:
  translate(text: String, from: Locale, to: Locale) async throws -> String
  detectLanguage(text: String) async throws -> Locale?

Use Apple's Translation framework (import Translation) — requires iOS 17.4+.
Use TranslationSession for on-device translation (no network required).
Call session.prepareTranslation() before first use to download language models.
Handle unsupported language pairs by returning a clear error message.

Support these 6 language pairs as minimum:
  EN <-> ES  (English / Spanish)
  EN <-> FR  (English / French)
  EN <-> DE  (English / German)
  EN <-> ZH  (English / Chinese Simplified)
  EN <-> AR  (English / Arabic)
  EN <-> PT  (English / Portuguese)

Build LanguageSelectorView.swift in Shared/Components/:
  Two Pickers side by side: source language, target language
  A swap button between them (arrows SF Symbol, ForgeGreen)
  Compact — maximum 60pt tall — sits comfortably below the main button
  First option in source picker is "Auto-detect"
  If "Auto-detect" selected, call detectLanguage() on the transcript

Integrate with recording flow:
  If a target language is selected when recording stops, auto-translate.
  Show original transcript first, then translated text below a ForgeGreen divider.
  Both texts scroll together in TranscriptView.

Definition of Done:
[ ] Translates a paragraph of English to Spanish with airplane mode on (on-device)
[ ] Auto-detection correctly identifies English, Spanish, and French
[ ] LanguageSelectorView fits cleanly below the main button
[ ] Swap button correctly reverses the language pair
[ ] Unsupported pairs show a clear message, not a crash
[ ] Translated text appears automatically after recording stops if target is selected
```

---

## SESSION 6 — The ForgeIQ Single Button UI: Hero Home Screen
**Estimated time: 4–5 hours | This is the face of the product — premium feel required**

```
Build the complete HomeView.swift in Modules/VoiceCore/Views/.
This is the primary screen and must feel polished and native.

Full-screen FORGE dark background (#1C2B2B).

Central element: large circular button, 120pt diameter, 4 states:

IDLE state:
  Outer ring animates with a pulsing glow in ForgeGreen
  Animation: withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true))
  Scale: 1.0 to 1.08, opacity 0.6 to 1.0
  Label below button: "Tap to Begin" in white
  LanguageSelectorView visible above the button

RECORDING state:
  Outer ring solid red (no animation)
  WaveformView appears above the button (12 animated ForgeGreen bars)
  Live duration counter below the button: "0:42" format
  Label: "Tap to Stop"
  LanguageSelectorView hidden

PROCESSING state:
  Spinning arc in ForgeGreen (trimmedPath circle, rotating 360° repeatedly)
  Label: "Transcribing..."
  No waveform, no duration counter

COMPLETE state:
  Checkmark animation (draw stroke from 0 to 1 over 0.4s)
  TranscriptView appears below, max height 200pt, scrollable
  Label: "Done"
  Save button appears in ForgeGreen: "Saved to Files"

All state transitions: withAnimation(.spring(response: 0.4, dampingFraction: 0.7))
Haptic feedback: UIImpactFeedbackGenerator(.medium) on every state change.
Long-press on button (0.5s) opens a .sheet with .fraction(0.35) detent:
  3 mode options in a clean list:
    Record Only
    Record + Translate
    Read-Back (ElevenLabs reads a saved file aloud)

Build HomeViewModel.swift to manage all state and coordinate all managers.
The ViewModel owns: AudioRecordingManager, SpeechTranscriptionManager,
TranslationManager, ElevenLabsTTSManager.

Tab bar at bottom:
  Tab 1: mic.fill icon (Home — this screen)
  Tab 2: doc.text.fill icon (Files)
  Tab 3: person.fill icon (Profile)
  Background: FORGE dark
  Selected tab tint: ForgeGreen
  Unselected tint: mid-grey

Definition of Done:
[ ] All 4 button states render correctly with smooth transitions on a real iPhone
[ ] Pulsing animation in IDLE is smooth at 60fps — not janky
[ ] Full flow: tap IDLE → RECORDING → PROCESSING → COMPLETE works without crashes
[ ] Waveform is visible and animated during recording
[ ] Long-press mode selector appears and all 3 options are selectable
[ ] Tab bar renders correctly and navigates to all 3 tabs
[ ] Tested on both notch and Dynamic Island iPhone form factors
```

---

## SESSION 7 — .txt File Save, Files Tab, and Share
**Estimated time: 3–4 hours**

```
Implement .txt auto-save triggered immediately when COMPLETE state is reached.

File naming format: YYYY-MM-DD_HHMM_[first-3-words-of-transcript].txt
Example: 2026-05-20_1432_We-keep-losing.txt

File content format (exact — do not vary this):
  ForgeIQ Transcript
  ──────────────────────────────────────────
  Date:       [full date and time]
  Duration:   [MM:SS]
  Language:   [from language] → [to language or "No translation"]
  Word Count: [n words]
  Rep:        [Kevin or Owen — from user profile]
  ──────────────────────────────────────────
  TRANSCRIPT
  
  [full transcript text]
  
  ──────────────────────────────────────────
  TRANSLATION
  
  [translated text — omit this section if no translation]

Save to app Documents directory using FileManager.
Show a brief "Saved ✓" toast notification in ForgeGreen for 1.5 seconds.
Haptic success feedback (UINotificationFeedbackGenerator .success) on save.

Build FilesTabView.swift in Modules/VoiceCore/Views/:
  List of all saved .txt files, newest first
  Each row shows: filename, date (friendly format), language pair, word count
  Search bar at top — filters filename and content
  Empty state: ForgeGreen icon + "Your transcripts will appear here"
  Swipe-left to delete with UIAlertController confirmation before deleting
  Pull-to-refresh that re-reads the Documents directory

Build TranscriptDetailView.swift:
  Full transcript with original and translation in clearly labelled sections
  Edit title: tap pencil icon to enable inline editing, return key saves
  Share button: UIActivityViewController with the .txt file attached
  ElevenLabs Read-Back button: calls ElevenLabsTTSManager.synthesise() with full text
  Export to iCloud Drive is available via the standard iOS share sheet

Definition of Done:
[ ] Every completed recording auto-saves a .txt file in the exact format above
[ ] FilesTabView shows all saved files sorted newest first
[ ] Search correctly filters the file list in real time
[ ] Swipe-delete removes the file from the list and from disk
[ ] Tap a file opens TranscriptDetailView with correct content
[ ] Share button opens iOS share sheet with the .txt file attached
[ ] ElevenLabs read-back button speaks the full transcript
[ ] Files persist correctly across app restarts and device restarts
```

---

## SESSION 8 — Node.js Backend: Auth + PostgreSQL + Full API
**Estimated time: 4–5 hours | Test all endpoints with curl before Session 9**

```
Complete the Node.js backend (forgeiq-api).

Build src/middleware/auth.middleware.js:
  Use express-jwt and jwks-rsa to validate Auth0 JWT RS256 tokens
  Fetch public key from https://[AUTH0_DOMAIN]/.well-known/jwks.json
  Attach decoded payload to req.auth (express-jwt v8 default)
  Return 401 JSON { success: false, error: "Unauthorised" } if token missing/invalid
  Never return 500 for auth errors

Build src/db/index.js:
  pg Pool using DATABASE_URL environment variable
  Export: async function query(text, params) — wraps pool.query()

Build src/db/migrate.js:
  Reads schema.sql and executes it on startup
  Use IF NOT EXISTS on all CREATE TABLE statements
  Called at the top of server.js before app.listen()

Build src/utils/response.js:
  success(res, data, status = 200) — returns { success: true, data }
  error(res, message, status = 400) — returns { success: false, error: message }

Build src/routes/auth.routes.js:
  POST /api/v1/auth/sync:
    Extract sub and email from req.auth (Auth0 JWT claims)
    INSERT OR FIND user by auth0_sub using ON CONFLICT DO NOTHING
    If new user: INSERT default row in user_subscriptions (all features false except voice_core)
    Return: full user object + subscription row + all feature flags
  GET /api/v1/auth/me:
    Return same data for authenticated user

Build src/routes/voice.routes.js:
  All queries use WHERE user_id = [user's database UUID — not auth0_sub]
  Add a helper function getUserIdFromSub(auth0_sub) used in every route
  Implement all endpoints from the KEY API ENDPOINTS section in CLAUDE.md
  ElevenLabs proxy: stream audio response directly, set Content-Type: audio/mpeg

Build src/middleware/errorHandler.js:
  Catch-all Express error handler (4 params: err, req, res, next)
  Always return JSON — never plain text or HTML
  Log error to console in development, not in production

Create stub routes: ideas.routes.js, sigma.routes.js, forge.routes.js, vapi.routes.js
  Each returns: { success: false, error: "Not implemented in this phase" } with status 501

Build src/db/schema.sql — the complete schema from the Master FINAL document:
  users, user_subscriptions, recordings, transcripts
  Plus stub tables: idea_cards, sigma_sessions, forge_scripts
  All with proper indexes on user_id columns

Definition of Done:
[ ] GET /health returns 200 with correct JSON
[ ] POST /api/v1/auth/sync with a valid Auth0 test token creates a user in PostgreSQL
[ ] GET /api/v1/auth/me returns correct user data
[ ] POST /api/v1/voice/recordings creates a row and returns the new ID
[ ] GET /api/v1/voice/recordings returns ONLY the authenticated user's records
[ ] POST /api/v1/voice/tts returns audio data (test with a short text string)
[ ] Invalid or missing JWT returns 401 JSON — never 500
[ ] All stub routes return 501 with correct JSON message
[ ] All SQL queries are parameterised — zero string concatenation
```

---

## SESSION 9 — iOS Auth0 Login + API Client
**Estimated time: 3–4 hours | Requires Auth0 account with iOS app and API configured**

```
Add Auth0.swift to the Xcode project via Swift Package Manager:
  URL: https://github.com/auth0/Auth0.swift
  Version: Up to Next Major from 2.0.0

Build AuthTokenManager.swift in Core/API/:
  Implement as ObservableObject
  @Published: isAuthenticated: Bool, currentUser: UserProfile?
  
  Methods:
    login() async throws — triggers Auth0 universal login web flow
    logout() async — clears tokens, calls Auth0 /v2/logout
    getValidAccessToken() async throws -> String — returns token, refreshes if needed
    
  Token storage:
    Store access token and refresh token in iOS Keychain (not UserDefaults)
    Use the Auth0.swift Credentials Manager for Keychain storage
    Check token expiry before returning — refresh silently if within 60 seconds of expiry
    
  On login success: call POST /api/v1/auth/sync to create or retrieve user record

Build APIClient.swift in Core/API/:
  A generic async function:
    func request<T: Codable>(_ path: String, method: HTTPMethod,
                              body: Encodable? = nil) async throws -> T
  Automatically fetches valid token from AuthTokenManager
  Adds: Authorization: Bearer [token], Content-Type: application/json
  On 401 response: attempt one silent token refresh then retry the request
  On second 401: call logout() and post a notification to show LoginView
  Parse response as ForgeIQResponse<T> then return response.data

Build LoginView.swift in Modules/Admin/Views/:
  Full-screen FORGE dark background
  ForgeIQ logo or wordmark centred
  "Sign in to ForgeIQ" button in ForgeGreen
  Tapping triggers AuthTokenManager.login()
  Loading indicator (ProgressView in ForgeGreen) while auth is in progress
  Error message in red if login fails

In ForgeIQApp.swift:
  Show LoginView as a full-screen cover when !authManager.isAuthenticated
  After successful login, dismiss LoginView and show main ContentView

Definition of Done:
[ ] LoginView appears on first launch on a real iPhone
[ ] Tapping Sign In opens Auth0 universal login in a browser sheet
[ ] After login, LoginView dismisses and the main app appears
[ ] JWT token is stored in Keychain (verify with a Keychain debugging tool)
[ ] APIClient.request() successfully calls GET /api/v1/auth/me and returns user data
[ ] Sign Out clears the token and returns to LoginView
[ ] Expired token is refreshed silently without the user noticing
```

---

## SESSION 10 — Sync + AI Call Summary + Pipedrive + Polish + Final Acceptance
**Estimated time: 5–6 hours | This session makes ForgeIQ shippable**

```
PART A — Transcript Sync to Backend

After every local .txt save:
  POST /api/v1/voice/recordings — create metadata record, get back recording_id
  POST /api/v1/voice/transcripts — save full transcript content with recording_id

Show sync status on each row in FilesTabView:
  Cloud icon (green): synced successfully
  Spinner: sync in progress
  Warning triangle (amber): sync failed — tap to retry

Queue failed syncs using a local array in FilesViewModel.
Retry all queued syncs when the app returns to foreground (scenePhase .active).
On fresh install after login: GET /api/v1/voice/recordings to restore history.

PART B — AI Call Summary (Session 10 add-on)

After transcript is saved and synced, automatically call POST /api/v1/ai/call-summary.
The Node.js endpoint calls the Claude API with the full transcript.
System prompt tells Claude to return JSON matching the CallSummary model in CLAUDE.md.
Display CallSummaryView after the COMPLETE state:
  Summary paragraph
  What went well (green bullets)
  Learning points (orange bullets)  
  Blown Past cards: each shows timestamp, quote, signal type, what happened,
    and the suggested better response — colour coded RED/AMBER/NAVY by severity
  Commitments list
  Call quality score (1–10)
  Talk-time ratio bar (rep% vs prospect%)

PART C — Pipedrive Auto-Log (Session 10 add-on)

After call summary is generated, call POST /api/v1/crm/log-call in Node.js.
The service uses PIPEDRIVE_API_TOKEN to:
  1. POST /activities — create call activity with summary as note
  2. POST /notes — add blown past + learning points as a deal note
  3. POST /activities — create one follow-up task per commitment (due tomorrow)
Show a small "Logged to Pipedrive ✓" confirmation in the app.

PART D — Rep Dashboard

Build RepDashboardView showing Kevin vs Owen metrics:
  Side-by-side average talk-time ratio
  Blown past frequency per call (trend over last 10 calls each)
  Average call quality score
  Commitment follow-through rate
Accessible from ProfileTabView.

PART E — Polish Checklist

Work through every item before declaring Phase 1 complete:
  [ ] All animations smooth on iPhone 13, 14, 15, and 16 form factors
  [ ] Empty state on FilesTabView (first use message)
  [ ] Network offline: recording and local save works, sync queued
  [ ] Error banner when API is unreachable
  [ ] All text supports Dynamic Type accessibility sizes
  [ ] App icon placeholder in Assets.xcassets (1024×1024 required for App Store)
  [ ] All Info.plist privacy strings are human-friendly
  [ ] No force-unwraps anywhere in the codebase (grep for "!")
  [ ] No TODO, FIXME, or placeholder comments in production code
  [ ] Dark mode consistent throughout — no white flash on navigation

PART F — Final Acceptance Test (on a real iPhone, no debugger attached)

  [ ] Record 90 seconds of speech — transcribes accurately, saves as .txt
  [ ] Translate English to Spanish — both languages visible in transcript
  [ ] ElevenLabs reads the full transcript aloud in selected voice
  [ ] .txt file appears in FilesTabView and can be shared via share sheet
  [ ] Transcript syncs to PostgreSQL — verify with direct DB query on Render
  [ ] AI Call Summary appears after call — summary, learning points, blown past cards
  [ ] Pipedrive shows the new activity and note after the call
  [ ] Sign out → sign back in → all previous transcripts restored from backend
  [ ] App runs 15 minutes continuously with no crash or memory warning
  [ ] Run Xcode Instruments Memory Leak tool on the main recording flow
```

---

## RENDER DEPLOYMENT

Add this render.yaml to forgeiq-api/ root:

```yaml
services:
  - type: web
    name: forgeiq-api
    runtime: node
    buildCommand: npm install
    startCommand: node src/server.js
    healthCheckPath: /health
    autoDeploy: true
    envVars:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: forgeiq-db
          property: connectionString
      - key: AUTH0_DOMAIN
        sync: false
      - key: AUTH0_AUDIENCE
        sync: false
      - key: ELEVEN_LABS_API_KEY
        sync: false
      - key: ANTHROPIC_API_KEY
        sync: false
      - key: PIPEDRIVE_API_TOKEN
        sync: false
      - key: STRIPE_SECRET_KEY
        sync: false
      - key: VAPI_API_KEY
        sync: false

databases:
  - name: forgeiq-db
    databaseName: forgeiq
    user: forgeiq_user
    plan: starter
```

Render setup steps:
1. Push ForgeIQ-Project to a private GitHub repository
2. render.com → New → Blueprint → Connect GitHub repo
3. Render reads render.yaml and creates Web Service + PostgreSQL
4. Set all sync:false env vars manually in Render Dashboard → Environment
5. Open Render PostgreSQL console → paste and run schema.sql
6. curl https://forgeiq-api.onrender.com/health → should return 200
7. Update iOS Constants.swift Release config to the Render URL

---

## MODULE BUILD ROADMAP

| Phase | Timeline | Scope |
|---|---|---|
| **Phase 1** | Weeks 1–2 | VoiceCore + AI Summary + Pipedrive + Auth + Backend + Render |
| **Phase 1.5** | Weeks 3–4 | Pre-call brief, re-engagement loop, Owen coaching dashboard, hot lead detection |
| **Phase 2** | Weeks 5–8 | IdeaVault + Vapi.ai EPDirectory agent + platform expansion |
| **Phase 3** | Weeks 9–13 | SigmaVault + Python stats engine + 5 Whys + T-Tests + DMAIC |
| **Phase 4** | Weeks 14–17 | SalesForge + script library + live coaching + CRM deep integration |
| **Phase 5** | Weeks 18–21 | DOE Optimiser + factorial design + interaction effects |
| **Phase 6** | Weeks 22–24 | Apex Script + Sigma Rating + confirmation testing + DOE→Vapi deployment |
| **Phase 7** | Weeks 25–28 | Enterprise layer + team accounts + web admin + App Store public launch |
