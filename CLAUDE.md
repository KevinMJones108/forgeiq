# ForgeIQ — Claude Code Master Configuration
# Product: ForgeIQ  |  Parent: alviz.ai  |  Owner: Kevin
# Version: 1.0  |  May 2026
# READ THIS ENTIRE FILE BEFORE WRITING A SINGLE LINE OF CODE.

---

## WHAT THIS PROJECT IS

ForgeIQ is an iOS-first B2B SaaS platform for sales intelligence,
Six Sigma idea validation, and AI-powered sales script optimisation.
It lives under the alviz.ai brand portfolio alongside Vizion PM and Vizion Scann.

Kevin is the product owner. Six Sigma Black Belt. Has shipped:
a pothole sales app (ElevenLabs + Render), Vizion Scann (App Store live),
Vizion PM (Render + Stripe + PostgreSQL). Directs Claude Code — does not write Swift manually.

Owen is Kevin's son and sales rep. Accounting background. Will use ForgeIQ
for EPDirectory.com outbound sales (procurement/operations managers).

ALWAYS explain what you are about to build before building it.
ALWAYS ask for confirmation before any major architectural decision.
ALWAYS keep code consistent with patterns already in the project.

---

## BRAND

App name:        ForgeIQ
Bundle ID:       ai.alviz.forgeiq
Parent company:  alviz.ai
Sibling apps:    Vizion PM, Vizion Scann, EPDirectory.com

Colour palette:
  Background:    #1C2B2B  (FORGE dark)
  Primary green: #00C853  (ForgeGreen — all buttons and accents)
  Navy:          #1F4E79  (headings, headers)
  Blue:          #2E75B6  (secondary)
  White:         #FFFFFF  (text on dark)
  Mid-grey:      #555555  (secondary text)

---

## COMPLETE TECH STACK

iOS App:
  Language:        Swift 5.10
  UI Framework:    SwiftUI (iOS 17+ only — no UIKit)
  Minimum iOS:     17.0
  Xcode:           16+
  Bundle ID:       ai.alviz.forgeiq

Backend API:
  Runtime:         Node.js 20 LTS
  Framework:       Express 4.x
  Database client: pg (node-postgres) 8.x
  Auth:            express-jwt 8.x + jwks-rsa 3.x
  Other deps:      cors, helmet, morgan, dotenv
  Host:            Render (Web Service)

Statistics Engine (Phase 3 only — do not build in Phase 1):
  Language:        Python 3.11
  Framework:       FastAPI 0.100+
  Libraries:       scipy, numpy, statsmodels, pandas
  Host:            Render (separate Web Service)

Database:
  Engine:          PostgreSQL 15
  Host:            Render (Managed PostgreSQL)
  Connection:      DATABASE_URL environment variable

Auth:
  Provider:        Auth0
  Token type:      JWT (RS256 — not HS256)
  iOS SDK:         Auth0.swift via Swift Package Manager
  SPM URL:         https://github.com/auth0/Auth0.swift

Voice / TTS:
  Provider:        ElevenLabs API v1
  Pattern:         Use Kevin's existing pothole app as reference implementation
  TTS endpoint:    POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
  Key storage:     Server-side only (Node.js) — NEVER in iOS app

Speech-to-Text:
  Primary:         Apple Speech Framework (SFSpeechRecognizer) — on-device, free
  Fallback:        OpenAI Whisper API (Phase 2)

Translation:
  Primary:         Apple Translation Framework (iOS 17+) — on-device, no API cost
  Fallback:        DeepL API (Phase 2)

AI Processing:
  Provider:        Anthropic Claude API
  Model:           claude-sonnet-4-6  # was claude-sonnet-4-20250514 — EOL 2026-06-15, migrated 2026-06-12
  Location:        Node.js backend ONLY — never called from iOS directly

CRM:
  Provider:        Pipedrive
  API token:       PIPEDRIVE_API_TOKEN in Node.js env (server-side only)
  Auto-log:        Call activity + deal notes after every recorded call
  Endpoints used:  POST /activities, POST /notes, POST /activities (tasks)

AI Calling Agent:
  Provider:        Vapi.ai (Kevin already has an account)
  Voice:           ElevenLabs (connected to Vapi)
  Use case:        EPDirectory outbound + re-engagement of low-score calls
  Phase:           Phase 2 parallel track

Payments:
  Provider:        Stripe (same pattern as Vizion PM)
  Phase:           Phase 4 only — do not touch in Phase 1

Push Notifications:
  Provider:        APNs (Apple Push Notification service)
  Phase:           Phase 2

---

## ARCHITECTURE PRINCIPLES — NEVER VIOLATE

PRINCIPLE 1 — THIN iOS CLIENT
The iOS app captures audio, displays results, and manages the UI.
All AI calls, statistical computation, script synthesis, DOE analysis,
Pipedrive logging, and Vapi management run on the Node.js backend.
Never put heavy logic in Swift.

PRINCIPLE 2 — MODULAR BOUNDARIES
Each module is self-contained with its own:
  - Swift views and ViewModels in ForgeIQ/Modules/[ModuleName]/
  - Node.js route file in forgeiq-api/src/routes/[module].routes.js
  - PostgreSQL tables prefixed with the module name
Modules NEVER directly access another module's data or Swift files.
All cross-module communication goes through the Node.js API.

PRINCIPLE 3 — MULTI-USER FROM DAY ONE
Every single database query MUST include WHERE user_id = $1
where $1 comes from the validated JWT sub claim.
NEVER return data without user_id filtering. No exceptions.
Kevin and Owen are separate users with separate data and rep dashboards.

PRINCIPLE 4 — JWT ON EVERY ROUTE
Every Express route except GET /health MUST validate the Auth0
JWT token using the auth middleware before any logic executes.
Never create unauthenticated endpoints, even for testing.

PRINCIPLE 5 — FEATURE FLAGS
Every module beyond VoiceCore is gated by a boolean column in
the user_subscriptions table. Check the flag before serving any
module API route or rendering any module UI screen.

PRINCIPLE 6 — PHASE 1 SCOPE ONLY
Do not build any Phase 2+ feature during Phase 1.
Create empty placeholder folders for future modules but no code.
See CURRENT PHASE below for the exact build list.

---

## MODULE STATUS MAP

Module 1: VoiceCore              STATUS: BUILDING NOW (Phase 1)
  Voice recording, Apple STT, Apple Translation, ElevenLabs TTS,
  .txt transcript save, Files tab, single button UI, Auth0 login,
  Node.js backend, PostgreSQL, Render deployment

Module 1b: Immediate Value       STATUS: ADD TO SESSION 10 (Phase 1)
  AI Call Summary (Claude API), Blown Past Detector (Claude API),
  Pipedrive auto-log, Owen vs Kevin rep dashboard

Module 2: IdeaVault              STATUS: Spec complete, not started (Phase 2)
  Idea extraction, pattern mapping, VOC cards, IP timestamping

Module 2b: Vapi Voice Agent      STATUS: Kevin has account — Phase 2 parallel
  EPDirectory outbound, re-engagement of low-score calls

Module 3: SigmaVault             STATUS: Spec complete, not started (Phase 3)
  5 Whys, T-Tests, DMAIC, FMEA — requires Python stats engine

Module 4: SalesForge             STATUS: Spec complete, not started (Phase 4)
  Script library, live coaching, sales plan builder, CRM deep integration

Module 5: DOE Optimiser          STATUS: Spec complete, not started (Phase 5)
  Factorial design, interaction effects, optimal combination finder

Module 6: ApexScript             STATUS: Spec complete, not started (Phase 6)
  DOE-proven script synthesis, Sigma Rating, confirmation testing

Module 7: Admin & Billing        STATUS: Stub in Phase 1, full in Phase 2
  User profile, subscription management, Stripe

---

## PHASE 1 BUILD CHECKLIST

iOS App:
  [ ] Xcode project: SwiftUI, Bundle ID ai.alviz.forgeiq, iOS 17+
  [ ] Complete folder structure per iOS FOLDER CONVENTION below
  [ ] Constants.swift with all config and colour palette
  [ ] AudioRecordingManager — AVFoundation, .m4a output
  [ ] WaveformView — live animated bars in ForgeGreen
  [ ] SpeechTranscriptionManager — Apple SFSpeechRecognizer
  [ ] TranslationManager — Apple Translation Framework
  [ ] ElevenLabsTTSManager — streaming via Node.js proxy
  [ ] HomeView — single animated button, 4-state machine
  [ ] FilesTabView — saved transcript list with search
  [ ] TranscriptDetailView — read, share, ElevenLabs read-back
  [ ] .txt auto-save after every recording with standard format
  [ ] Auth0.swift login flow — JWT stored in Keychain
  [ ] APIClient — URLSession with auth headers
  [ ] ProfileTabView — user info, rep stats, sign out
  [ ] Transcript sync to backend after save
  [ ] SESSION 10 ADD-ON: AI Call Summary via Claude API
  [ ] SESSION 10 ADD-ON: Blown Past Detector via Claude API
  [ ] SESSION 10 ADD-ON: Pipedrive call activity auto-log
  [ ] SESSION 10 ADD-ON: Call quality score (talk-time, commitments)

Node.js Backend:
  [ ] Express app with Auth0 JWT middleware
  [ ] PostgreSQL connection pool
  [ ] Schema migration on startup (runs schema.sql)
  [ ] POST /api/v1/auth/sync
  [ ] GET  /api/v1/auth/me
  [ ] CRUD /api/v1/voice/recordings
  [ ] POST /api/v1/voice/transcripts
  [ ] POST /api/v1/voice/tts  (ElevenLabs proxy)
  [ ] POST /api/v1/ai/call-summary  (Claude API — summary + blown past)
  [ ] POST /api/v1/crm/log-call  (Pipedrive auto-log)
  [ ] Stub routes for Phase 2+ modules (501 response)
  [ ] Render deployment (render.yaml)

---

## iOS FOLDER CONVENTION

ForgeIQ/
  App/
    ForgeIQApp.swift              Entry point (@main)
    AppEnvironment.swift          @EnvironmentObject shared state
  Core/
    Audio/
      AudioRecordingManager.swift
      AudioPlaybackManager.swift
    Speech/
      SpeechTranscriptionManager.swift
    Translation/
      TranslationManager.swift
    ElevenLabs/
      ElevenLabsTTSManager.swift
    API/
      APIClient.swift
      AuthTokenManager.swift
  Modules/
    VoiceCore/
      Views/
        HomeView.swift
        RecordingView.swift
        FilesTabView.swift
        TranscriptDetailView.swift
        VoicePickerView.swift
        CallSummaryView.swift       (Session 10)
        BlownPastView.swift         (Session 10)
      ViewModels/
        HomeViewModel.swift
        RecordingViewModel.swift
        FilesViewModel.swift
        CallSummaryViewModel.swift  (Session 10)
    IdeaVault/          (empty folder — Phase 2)
    SigmaVault/         (empty folder — Phase 3)
    SalesForge/         (empty folder — Phase 4)
    DOEOptimiser/       (empty folder — Phase 5)
    ApexScript/         (empty folder — Phase 6)
    Admin/
      Views/
        ProfileTabView.swift
        LoginView.swift
        RepDashboardView.swift      (Owen vs Kevin)
      ViewModels/
        ProfileViewModel.swift
  Shared/
    Components/
      ForgeButton.swift
      WaveformView.swift
      TranscriptCard.swift
      LanguageSelectorView.swift
    Models/
      Recording.swift
      Transcript.swift
      User.swift
      Subscription.swift
      CallSummary.swift             (Session 10)
    Constants.swift
  Resources/
    Assets.xcassets
    Info.plist

---

## BACKEND FOLDER CONVENTION

forgeiq-api/
  src/
    app.js                        Express app setup
    server.js                     HTTP server start
    middleware/
      auth.middleware.js           Auth0 JWT validation
      errorHandler.js              Global error handler
    routes/
      index.js                     Mounts all route files
      auth.routes.js
      voice.routes.js              Recordings, transcripts, TTS
      ai.routes.js                 Call summary, blown past (Session 10)
      crm.routes.js                Pipedrive auto-log (Session 10)
      ideas.routes.js              Stub — 501 response
      sigma.routes.js              Stub — 501 response
      forge.routes.js              Stub — 501 response
      vapi.routes.js               Stub — 501 response (Phase 2)
    services/
      recordingsService.js
      transcriptsService.js
      elevenLabsService.js
      callSummaryService.js        (Session 10)
      pipedriveService.js          (Session 10)
    db/
      index.js                     pg Pool
      schema.sql                   Full schema
      migrate.js                   Run schema on startup
    utils/
      response.js                  success() and error() helpers
  package.json
  .env                             (never commit — in .gitignore)
  .env.example                     (commit this — no real values)
  render.yaml
  .gitignore

---

## NAMING CONVENTIONS

Swift:
  Files:        PascalCase              AudioRecordingManager.swift
  Views:        PascalCase + View       HomeView.swift
  ViewModels:   PascalCase + ViewModel  HomeViewModel.swift
  Managers:     PascalCase + Manager    SpeechTranscriptionManager.swift
  Models:       PascalCase              Recording.swift
  Constants:    SCREAMING_SNAKE_CASE    API_BASE_URL
  Properties:   camelCase               isRecording, transcriptText

Node.js:
  Route files:  kebab-case.routes.js    voice.routes.js
  Service files: camelCase + Service    recordingsService.js

Database:
  Tables:       snake_case plural        recordings, user_subscriptions
  Columns:      snake_case               created_at, user_id, audio_duration_sec
  Primary keys: id UUID DEFAULT gen_random_uuid()
  Timestamps:   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()

---

## API CONVENTIONS

Base URL dev:   http://localhost:3001
Base URL prod:  https://forgeiq-api.onrender.com
Versioning:     /api/v1/[module]/[resource]
Auth header:    Authorization: Bearer <jwt>
Response shape: { success: boolean, data: {} | [], error: string | null }
Pagination:     ?page=1&limit=20 on all list endpoints

HTTP status codes:
  200  Success
  201  Created
  400  Validation error
  401  Missing or invalid JWT
  403  Valid JWT but insufficient permission
  404  Resource not found or does not belong to user
  500  Server error — never expose stack trace in production

All error responses must be JSON — never plain text.

---

## SWIFT CODE STANDARDS

- Never force-unwrap optionals (no ! operator anywhere)
- Use guard let or if let for all optionals
- All async calls wrapped in do { } catch { }
- Show errors in UI — never silently swallow them
- Use @StateObject for ViewModels owned by a view
- Use @EnvironmentObject for app-wide shared state
- Keep SwiftUI views under 150 lines — extract subviews if larger
- Add // MARK: - Section Name comments throughout
- Never store JWT in UserDefaults — Keychain only
- Spring animations on all state transitions
- Haptic feedback on every significant user action

---

## NODE.JS CODE STANDARDS

- All Express routes use async/await with try-catch
- All errors passed to next(error) for global handler
- Never log JWT tokens, passwords, or user PII
- Every query includes WHERE user_id = $1 from JWT
- Parameterised queries only — never string concatenation in SQL
- All API keys and secrets in environment variables only

---

## ENVIRONMENT VARIABLES

NODE_ENV=production
PORT=3001
DATABASE_URL=[Render PostgreSQL connection string]
AUTH0_DOMAIN=[your-tenant].auth0.com
AUTH0_AUDIENCE=[your API identifier in Auth0 dashboard]
AUTH0_CLIENT_ID=[iOS app client ID from Auth0 dashboard]
ELEVEN_LABS_API_KEY=[from elevenlabs.io account]
ANTHROPIC_API_KEY=[from console.anthropic.com]
PIPEDRIVE_API_TOKEN=[from Pipedrive Settings > API]
STRIPE_SECRET_KEY=[from Stripe dashboard — Phase 4 only]
VAPI_API_KEY=[from vapi.ai account — Phase 2 only]

iOS Constants.swift (safe to hardcode — not secrets):
  API_BASE_URL (Debug):   http://localhost:3001
  API_BASE_URL (Release): https://forgeiq-api.onrender.com
  AUTH0_DOMAIN:           [your-tenant].auth0.com
  AUTH0_CLIENT_ID:        [iOS app client ID]
  AUTH0_AUDIENCE:         [API identifier]
  FORGEIQ_GREEN:          Color(hex: "#00C853")
  FORGEIQ_NAVY:           Color(hex: "#1F4E79")
  FORGEIQ_FORGE:          Color(hex: "#1C2B2B")

---

## KEY API ENDPOINTS — PHASE 1

GET  /health                              No auth  — Render health check
POST /api/v1/auth/sync                    JWT      — First login, create user
GET  /api/v1/auth/me                      JWT      — Current user + flags
GET  /api/v1/voice/recordings             JWT      — Paginated list
POST /api/v1/voice/recordings             JWT      — Create recording metadata
GET  /api/v1/voice/recordings/:id         JWT      — Single recording + transcript
PUT  /api/v1/voice/recordings/:id         JWT      — Update title
DELETE /api/v1/voice/recordings/:id       JWT      — Soft delete
POST /api/v1/voice/transcripts            JWT      — Save transcript
GET  /api/v1/voice/transcripts/:id        JWT      — Get transcript
POST /api/v1/voice/tts                    JWT      — ElevenLabs proxy
POST /api/v1/ai/call-summary              JWT      — Generate call summary + blown past
POST /api/v1/crm/log-call                 JWT      — Auto-log to Pipedrive
POST /api/v1/ideas/*                      JWT      — 501 Not Implemented (Phase 2)
POST /api/v1/sigma/*                      JWT      — 501 Not Implemented (Phase 3)
POST /api/v1/forge/*                      JWT      — 501 Not Implemented (Phase 4)
POST /api/v1/vapi/*                       JWT      — 501 Not Implemented (Phase 2)

---

## AI CALL SUMMARY — SESSION 10 FEATURE

After every call transcript is saved, call POST /api/v1/ai/call-summary.
The Node.js backend calls Claude API with the transcript and returns:

{
  summary: "2-3 sentence executive summary of the call",
  went_well: ["bullet 1", "bullet 2", "bullet 3"],
  learning_points: ["what to improve", "what was missed"],
  blown_past: [
    {
      timestamp: "04:17",
      prospect_said: "exact quote",
      signal_type: "HIGH | MED | LOW",
      signal_description: "what the signal means",
      what_happened: "what the rep did instead",
      suggested_response: "what to say next time"
    }
  ],
  commitments: [
    { owner: "Owen | Prospect", text: "what was committed", due: "today | specific date" }
  ],
  next_step: "specific recommended action",
  call_score: 7,
  talk_time_rep_pct: 38,
  talk_time_prospect_pct: 62
}

Pipedrive auto-log runs in parallel — POST to Pipedrive /activities
with the call summary as the note body.

---

## PIPEDRIVE AUTO-LOG — SESSION 10 FEATURE

After call summary is generated, POST to Pipedrive API:

1. Create Activity (call log):
   POST https://api.pipedrive.com/v1/activities
   { subject: "ForgeIQ Call — [contact] [date]",
     type: "call", duration: "[MM:SS]",
     note: [full summary text], done: true }

2. Create Note on Deal:
   POST https://api.pipedrive.com/v1/notes
   { content: [blown past items + learning points],
     deal_id: [if known], person_id: [if known] }

3. Create Follow-up Tasks (one per commitment):
   POST https://api.pipedrive.com/v1/activities
   { subject: "[commitment text]", type: "task",
     due_date: "[today + 1 day]", done: false }

Use PIPEDRIVE_API_TOKEN header: api_token=[token]

---

## RE-ENGAGEMENT LOOP

Low-score calls (score < 5 OR 2+ HIGH blown past signals):
  - Flag as Re-Engagement Candidate
  - Create Pipedrive Task at day +7: "Re-engage [contact] — ForgeIQ improved script ready"
  - Generate Re-Engagement Brief (Claude API):
    What the prospect revealed, what was missed, improved opening line
  - After DOE confirms optimal script: brief uses proven approach
  - Vapi agent can execute re-engagement calls automatically (Phase 2)

---

## DO NOT BUILD IN PHASE 1

- ReplayKit call audio capture
- ElevenLabs voice cloning
- Any SigmaVault statistical tests
- DOE matrix builder
- SalesForge script library
- Apex Script generator
- CRM deep integrations beyond basic Pipedrive logging
- Apple Watch companion
- iPad-specific layouts
- Team or enterprise admin features
- Stripe payment flows
- Python statistics microservice
- Vapi.ai calling agent
- Web admin console

---

## Pre-Submission Gate (Mandatory — born from Vizion Scan 49-day delay)

Run BEFORE every App Store submission. Each failure = 7 days lost minimum.
Full rule: ~/.claude/rules/ios-submission-checklist.md

### Gate 1: Paywall UI pattern
```bash
# Run from project root — must return ZERO results
grep -r '\.alert(' ForgeIQ/ | grep -i 'paywall\|subscription\|purchase\|premium'
# PASS: zero results
# FAIL: any match → replace with .sheet() before submitting
```
- UIAlertController CANNOT render SwiftUI Link views
- Apple 3.1.2(c) requires PP + EULA links in every paywall
- ALWAYS `.sheet()`. NEVER `.alert()` for paywalls.

### Gate 2: Subscription Settings section
- Open Settings or Profile tab on device
- Confirm "Manage Subscription" option is visible to free users
- Tap it → must open Apple's subscription management (StoreKit link)
- PASS: visible and functional in 1 tap
- FAIL: missing or hidden → Apple 2.1(b) REJECT

### Gate 3: Free tier smoke test
- Sign in as a free user (fresh account)
- Complete the primary ForgeIQ flow: record a call → get AI summary
- MUST complete without hitting a paywall
- Apple 2.1(b): free users must receive genuine value before paywall
- PASS: free user completes core flow end-to-end
- FAIL: paywall blocks core feature immediately → REJECT incoming

### Pre-submission checklist
- [ ] Gate 1: grep paywall alerts → zero results
- [ ] Gate 2: Subscription management visible in Settings (manual test on device)
- [ ] Gate 3: Free tier smoke test complete (record → summary, no paywall block)
- [ ] All 3 PASS → submit
- [ ] Any FAIL → fix first (saves 7 days minimum per fix)

---

## KEVIN'S PREFERENCES

- Dark FORGE background (#1C2B2B) on all primary screens
- ForgeGreen (#00C853) for all primary buttons and accents
- Spring animations on all state changes — no linear transitions
- Haptic feedback on every significant user action
- Explain before building — one paragraph summary first
- Confirm before creating files outside the structure above
- Never leave TODO comments in completed session code
- Always test on a real iPhone, not just Simulator
- Owen and Kevin are both users — keep their data and dashboards separate
