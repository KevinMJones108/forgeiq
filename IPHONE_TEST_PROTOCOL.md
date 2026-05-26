# ForgeIQ iPhone Testing Protocol
# Version: 1.0 — May 2026
# Test on Kevin's physical device before declaring VoiceCore complete

---

## PRE-TEST SETUP (ONE TIME)

### 1. Xcode Device Configuration (5 min)

**Connect iPhone:**
1. Plug iPhone into Mac via USB cable
2. Xcode → Window → Devices and Simulators → Devices tab
3. Verify iPhone appears in left sidebar
4. If "Trust This Computer?" alert → Trust on both iPhone and Mac

**Signing Setup:**
1. Open ForgeIQ.xcodeproj in Xcode
2. Select ForgeIQ target → Signing & Capabilities tab
3. Team dropdown → Select Kevin's Apple Developer account
4. Bundle Identifier → Verify: `ai.alviz.forgeiq`
5. If "Signing Certificate" error → Xcode → Preferences → Accounts → Download Manual Profiles

**Build Configuration:**
1. Xcode toolbar → Select Kevin's iPhone (not "Any iOS Device")
2. Product → Scheme → Edit Scheme → Run → Info → Build Configuration → Debug
3. Product → Destination → Kevin's iPhone [model name]

**Permissions Check (Info.plist):**
- `NSMicrophoneUsageDescription` present
- `NSSpeechRecognitionUsageDescription` present
- App Transport Security allows localhost (for dev API testing)

---

## TEST CASE 1: AUDIO RECORDING (CRITICAL)

**OBJECTIVE:** Verify microphone access + AVFoundation recording works

**PRECONDITIONS:**
- iPhone connected, app built successfully
- No other audio apps running (close Music, Voice Memos)

**TEST STEPS:**
1. Xcode → Product → Run (⌘R)
2. On iPhone: Allow microphone access prompt (first launch only)
3. Tap center animated button (state: IDLE → RECORDING)
4. Speak continuously for 10 seconds: "Testing ForgeIQ audio recording on Kevin's iPhone"
5. Observe waveform animation during speech
6. Tap button again to stop (state: RECORDING → PROCESSING)

**EXPECTED RESULTS:**
✅ Button animates to red RECORDING state
✅ Waveform bars animate in ForgeGreen (#00C853)
✅ Waveform responds to voice volume (louder = taller bars)
✅ No crashes, no microphone permission errors
✅ Button returns to IDLE after processing completes

**PASS/FAIL CRITERIA:**
- **PASS:** Waveform animates smoothly, no console errors, recording completes
- **FAIL:** No waveform animation, console shows AVAudioRecorder error, app crashes

**KNOWN ISSUES:**
- First launch: 2-3 second delay before waveform starts (normal — AVFoundation init)
- Simulator: waveform will NOT animate (no mic) — device-only test

**IF TEST FAILS:**
1. Check Xcode console for `AVAudioRecorder` errors
2. Settings → Privacy & Security → Microphone → ForgeIQ → toggle OFF then ON
3. Verify Info.plist microphone description key exists
4. Clean Build Folder (⌘⇧K) and rebuild

---

## TEST CASE 2: SPEECH-TO-TEXT (CRITICAL)

**OBJECTIVE:** Verify Apple SFSpeechRecognizer real-time transcription

**PRECONDITIONS:**
- Test Case 1 passed
- iPhone language set to English (Settings → General → Language & Region)

**TEST STEPS:**
1. Start new recording (tap button)
2. Speak clearly: "ForgeIQ is a Six Sigma sales intelligence platform built by Kevin Jones"
3. Watch transcript text area below waveform
4. Stop recording after 15 seconds

**EXPECTED RESULTS:**
✅ Transcript text appears word-by-word during recording (real-time)
✅ Accuracy ≥ 90% (minor punctuation errors acceptable)
✅ Final transcript shows complete sentence
✅ No "Speech recognition not available" errors

**PASS/FAIL CRITERIA:**
- **PASS:** Transcript captures ≥ 90% of spoken words, real-time updates visible
- **FAIL:** No transcript appears, console shows `SFSpeechRecognizer` unavailable, <70% accuracy

**KNOWN ISSUES:**
- First word may be delayed 1-2 seconds (normal SFSpeechRecognizer warmup)
- Chinese iPhone: must enable English keyboard in Settings
- Airplane mode: on-device STT works but cloud-enhanced features disabled

**IF TEST FAILS:**
1. Check Xcode console for `SFSpeechRecognizer` authorization errors
2. Settings → Privacy & Security → Speech Recognition → ForgeIQ → toggle ON
3. Verify device language matches app language setting
4. Restart iPhone (speech recognition service can hang)

---

## TEST CASE 3: FILE PERSISTENCE (CRITICAL)

**OBJECTIVE:** Verify .txt transcript saves to app Documents directory

**PRECONDITIONS:**
- Test Case 2 passed (transcript generated)

**TEST STEPS:**
1. After recording stops, wait for state: PROCESSING → IDLE (2-3 sec)
2. Tap "Files" tab at bottom of screen
3. Verify new transcript appears in list
4. Tap transcript row to open detail view
5. Verify transcript text matches what was spoken
6. Note filename format: `YYYY-MM-DD_HH-mm-ss.txt`

**EXPECTED RESULTS:**
✅ Transcript appears in Files tab within 3 seconds
✅ Filename includes correct timestamp
✅ Opening transcript shows full text
✅ Share button works (tap → verify iOS share sheet appears)

**PASS/FAIL CRITERIA:**
- **PASS:** Transcript saved, filename correct, text readable, share works
- **FAIL:** Files tab empty, transcript text truncated, crashes on open

**KNOWN ISSUES:**
- First save may take 5 seconds (FileManager first write)
- 0-byte file = save failed (check console for permission errors)

**IF TEST FAILS:**
1. Xcode → Window → Devices and Simulators → [iPhone] → Installed Apps → ForgeIQ → Show Container
2. Navigate to Documents/ folder → verify .txt file exists
3. If missing: check console for FileManager write errors
4. Verify app has document directory access (should be default)

---

## TEST CASE 4: TRANSLATION (HIGH PRIORITY)

**OBJECTIVE:** Verify Apple Translation Framework works on-device

**PRECONDITIONS:**
- Test Case 3 passed (transcript exists)
- iPhone has Spanish language pack downloaded (Settings → General → Dictionary)

**TEST STEPS:**
1. Open existing transcript from Files tab
2. Tap "Translate" button (if visible in UI)
3. Select Spanish (Español) as target language
4. Wait for translation (3-5 seconds)
5. Verify Spanish text appears below English transcript

**EXPECTED RESULTS:**
✅ Translation completes within 5 seconds
✅ Spanish text is grammatically correct
✅ No "Translation unavailable" errors
✅ Original English transcript unchanged

**PASS/FAIL CRITERIA:**
- **PASS:** Spanish translation appears, meaning preserved, no errors
- **FAIL:** Translation button disabled, error "Language pack not available", gibberish output

**KNOWN ISSUES:**
- First translation: 10-15 second delay (downloading language model)
- Offline mode: translation works but slower
- Non-English source: must specify source language explicitly

**IF TEST FAILS:**
1. Settings → General → Dictionary → Download Spanish
2. Check Xcode console for `Translation` framework errors
3. iOS 17.0+ required (earlier versions lack on-device translation)
4. Restart app after language pack downloads

---

## TEST CASE 5: ELEVENLABS TTS PLAYBACK (HIGH PRIORITY)

**OBJECTIVE:** Verify text-to-speech audio playback via Node.js proxy

**PRECONDITIONS:**
- Backend running (local or Render)
- Test Case 3 passed (transcript exists)
- Network connectivity (Wi-Fi or cellular)

**TEST STEPS:**
1. Open transcript from Files tab
2. Tap "Play Audio" button (TTS icon)
3. Wait for audio generation (3-7 seconds)
4. Listen to full playback
5. Verify audio matches transcript text

**EXPECTED RESULTS:**
✅ Audio starts playing within 7 seconds
✅ Voice is natural (ElevenLabs quality)
✅ All transcript text is spoken
✅ No audio glitches or cutoffs

**PASS/FAIL CRITERIA:**
- **PASS:** Audio plays completely, quality ≥ 90%, no errors
- **FAIL:** No audio, console shows 401/500 error, audio cuts off mid-sentence

**KNOWN ISSUES:**
- First TTS call: 10-15 seconds (ElevenLabs cold start)
- Large transcripts (>500 words): may timeout (split into chunks in backend)
- No network: TTS will fail (show user-friendly error)

**IF TEST FAILS:**
1. Check backend logs: `POST /api/v1/voice/tts` response code
2. Verify `ELEVEN_LABS_API_KEY` set in backend .env
3. Test backend directly: `curl -X POST [backend]/api/v1/voice/tts -H "Authorization: Bearer [jwt]" -d '{"text":"test"}'`
4. Check ElevenLabs account quota (free tier: 10k chars/month)

---

## TEST CASE 6: AUTH FLOW (CRITICAL)

**OBJECTIVE:** Verify Auth0 login + JWT persistence

**PRECONDITIONS:**
- iPhone has Safari installed (Auth0 uses ASWebAuthenticationSession)
- Auth0 tenant configured with iOS callback URL

**TEST STEPS:**
1. Fresh install or delete app data (Settings → ForgeIQ → Reset)
2. Launch app → should show login screen
3. Tap "Sign In" → Safari sheet opens
4. Enter Kevin's credentials (or use biometric if saved)
5. Auth0 redirects back to app
6. Verify HomeView appears (authenticated state)
7. Kill app, relaunch → verify stays logged in (JWT persisted)

**EXPECTED RESULTS:**
✅ Login sheet opens in Safari ASWebAuthenticationSession
✅ After login: redirect back to app within 3 seconds
✅ HomeView shows immediately (no re-login)
✅ JWT stored securely in Keychain
✅ App stays logged in after force-quit and relaunch

**PASS/FAIL CRITERIA:**
- **PASS:** Login succeeds, redirect works, JWT persists across launches
- **FAIL:** Login sheet doesn't open, redirect fails, re-login required every launch

**KNOWN ISSUES:**
- First login: 5-10 seconds (Auth0 session init)
- If "Invalid Callback URL" error: check Auth0 dashboard → Application Settings → Allowed Callback URLs
- Safari private mode: login may fail (disable in Settings → Safari)

**IF TEST FAILS:**
1. Check Auth0 dashboard: Application → Settings → Allowed Callback URLs includes `ai.alviz.forgeiq://[tenant].auth0.com/ios/ai.alviz.forgeiq/callback`
2. Verify Constants.swift AUTH0_DOMAIN and AUTH0_CLIENT_ID match Auth0 dashboard
3. Check Xcode console for `Auth0.swift` error messages
4. Test Auth0 credentials in browser first: https://[tenant].auth0.com/

---

## CTQ VERIFICATION CHECKLIST

After all test cases, verify Critical-To-Quality metrics:

**CTQ_1 [Real-Time STT]:** PASS if transcript updates word-by-word during recording ✓
**CTQ_2 [Audio Fidelity]:** PASS if waveform animates smoothly with no glitches ✓
**CTQ_3 [File Persistence]:** PASS if .txt saved within 3 seconds, accessible from Files tab ✓
**CTQ_4 [Translation Accuracy]:** PASS if Spanish translation preserves meaning ✓
**CTQ_5 [TTS Quality]:** PASS if ElevenLabs audio plays completely, natural voice ✓
**CTQ_6 [Auth Security]:** PASS if JWT stored in Keychain, persists across launches ✓

**OVERALL PASS CRITERIA:**
All 6 CTQs must PASS. If any CTQ fails → fix before Kevin demo.

---

## COMMON ISSUES & FIXES

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| No waveform animation | Simulator (no mic) or mic permission denied | Test on device, check Settings → Privacy → Microphone |
| Transcript empty | SFSpeechRecognizer not authorized | Settings → Privacy → Speech Recognition → ForgeIQ ON |
| Files tab empty | FileManager save failed | Check console for write errors, verify Documents/ path |
| TTS no audio | Backend env var missing or ElevenLabs quota exceeded | Verify ELEVEN_LABS_API_KEY set, check quota |
| Login sheet doesn't open | Auth0 callback URL mismatch | Check Auth0 dashboard → Allowed Callback URLs |
| App crashes on launch | Missing Info.plist keys | Verify NSMicrophoneUsageDescription + NSSpeechRecognitionUsageDescription present |
| Real-time transcript delayed | iPhone language ≠ app language | Settings → General → Language & Region → English |
| Share button doesn't work | UIActivityViewController error | Check console, verify transcript.text not nil |

---

## TROUBLESHOOTING COMMANDS

**Check app logs:**
```bash
# Real-time console output from connected iPhone
xcrun simctl spawn booted log stream --predicate 'subsystem == "ai.alviz.forgeiq"' --level=debug
```

**Verify file saved:**
```bash
# List app Documents directory on device
xcrun devicectl device info files --device [UDID] --domain appDataContainer --path Documents/
```

**Check permissions:**
```bash
# Query microphone authorization status
tccutil reset Microphone ai.alviz.forgeiq
```

**Force clean build:**
```bash
cd /Users/kevinmarlesjones/qbo/forgeiq/forgeiq-api
rm -rf ~/Library/Developer/Xcode/DerivedData/ForgeIQ-*
xcodebuild clean -project ForgeIQ.xcodeproj -scheme ForgeIQ
```

---

## TEST EXECUTION LOG

**Tester:** Kevin Jones  
**Date:** [YYYY-MM-DD]  
**iPhone Model:** [e.g., iPhone 15 Pro]  
**iOS Version:** [e.g., 17.4]  
**Xcode Version:** [e.g., 16.0]  
**Backend:** [Local / Render]

| Test Case | Status | Notes |
|-----------|--------|-------|
| 1. Audio Recording | ⬜ PASS / ⬜ FAIL | |
| 2. Speech-to-Text | ⬜ PASS / ⬜ FAIL | |
| 3. File Persistence | ⬜ PASS / ⬜ FAIL | |
| 4. Translation | ⬜ PASS / ⬜ FAIL | |
| 5. ElevenLabs TTS | ⬜ PASS / ⬜ FAIL | |
| 6. Auth Flow | ⬜ PASS / ⬜ FAIL | |

**Overall Result:** ⬜ ALL PASS — Ready for Kevin demo  
**Blockers:** [List any failures requiring fixes before demo]

---

## NEXT STEPS AFTER TESTING

**If all tests PASS:**
1. Record 3 real sales call transcripts (Owen's EPDirectory calls)
2. Test Call Summary + Blown Past Detector (Session 10 features)
3. Verify Pipedrive auto-log integration
4. Deploy backend to Render production
5. Submit TestFlight build for Kevin + Owen

**If any test FAILS:**
1. Document exact failure in Test Execution Log above
2. Check "IF TEST FAILS" section for that test case
3. Fix root cause in code
4. Re-run failed test + regression check (other tests still pass)
5. Do not proceed to Session 10 until VoiceCore 100% stable

**Kevin Approval Required Before:**
- TestFlight submission
- Render production deployment
- Adding Session 10 AI features
- Starting Phase 2 (IdeaVault)

---

END OF PROTOCOL
