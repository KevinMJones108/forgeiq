# EPDirectory.com — Full Functional UAT Plan

**Tester:** Owen / Kevin
**Date executed:** ______________
**Build / commit tested:** ______________
**Browser + OS:** ______________

How to use this document:
- Walk every section top-to-bottom.
- Mark each step: `PASS` / `FAIL` / `BLOCKED` / `N/A`.
- When a step fails, fill in the **Bug Report** block under that step. Don't try to fix in your head — capture the raw observation.
- At the end, count failures by severity. Anything `S1` or `S2` blocks release.

Severity key:
- **S1 — Blocker:** Core function unusable (login broken, search returns nothing, app crashes).
- **S2 — Major:** Function works but produces wrong/stale data or breaks a key workflow (continuous search doesn't refresh, PDF missing data, graph wrong).
- **S3 — Minor:** Cosmetic, slow, confusing UX, edge case.
- **S4 — Trivial:** Typo, alignment, copy.

---

## 0. Pre-flight

- [ ] 0.1 Site loads at the production URL within 5 seconds.
- [ ] 0.2 HTTPS valid (no cert warning).
- [ ] 0.3 Login as **Jim** (procurement / standard user account).
- [ ] 0.4 Login as **Owen** (sales account) in a second browser / incognito to test multi-user isolation.
- [ ] 0.5 Browser devtools network tab open — flag any 4xx/5xx during the run.
- [ ] 0.6 Browser devtools console open — flag any JS errors during the run.

**Bug Report Block (copy/fill if any 0.x fails):**
```
ID: BUG-EPD-000-__
Severity: __
Step: 0.__
Expected: ____
Actual: ____
Repro: ____
Screenshot: ____
Console / network errors: ____
```

---

## 1. Authentication & Session

- [ ] 1.1 Login form accepts valid credentials and lands on the dashboard.
- [ ] 1.2 Login form rejects wrong password with a clear error (not a generic 500).
- [ ] 1.3 Forgot-password flow sends a reset email (check inbox + spam).
- [ ] 1.4 Session persists on page refresh.
- [ ] 1.5 Logout clears session (back-button shouldn't show authenticated page from cache).
- [ ] 1.6 Idle timeout behaves as documented (note actual minutes).
- [ ] 1.7 Owen's account cannot see Jim's saved searches / watchlists / projects.

---

## 2. Top Menu Walk — every link, every tab

Walk each top-nav item and every sub-menu. For each: load, render, no JS errors, all controls clickable.

- [ ] 2.1 Home / Dashboard
- [ ] 2.2 Search (Parts / Components)
- [ ] 2.3 Obsolescence
- [ ] 2.4 Commodity / Materials
- [ ] 2.5 Projects / Watchlists
- [ ] 2.6 Reports / PDF Export
- [ ] 2.7 Account / Settings
- [ ] 2.8 Help / Support
- [ ] 2.9 Admin (if visible to this role — should NOT be visible to Jim)

For each tab that fails to render or has dead controls, file a bug.

---

## 3. "Jim Functions" — procurement workflow

These are the functions Jim (procurement / ops manager persona) actually uses day-to-day. Confirm with Kevin/Owen if any are missing from this list before executing.

- [ ] 3.1 Quick part lookup by manufacturer P/N (try a known good: `1756-L83E`).
- [ ] 3.2 Part lookup returns: manufacturer, description, lifecycle status, last-updated date, datasheet link.
- [ ] 3.3 Datasheet link opens (PDF or external).
- [ ] 3.4 "Add to Watchlist" / "Save Search" persists across logout/login.
- [ ] 3.5 Edit and rename a saved watchlist.
- [ ] 3.6 Delete a saved watchlist — confirm prompt appears.
- [ ] 3.7 Bulk import of part numbers (CSV upload) — try 10 valid + 2 garbage rows; garbage should be flagged not silently dropped.
- [ ] 3.8 Export watchlist to CSV.
- [ ] 3.9 Share / email a watchlist (if supported).
- [ ] 3.10 Notification preferences page saves changes.

---

## 4. Continuous Search — refresh & freshness

This is a known pain point. Test it rigorously.

- [ ] 4.1 Create a new continuous search on a part you know is active (e.g. `1756-L83E`).
- [ ] 4.2 Note the **timestamp** of creation and the **"last updated"** timestamp shown.
- [ ] 4.3 Trigger a manual refresh — does the timestamp advance?
- [ ] 4.4 Add a new continuous search — does the list update **immediately** without a hard page refresh?
- [ ] 4.5 Remove a continuous search — does it disappear **immediately** without a hard page refresh?
- [ ] 4.6 Leave a continuous search running for 1 hour; return — has it polled? What's the latency between expected and actual update?
- [ ] 4.7 Network tab: how often does the page poll? (Note the endpoint and interval.) If it's not polling, the "continuous" claim is broken.
- [ ] 4.8 Two browser tabs open to the same watchlist — does an update in tab A reflect in tab B without a manual refresh? (Tests websocket / SSE wiring.)
- [ ] 4.9 Add 20 continuous searches — does the page still feel responsive? Note time-to-interactive.
- [ ] 4.10 Continuous search with a typo / nonsense part — does it fail gracefully or hang forever?

**This section's failures are likely S2 minimum. The product promise is "continuous."**

---

## 5. Obsolescence — real-world PLC checks

Run these against parts engineering actually asks about. Capture the lifecycle status the app returns, then compare against what's true on the manufacturer's site.

### 5.1 Allen-Bradley (Rockwell)

| # | Part | Family | Vintage | App says | Truth (Rockwell PCDC) | Match? |
|---|------|--------|---------|----------|----------------------|--------|
| 5.1.1 | `1756-L61` | ControlLogix L6 | ~2003 | | Discontinued | |
| 5.1.2 | `1756-L73` | ControlLogix L7 | ~2010 | | Active (mature) | |
| 5.1.3 | `1756-L83E` | ControlLogix L8 | ~2015 | | Active | |
| 5.1.4 | `1769-L32E` | CompactLogix L3 | ~2005 | | Discontinued | |
| 5.1.5 | `1769-L33ER` | CompactLogix 5370 | ~2012 | | Active (mature) | |
| 5.1.6 | `5069-L320ER` | CompactLogix 5380 | ~2017 | | Active | |
| 5.1.7 | `1747-L551` | SLC 500 | ~1998 | | Discontinued | |
| 5.1.8 | `1785-L40B` | PLC-5 | ~1995 | | Discontinued | |
| 5.1.9 | `1761-L16BWA` | MicroLogix 1000 | ~1997 | | Discontinued | |
| 5.1.10 | `2080-LC50-24QWB` | Micro850 | ~2013 | | Active | |

### 5.2 Siemens

| # | Part | Family | Vintage | App says | Truth (Siemens Mall) | Match? |
|---|------|--------|---------|----------|---------------------|--------|
| 5.2.1 | `6ES7314-1AG14-0AB0` | S7-300 CPU 314 | ~2008 | | Phase-out 2023, end-of-service 2028 | |
| 5.2.2 | `6ES7315-2EH14-0AB0` | S7-300 CPU 315F | ~2010 | | Same as above | |
| 5.2.3 | `6ES7416-3ES07-0AB0` | S7-400 CPU 416 | ~2012 | | Active, mature | |
| 5.2.4 | `6ES7214-1AG40-0XB0` | S7-1200 CPU 1214C | ~2014 | | Active | |
| 5.2.5 | `6ES7215-1AG40-0XB0` | S7-1200 CPU 1215C | ~2015 | | Active | |
| 5.2.6 | `6ES7515-2AM02-0AB0` | S7-1500 CPU 1515-2 PN | ~2017 | | Active | |
| 5.2.7 | `6ES7516-3AN02-0AB0` | S7-1500 CPU 1516-3 PN/DP | ~2018 | | Active | |
| 5.2.8 | `6ES5095-8MA05` | S5-95U | ~1990 | | Discontinued | |

### 5.3 Obsolescence engineering assessment

For any part the app marks as discontinued / phase-out, the app should also provide:

- [ ] 5.3.1 **Recommended replacement** P/N.
- [ ] 5.3.2 **Last-time-buy (LTB) date** if applicable.
- [ ] 5.3.3 **End-of-service / end-of-support date.**
- [ ] 5.3.4 **Form-fit-function notes** (drop-in vs migration required).
- [ ] 5.3.5 **Migration tool / guide link** (Rockwell publishes these; Siemens has TIA migration tools).
- [ ] 5.3.6 **Confidence / source citation** — where did this data come from and when was it last refreshed?

If any of those six are missing, that's an S2 — engineering can't sign off without them.

---

## 6. Commodity Search & Continuous Commodity Tracking

- [ ] 6.1 One-shot commodity lookup — **Copper** spot price. App shows: current price, currency, units (USD/lb? USD/MT?), timestamp, source.
- [ ] 6.2 Same for **Lead**.
- [ ] 6.3 Same for **Aluminum**.
- [ ] 6.4 Same for **Nickel**.
- [ ] 6.5 Same for **Tin** (relevant for solder).
- [ ] 6.6 Same for **Silver** (contacts / relays).
- [ ] 6.7 Same for **Gold** (connectors).
- [ ] 6.8 Price source clearly cited (LME? COMEX? Fastmarkets?).
- [ ] 6.9 Stale-data warning if the quote is > 24h old.

### Continuous commodity search

- [ ] 6.10 Set up a continuous tracker on Copper.
- [ ] 6.11 Set a price-threshold alert (e.g. "notify if Cu > $X/lb"). Does the threshold form save?
- [ ] 6.12 Trigger the alert by setting a threshold below current — does the notification fire (email / in-app)?
- [ ] 6.13 Remove the tracker — does it disappear immediately without page refresh?
- [ ] 6.14 Add 5 commodity trackers — does the dashboard still render in < 2s?

---

## 7. Graphs — do they actually tell the user what they need?

For each commodity from §6, open the chart view and verify:

- [ ] 7.1 Chart renders (no blank canvas).
- [ ] 7.2 X-axis: time, with sensible tick marks (days for 1mo, weeks for 1y).
- [ ] 7.3 Y-axis: price with units labeled.
- [ ] 7.4 Time-range selector works: 1D, 1W, 1M, 3M, 1Y, 5Y, All.
- [ ] 7.5 Hover/tap on a data point shows date + price tooltip.
- [ ] 7.6 Multi-series overlay (e.g. Cu vs Pb) — works and is color-distinguishable.
- [ ] 7.7 Y-axis re-scales correctly when a new series is added.
- [ ] 7.8 Trend / moving-average overlay (if supported) — actually plots.
- [ ] 7.9 Chart is legible on mobile width (responsive).
- [ ] 7.10 Chart matches the numeric data table (no chart-vs-table mismatch).

**Plain-English check (the actual product question):** *"Looking at this chart for 5 seconds, can a buyer say 'price is up / down / flat, by roughly X%, and I should buy now / wait'?"* If no — that's an S2 UX failure even if the chart technically renders.

---

## 8. PDF Export

For each report type the app offers, generate a PDF and inspect.

- [ ] 8.1 Part-detail PDF — opens, shows manufacturer / P/N / lifecycle / datasheet link.
- [ ] 8.2 Watchlist PDF — every row from the on-screen watchlist appears, in same order.
- [ ] 8.3 Obsolescence-assessment PDF — includes the six fields from §5.3.
- [ ] 8.4 Commodity-tracker PDF — includes the chart image **and** the underlying data table.
- [ ] 8.5 PDF header has: report title, date generated, user name, EPDirectory branding.
- [ ] 8.6 PDF footer has: page X of Y.
- [ ] 8.7 PDF prints to physical printer without clipping (A4 and Letter both).
- [ ] 8.8 PDF file size reasonable (< 5MB for a 10-row watchlist).
- [ ] 8.9 PDF generated within 10 seconds for a typical report.
- [ ] 8.10 PDF accessibility — text is selectable (not a flattened image).

---

## 9. Cross-cutting concerns

- [ ] 9.1 Any operation > 3s shows a loading spinner.
- [ ] 9.2 Any failed network call shows a user-readable error, not a raw stack trace.
- [ ] 9.3 Browser back button never breaks the app state.
- [ ] 9.4 Forms preserve user input on validation error (don't blank the form).
- [ ] 9.5 Numeric inputs accept comma and decimal separators correctly per locale.
- [ ] 9.6 Dates display in a consistent format throughout.
- [ ] 9.7 No mixed-content warnings (all assets HTTPS).
- [ ] 9.8 No console errors during a full walk-through.

---

## 10. Performance budget

Capture rough numbers (Chrome devtools Lighthouse or Network tab):

- [ ] 10.1 Dashboard time-to-interactive: ____ s (target < 3s)
- [ ] 10.2 Part-search first result: ____ s (target < 2s)
- [ ] 10.3 Continuous-search poll endpoint latency: ____ ms (target < 500ms)
- [ ] 10.4 PDF generation: ____ s (target < 10s)
- [ ] 10.5 Chart render for 1Y daily data: ____ s (target < 1s)

---

## Summary roll-up (fill at end)

| Section | Total steps | Pass | Fail | Blocked |
|---------|-------------|------|------|---------|
| 0 Pre-flight | 6 | | | |
| 1 Auth | 7 | | | |
| 2 Menu walk | 9 | | | |
| 3 Jim functions | 10 | | | |
| 4 Continuous search | 10 | | | |
| 5 Obsolescence | 24 | | | |
| 6 Commodity | 14 | | | |
| 7 Graphs | 10 | | | |
| 8 PDF | 10 | | | |
| 9 Cross-cutting | 8 | | | |
| 10 Performance | 5 | | | |

**Open bugs by severity:** S1 ___ · S2 ___ · S3 ___ · S4 ___

**Release recommendation:** GO / NO-GO — ______________

---

## Next step for Kevin

Once Owen runs through this and we have a failure list, send back to Claude:
1. This filled-in document (failures + repro steps).
2. The EPDirectory **repo URL** and either grant my GitHub MCP scope access OR start a Claude Code session inside the EPDirectory repo.
3. A **Render API key** if you want me to pull live logs / service config (drop into env as `RENDER_API_KEY` and tell me).

With any one of those three, I can move from "test plan" to "diagnosed root cause + patch."
