# ForgeIQ — Quick Reference Sheet
# Keep this open while building
# alviz.ai | Kevin | May 2026

---

## START EVERY SESSION

```bash
cd ForgeIQ-Project
claude
```

Then type:
```
Read CLAUDE.md first, confirm you have loaded the project context,
then proceed with the session below.
```

---

## SESSION ORDER

| # | Name | Status |
|---|---|---|
| 1 | Project Scaffold | ⬜ Not started |
| 2 | Audio Recording Engine | ⬜ Not started |
| 3 | Speech-to-Text | ⬜ Not started |
| 4 | ElevenLabs TTS | ⬜ Not started |
| 5 | Apple Translation | ⬜ Not started |
| 6 | Single Button UI | ⬜ Not started |
| 7 | File Save + Files Tab | ⬜ Not started |
| 8 | Node.js Backend | ⬜ Not started |
| 9 | Auth0 + API Client | ⬜ Not started |
| 10 | Sync + AI Summary + Pipedrive + Polish | ⬜ Not started |

Change ⬜ to ✅ as you complete each session.

---

## BRAND COLOURS

| Name | Hex | Use |
|---|---|---|
| ForgeGreen | #00C853 | All buttons, accents, active states |
| FORGE | #1C2B2B | App background |
| Navy | #1F4E79 | Headings, headers |
| Blue | #2E75B6 | Secondary elements |
| White | #FFFFFF | Primary text on dark |
| Mid-grey | #555555 | Secondary text |
| Red | #C00000 | Recording state, errors |
| Amber | #E65100 | Warnings, medium severity |

---

## KEY FILE PATHS

### iOS (Xcode)
```
ForgeIQ/Core/Audio/AudioRecordingManager.swift
ForgeIQ/Core/Speech/SpeechTranscriptionManager.swift
ForgeIQ/Core/Translation/TranslationManager.swift
ForgeIQ/Core/ElevenLabs/ElevenLabsTTSManager.swift
ForgeIQ/Core/API/APIClient.swift
ForgeIQ/Core/API/AuthTokenManager.swift
ForgeIQ/Modules/VoiceCore/Views/HomeView.swift
ForgeIQ/Modules/VoiceCore/Views/FilesTabView.swift
ForgeIQ/Modules/VoiceCore/Views/TranscriptDetailView.swift
ForgeIQ/Modules/VoiceCore/Views/CallSummaryView.swift
ForgeIQ/Shared/Constants.swift
ForgeIQ/Resources/Info.plist
```

### Node.js Backend
```
forgeiq-api/src/app.js
forgeiq-api/src/middleware/auth.middleware.js
forgeiq-api/src/routes/voice.routes.js
forgeiq-api/src/routes/ai.routes.js
forgeiq-api/src/routes/crm.routes.js
forgeiq-api/src/services/callSummaryService.js
forgeiq-api/src/services/pipedriveService.js
forgeiq-api/src/db/schema.sql
forgeiq-api/.env
forgeiq-api/render.yaml
```

---

## API ENDPOINTS — PHASE 1

```
GET  /health                          No auth
POST /api/v1/auth/sync                JWT
GET  /api/v1/auth/me                  JWT
GET  /api/v1/voice/recordings         JWT  ?page=1&limit=20
POST /api/v1/voice/recordings         JWT
GET  /api/v1/voice/recordings/:id     JWT
PUT  /api/v1/voice/recordings/:id     JWT
DELETE /api/v1/voice/recordings/:id   JWT
POST /api/v1/voice/transcripts        JWT
GET  /api/v1/voice/transcripts/:id    JWT
POST /api/v1/voice/tts                JWT  (ElevenLabs proxy)
POST /api/v1/ai/call-summary          JWT  (Claude API — Session 10)
POST /api/v1/crm/log-call             JWT  (Pipedrive — Session 10)
```

---

## ENV VARIABLES NEEDED

```
NODE_ENV=production
DATABASE_URL=[Render PostgreSQL URL]
AUTH0_DOMAIN=[tenant].auth0.com
AUTH0_AUDIENCE=[API identifier]
AUTH0_CLIENT_ID=[iOS client ID]
ELEVEN_LABS_API_KEY=[from elevenlabs.io]
ANTHROPIC_API_KEY=[from console.anthropic.com]
PIPEDRIVE_API_TOKEN=[from Pipedrive Settings > API]
STRIPE_SECRET_KEY=[Phase 4 — leave blank now]
VAPI_API_KEY=[Phase 2 — leave blank now]
```

---

## INFO.PLIST PRIVACY STRINGS

```xml
NSMicrophoneUsageDescription
"ForgeIQ uses your microphone to record and transcribe conversations."

NSSpeechRecognitionUsageDescription
"ForgeIQ transcribes your conversations to create searchable text files."
```

---

## SWIFT PACKAGE MANAGER DEPENDENCIES

```
Auth0.swift:   https://github.com/auth0/Auth0.swift  (v2.x)
```

---

## NODE.JS DEPENDENCIES

```bash
npm install express pg express-jwt jwks-rsa cors helmet morgan dotenv
```

---

## DATABASE TABLES — PHASE 1

```
users                  (id, auth0_sub, email, full_name, created_at)
user_subscriptions     (id, user_id, tier, feature_* flags, stripe_*)
recordings             (id, user_id, title, duration_sec, language_from, language_to, mode)
transcripts            (id, recording_id, user_id, content, content_translated)
idea_cards             (stub — Phase 2)
sigma_sessions         (stub — Phase 3)
forge_scripts          (stub — Phase 4)
```

---

## CALL SUMMARY JSON SHAPE (Claude API returns this)

```json
{
  "summary": "2-3 sentence summary",
  "went_well": ["bullet 1", "bullet 2"],
  "learning_points": ["what to improve"],
  "blown_past": [
    {
      "timestamp": "04:17",
      "prospect_said": "exact quote",
      "signal_type": "HIGH",
      "signal_description": "what the signal means",
      "what_happened": "what the rep did instead",
      "suggested_response": "what to say next time"
    }
  ],
  "commitments": [
    { "owner": "Owen", "text": "Send demo link by 5pm", "due": "today" }
  ],
  "next_step": "specific recommended action",
  "call_score": 7,
  "talk_time_rep_pct": 38,
  "talk_time_prospect_pct": 62
}
```

---

## PIPEDRIVE API CALLS (in pipedriveService.js)

```javascript
// Base URL
const PIPEDRIVE_BASE = 'https://api.pipedrive.com/v1';
const headers = { 'Content-Type': 'application/json' };
const params = `?api_token=${process.env.PIPEDRIVE_API_TOKEN}`;

// 1. Log the call as an Activity
POST `${PIPEDRIVE_BASE}/activities${params}`
{ subject: `ForgeIQ Call — ${contactName} ${date}`,
  type: 'call', duration: durationFormatted,
  note: summaryText, done: true }

// 2. Add blown past + learning points as a Note
POST `${PIPEDRIVE_BASE}/notes${params}`
{ content: blownPastAndLearningPoints }

// 3. Create follow-up Task for each commitment  
POST `${PIPEDRIVE_BASE}/activities${params}`
{ subject: commitmentText, type: 'task',
  due_date: tomorrowDateString, done: false }
```

---

## EPDIRECTORY SIGNAL LIBRARY (for AI call summary prompts)

HIGH signals to detect and flag when not followed up:
- Manual process pain: "spreadsheet", "three sites", "takes half a day"
- Commodity frustration: "aluminium costs", "steel prices", "hedging"
- Supplier qualification friction: "hard to vet", "weeks to qualify"
- Budget signal: "budget allocated", "reviewing systems", "Q4 budget"
- Decision maker reveal: "run it by my director", "IT would need to sign off"
- Urgency: "before summer shutdown", "contract up in 3 months"
- Volume signal: "200 orders a week", "£2M in parts", "6 buyers"

Always flag if call > 12 minutes and hedging feature was not mentioned
to a manufacturing/engineering prospect.

---

## VAPI AGENT OPENING SCRIPT (Phase 2)

```
"Hi [name], my name is Alex and I'm an AI assistant calling on behalf of 
EPDirectory — a procurement tool that helps operations and purchasing teams 
find and price parts faster. I have 90 seconds of your time — and if what 
I describe sounds relevant, I can book you straight in with one of our team. 
Is now an okay moment?"
```

---

## RENDER DEPLOYMENT COMMANDS

```bash
# After connecting GitHub repo to Render:
# 1. Render auto-deploys on git push to main
# 2. Run schema.sql manually in Render PostgreSQL console (first time only)
# 3. Set env vars in Render Dashboard → forgeiq-api → Environment

# Test deployment:
curl https://forgeiq-api.onrender.com/health
# Should return: { "success": true, "data": { "status": "ok" } }
```

---

## COMMON DEBUGGING

```bash
# Check Node.js logs on Render:
# Render Dashboard → forgeiq-api → Logs

# Test API locally with curl:
curl -X POST http://localhost:3001/api/v1/auth/sync \
  -H "Authorization: Bearer [test_jwt_token]" \
  -H "Content-Type: application/json"

# Check PostgreSQL on Render:
# Render Dashboard → forgeiq-db → Connect → PSQL
SELECT * FROM users;
SELECT * FROM recordings WHERE user_id = '[your_user_id]';

# Xcode: check Documents directory contents
# Add a temporary debug print in FilesViewModel:
print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
```

---

## PHASE 1.5 SPRINT (after Phase 1 ships)

Quick features to add before Phase 2 begins (~17 hours total):

| Feature | Hours |
|---|---|
| Pre-call intelligence brief (surface all previous calls before dialling) | 3–4 |
| Re-engagement scheduler (low-score calls → Pipedrive task at day +7) | 3–4 |
| Re-engagement brief generation (Claude API improved opening script) | 2–3 |
| Objection frequency map (running count across all calls) | 2 |
| Vocabulary mirror (top phrases customers use → feed into follow-ups) | 2 |
| Weekly intelligence digest (Monday summary of last week's patterns) | 3 |

---

*ForgeIQ — alviz.ai — Kevin — May 2026*
