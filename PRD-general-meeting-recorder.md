===================================================
PRD: ForgeIQ — General iPhone Meeting Recorder (repositioned)
Generated: 2026-06-30
Product: ForgeIQ (alviz.ai)  |  Owner: Kevin
Status: DRAFT — Kevin approves before build. Repositions ForgeIQ from B2B sales-intelligence
        to a general meeting recorder; sales features PARKED (flag-gated) as a future upsell.
===================================================

EXPLICIT LOCKED-DECISION CHANGES (not silent — per decision-consistency gate):
 1. POSITIONING: CLAUDE.md lines 10-11 position ForgeIQ as "B2B sales intelligence". This PRD
    repositions it as a GENERAL meeting recorder (Plaud-killer). Sales modules are PARKED, not deleted.
 2. PAYMENTS: CLAUDE.md lists Stripe (Phase 4). iOS digital subscriptions REQUIRE Apple IAP — this PRD
    REUSES Vizion Scan's proven, App-Store-APPROVED RevenueCat paywall (SubscriptionManager.swift +
    PaywallView.swift), NOT Stripe and NOT a from-scratch StoreKit build. RevenueCat handles the
    2-week intro free trial, entitlements, and Apple subscription management.

1. PROBLEM STATEMENT
   AI meeting recorders (Plaud ~$159 hardware + subscription, Otter, etc.) are expensive because
   they pay per-minute for cloud transcription + AI. ForgeIQ does transcription ON-DEVICE (Apple
   Speech, $0 marginal cost), so it can undercut them as an iPhone-only app. Kevin was a paying Plaud
   customer — he is the first user and knows the willingness-to-pay.

2. TARGET USER
   Anyone who records meetings/calls and wants a transcript + AI summary on their iPhone with no
   extra hardware. First user: Kevin (daily). User story: As a professional, I want to hit one button
   to record, get an on-device transcript, and an AI summary, so I never take meeting notes again.

3. SUCCESS CRITERIA (measurable)
   SC1. Core loop works end-to-end on a real iPhone: record -> on-device transcript -> AI summary -> saved.
   SC2. Monetization: 2-week free trial via StoreKit IAP, then auto-converts to a paid subscription.
   SC3. App Store approved — all 3 ios-submission gates pass (paywall .sheet, sub-management in
        Settings, free-tier smoke test).

4. REQUIREMENTS
   R1. VoiceCore (KEEP): record (AVFoundation), on-device transcribe (Apple SFSpeechRecognizer),
       optional on-device translation, .txt save, Files tab + search, transcript detail + share.
   R2. General AI Summary (GENERALIZE): backend Claude call returns a GENERAL meeting summary —
       { summary, key_points[], action_items[], decisions[], next_steps[] }. Remove the sales-specific
       fields (blown_past, talk_time, call_score) from the shipped path.
   R3. Monetization (REUSE, not new-build): copy Vizion Scan's RevenueCat SubscriptionManager +
       PaywallView (already App-Store-approved, .sheet-based per Apple 3.1.2c). Add a ForgeIQ app +
       offering in RevenueCat + App Store Connect with products (forgeiq_pro_monthly etc.) and a
       2-week intro free trial. "Manage Subscription" in Settings (Apple 2.1b). Converts to paid at day 14.
   R4. Sales tier PARKED (PRESERVE — do NOT delete): BlownPast, call-score, Pipedrive auto-log stay
       in-repo, flag-gated OFF via user_subscriptions (CLAUDE.md PRINCIPLE 5). Re-enabled later as the
       "Sales/Business" upsell tier. Zero code thrown away.
   R5. Auth0 login, multi-user, every query WHERE user_id (CLAUDE.md PRINCIPLES 3-4 unchanged).

5. ACCEPTANCE CRITERIA (binary)
   AC1. [ ] Fresh user records a 1-min clip -> transcript appears (on-device) -> AI summary returns
            general fields (no sales fields) -> saved + searchable.
   AC2. [ ] New install starts a 2-week free trial (StoreKit); at trial end it converts to paid OR
            locks premium features; status visible in Settings.
   AC3. [ ] Paywall is a .sheet with PP + EULA links; "Manage Subscription" opens Apple's sheet in 1 tap.
   AC4. [ ] Free-trial user completes record->summary without hitting a hard paywall mid-core-flow.
   AC5. [ ] Sales modules are present in the repo but return disabled/404 for non-sales-tier users.
   AC6. [ ] grep '\.alert(' for paywall returns ZERO (ios-submission Gate 1).

6. TECHNICAL APPROACH
   iOS: keep VoiceCore + Admin (Profile/Login); COPY vizion-scanner's SubscriptionManager.swift +
   PaywallView.swift, swap product/entitlement IDs to forgeiq_*. Backend: generalize callSummaryService
   prompt + response schema; keep sales routes behind the feature flag. Sales UI screens hidden unless
   the sales flag is on. Device build needs Kevin's Apple sign-in (0 provisioning profiles today) —
   generate profile with -allowProvisioningUpdates. RevenueCat + App Store Connect accounts already
   exist (used by Vizion Scan) — add a ForgeIQ app/offering, not a new account.

7. CTQ TARGETS
   Primary: trial-to-paid conversion rate (measure after launch; target TBD with Kevin).
   Core: record->summary success rate >= 99% on a supported device; on-device transcription = $0 cost.

8. BLAST RADIUS
   If wrong: a rejected App Store submission (7-day delay each) or a broken paywall (no revenue).
   Mitigation: run the 3 ios-submission gates BEFORE submit; test trial->paid in StoreKit sandbox first.
   Sales code is flag-gated, so parking it cannot break the shipped app.

9. OUT OF SCOPE (this release)
   - Stripe (replaced by Apple IAP). - The sales/business tier features (parked, flag-gated).
   - Vapi calling agent, SigmaVault stats, DOE, SalesForge, ApexScript (all already Phase 2+).
   - The "better" long-term pricing plan (Kevin will develop post-adoption).

10. TEST PLAN
   Happy path: fresh device install -> trial starts -> record -> transcript -> summary -> save.
   Edge: trial expiry -> conversion/lock; airplane mode (on-device transcribe still works, AI summary
   queues/errors gracefully). Error: denied mic permission -> clear UI message. Kevin test: install on
   your iPhone -> record a real meeting -> read the AI summary -> confirm it's genuinely useful.

11. COMPLEXITY ESTIMATE
   [ ] M — paywall is a COPY of Vizion Scan's approved RevenueCat code (not from scratch); summary
   generalization is small; VoiceCore + AI summary core already BUILT + backend live. Real remaining
   work: copy/adapt the paywall, generalize the summary, configure RevenueCat/ASC offering + trial,
   device build (Kevin Apple sign-in), App Store submission (3 gates).
===================================================
