# ForgeIQ iOS Device Smoke Test
# DO NOT RUN IN SIMULATOR — DEVICE ONLY

## OVERVIEW

Zero proof app works on real iPhone. This test protocol confirms core VoiceCore features before declaring ForgeIQ "functional."

**Pass criteria:** 100% of basic features work (Tests 1-6)
**Target device:** iPhone 15+ running iOS 17+
**Phase:** Phase 1 VoiceCore + Session 10 AI Summary/Pipedrive

---

## TEST 1: Audio Recording

**Steps:**
1. Launch ForgeIQ on iPhone
2. Tap Record button (ForgeGreen circular button)
3. Speak clearly for 30 seconds
4. Tap Stop button

**PASS:**
- .m4a file saved to app Documents directory
- File duration matches recording time ±2s
- Waveform animated during recording
- Haptic feedback on tap

**FAIL:**
- Crash during record/stop
- No file created
- Duration wrong (0:00 or >35s when recorded 30s)
- No waveform animation

**RPN:** Severity 9 × Occurrence 3 × Detection 2 = **54 (MEDIUM)**

---

## TEST 2: Speech-to-Text Transcription (Apple STT)

**Steps:**
1. Tap Record button
2. Speak clearly: "This is a test of the ForgeIQ speech transcription system. I am testing all features to ensure accuracy."
3. Watch live transcript appear
4. Tap Stop button
5. Review final transcript text

**PASS:**
- Live transcript appears word-by-word during recording
- Auto-scrolls as transcript grows
- Final text ≥90% accurate (minor errors acceptable)
- Transcript saves with recording

**FAIL:**
- No text appears during recording
- Transcript <70% accurate
- Crash during transcription
- Transcript not saved

**RPN:** Severity 7 × Occurrence 4 × Detection 3 = **84 (MEDIUM)**

---

## TEST 3: Files Tab — Recording Management

**Steps:**
1. Record 3 separate calls (10-20 seconds each, different content)
2. Navigate to Files tab
3. Search for keyword from one recording
4. Swipe-delete one file
5. Verify remaining files intact

**PASS:**
- All 3 recordings appear in Files list
- Search returns correct recording
- Swipe-delete removes file (disappears from list)
- Remaining 2 files still accessible

**FAIL:**
- Files missing from list
- Search broken (no results or wrong results)
- Delete doesn't work (file remains)
- Delete removes wrong file

**RPN:** Severity 5 × Occurrence 3 × Detection 4 = **60 (MEDIUM)**

---

## TEST 4: ElevenLabs TTS (Voice Playback)

**Prerequisites:** Node.js backend running with ELEVEN_LABS_API_KEY configured

**Steps:**
1. Open Voice Picker screen
2. Select voice from dropdown (default: any voice)
3. Tap "Play Sample" button
4. Listen for TTS output

**PASS:**
- Voice speaks "Hello, I am ForgeIQ" or sample phrase
- Playback smooth (no stuttering)
- Playback completes without crash
- Different voices produce different audio

**FAIL:**
- No audio plays
- Crash during playback
- Audio stutters/cuts out
- All voices sound identical (proxy broken)

**RPN:** Severity 6 × Occurrence 5 × Detection 2 = **60 (MEDIUM)**

---

## TEST 5: Auth0 Login Flow

**Steps:**
1. Launch app (not logged in)
2. Tap "Sign In" button
3. Enter credentials in Auth0 Universal Login
4. Complete login
5. Verify HomeView appears (Record button visible)

**PASS:**
- Auth0 login screen appears
- Login succeeds, redirects to HomeView
- JWT stored in Keychain (verify by relaunch — no re-login)
- ProfileTabView shows user info (name, email)

**FAIL:**
- Login screen doesn't appear
- Login fails with valid credentials
- Crash after login
- Re-launch requires re-login (JWT not persisted)

**RPN:** Severity 10 × Occurrence 2 × Detection 1 = **20 (LOW)**

---

## TEST 6: AI Call Summary + Pipedrive Auto-Log (Session 10)

**Prerequisites:** Node.js backend running with ANTHROPIC_API_KEY + PIPEDRIVE_API_TOKEN configured

**Steps:**
1. Record a 60-second call with these phrases:
   - "I think we could use this for our procurement process"
   - "Let me talk to my team and get back to you next week"
   - "Can you send me pricing?"
2. Stop recording
3. Wait 5-10 seconds for AI summary to generate
4. Open CallSummaryView (tap on recording)
5. Check Pipedrive account for logged activity

**PASS:**
- AI summary appears with:
  - 2-3 sentence executive summary
  - "Went Well" bullets
  - "Learning Points" bullets
  - At least 1 "Blown Past" signal detected (missed buying signal)
  - Talk-time percentages (rep vs prospect)
  - Call score (1-10)
- Pipedrive activity created with summary as note
- Pipedrive task created for follow-up

**FAIL:**
- No summary appears
- Summary generic/wrong (didn't analyze actual transcript)
- Zero "Blown Past" signals when obvious signals existed
- Pipedrive call not logged
- Crash during summary generation

**RPN:** Severity 8 × Occurrence 4 × Detection 2 = **64 (MEDIUM)**

---

## OPTIONAL TEST 7: Translation (Apple Translation Framework)

**Prerequisites:** iOS 17+ device with English + Spanish language packs downloaded

**Steps:**
1. Record a call in English
2. Select "Translate to Spanish" option
3. View translated transcript

**PASS:**
- Translation appears within 5 seconds
- Translation ≥80% accurate (coherent sentences)
- Original transcript preserved

**FAIL:**
- No translation appears
- Translation gibberish
- Original transcript deleted

**RPN:** Severity 4 × Occurrence 3 × Detection 5 = **60 (MEDIUM)**

---

## OPTIONAL TEST 8: Transcript Sync to Backend

**Prerequisites:** Node.js backend running, JWT valid

**Steps:**
1. Record a call on device
2. Check backend database: `SELECT * FROM transcripts WHERE user_id = '[Kevin auth0|id]';`
3. Verify transcript text matches device

**PASS:**
- Transcript saved to PostgreSQL
- Text matches iOS transcript exactly
- user_id correct (Kevin's Auth0 sub)

**FAIL:**
- No database entry
- Text wrong or truncated
- user_id NULL or wrong

**RPN:** Severity 6 × Occurrence 4 × Detection 3 = **72 (MEDIUM)**

---

## SMOKE TEST SUMMARY

**Total tests:** 8 (6 required, 2 optional)
**Pass criteria:** Tests 1-6 MUST pass (100%)
**Target RPN threshold:** No blocker (RPN > 100) allowed

**Current highest RPN:** Test 2 (STT) at 84 — MEDIUM priority

---

## WHEN TO RUN THIS TEST

- After every ForgeIQ iOS build before claiming "working"
- Before any App Store submission (Gate 3 requirement)
- After any Swift file changes in VoiceCore module
- Before demo to Kevin/Owen/Adam

---

## KEVIN MANUAL TEST PROTOCOL

Kevin runs Tests 1-6 on his iPhone 15.
Results logged in chat:
- "Test 1: PASS — recorded 30s, file saved, 29.8s duration ✅"
- "Test 2: FAIL — no transcript appeared ❌"
- etc.

**If any test FAILS:** fix immediately before continuing development.
**If all 6 PASS:** ForgeIQ VoiceCore is functional — proceed to next phase.

---

## FUTURE: AUTOMATED SMOKE TEST (Phase 2)

XCTest UI automation for Tests 1-6.
Run via `xcodebuild test` before every commit.
Integrate into pre-push hook.
Target: ≥99.5% pass rate (1,000-test-gate standard).
