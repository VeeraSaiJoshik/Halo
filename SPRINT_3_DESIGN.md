# Sprint 3 — AI Reasoning & Alerts

The detection engine finds setups. Sprint 3 turns them into something the trader actually sees: an LLM-generated verdict delivered as a desktop notification and a sidebar insight card.

This doc captures every design decision, why it was made, and the exact flow of data from scored setup → user notification.

> **Architecture update (April 2026):** Halo is now **local-first**. The reasoning model is a small LLM packaged with the app — no remote proxy, no API keys, no per-call cost. The `LocalLlm` interface is documented separately in [docs/LOCAL_LLM_INTEGRATION.md](docs/LOCAL_LLM_INTEGRATION.md). The sections below describing a Node proxy / Anthropic API are kept for historical context but are NOT what's shipping.

---

## Goals

1. When `DetectionEngine.onCandle()` emits a `ScoredSetup` above the AI trigger threshold, send it to Claude for a structured trade thesis.
2. Render that thesis as an OS-level desktop notification (for setups the user should see *now*) and as a persistent card in the Halo sidebar (for review).
3. Keep API keys off the client, avoid spamming Claude with duplicate setups, and don't block the UI thread on network calls.

---

## High-level flow

```
IntakeService           DetectionEngine         AIReasoningService        NotificationService
    │                        │                         │                          │
    │── onNewCandle ────────▶│                         │                          │
    │                        │── scored setups ───────▶│                          │
    │                        │   (score ≥ 3.5 &&       │                          │
    │                        │   approaching)          │                          │
    │                        │                         │── POST /v1/insight ─────▶│ (proxy)
    │                        │                         │                          │
    │                        │                         │◀── ClaudeVerdict ────────│
    │                        │                         │                          │
    │                        │                         │── VerdictDispatcher ────▶│ OS toast
    │                        │                         │                       ────▶ Sidebar stream
```

Four new pieces:

- **`AIReasoningService`** (Dart) — takes a `ScoredSetup`, talks to the proxy, returns a `ClaudeVerdict`.
- **Proxy server** (Node or Dart) — holds the Anthropic API key, forwards prompts, returns responses. Lives outside the Flutter app.
- **`VerdictDispatcher`** (Dart) — deduplicates, rate-limits, and fans out each verdict to notification + sidebar.
- **Sidebar UI** (Flutter) — `InsightPanel` widget showing live and historical verdicts.

---

## Decision 1 — Where the Claude API call lives

**Choice: a tiny proxy server, not the Flutter app directly.**

### Why

An Anthropic API key embedded in a desktop Flutter binary is extractable within minutes — anyone with the binary can strings/grep it out, or intercept the outbound TLS using their own CA. That means leaked keys, abuse, and a bill on the user's (or your) account.

A proxy gives us:

- **Key isolation.** The key lives in one place — a secret manager or env var on the server. The Flutter app never sees it.
- **Rate limiting.** Per-user quotas enforced server-side so a bug in the detection engine (e.g., firing the same setup every candle) can't drain the budget.
- **Prompt caching.** Anthropic's prompt cache works best when the same system prompt and engine schema are reused across many calls. A proxy makes that trivially shareable across users.
- **Observability.** One place to log every prompt/response pair for debugging calibration, audit trails, and monthly cost reporting.
- **Model swaps.** If we want to move from Opus 4.7 → Sonnet 4.6 for cheaper inference, it's a server deploy, not an app update.

### Cost of this choice

We have to run a server. For v1 this is a ~100-line Express or Dart-shelf app deployed to Fly.io or Cloudflare Workers — the cheapest tier covers us until we have real users.

### Rejected alternative

Calling the Anthropic API directly from Dart. Simpler, but the key exposure is a hard no. We'd have to ship a per-user key flow (user pastes their own Anthropic key into settings), which most users won't do and which still leaks in plaintext `shared_preferences`.

### Proxy contract

`POST https://halo-proxy.<host>/v1/insight`

Request:
```json
{
  "symbol": "AAPL",
  "timeframe": "5m",
  "assetProfile": "us_equities",
  "currentPrice": 259.38,
  "atr": 0.2895,
  "setup": {
    "direction": "bearish",
    "score": 4.5,
    "zoneLower": 259.40,
    "zoneUpper": 259.56,
    "priceApproaching": true,
    "flags": ["chopZone", "sameBarSweep"]
  },
  "events": [ /* FVG, sweeps, BOS with timestamps and levels */ ],
  "recentCandles": [ /* last 20 OHLCV bars */ ]
}
```

Response:
```json
{
  "direction": "bearish",
  "confidence": 7,
  "entry": { "type": "limit", "price": 259.50, "zone": [259.40, 259.56] },
  "invalidation": 259.70,
  "target": 258.80,
  "thesis": "Price rejected a fresh bearish FVG with a same-bar sweep and aligned BOS...",
  "keyRisks": ["thin volume into close", "opposing bullish BOS 18 candles back"],
  "generatedAt": "2026-04-10T17:31:02Z",
  "modelVersion": "claude-opus-4-7"
}
```

The proxy enforces:
- `Authorization: Bearer <per-user token>` — issued at app first-launch, stored in OS keychain.
- Per-token quota (e.g., 200 insights/day v1 — tune later).
- Input size cap (~8KB) to prevent runaway prompts.

---

## Decision 2 — Output format from Claude

**Choice: structured JSON matching the response shape above.**

### Why

A free-form prose reply is easy for Claude to write but terrible for:

- **Sidebar UI.** We need specific fields — entry, invalidation, target, confidence — to render consistently.
- **Filtering.** Users will want to hide `confidence ≤ 5` setups. Prose makes that impossible.
- **History search.** "Show me every bearish AAPL insight last week" requires structured fields.

We use Claude's tool-use API (a single tool called `emit_insight` with the schema above) to force a structured response. The `thesis` field carries the prose.

### Prompt caching

The system prompt + asset profile description + scoring legend are all static per profile. We make them a single cached prefix so every call after the first is much cheaper. Structure:

```
[cached prefix — system prompt + profile rules]   ← cache_control: ephemeral
[dynamic — current setup JSON]
```

This hits the 5-minute TTL naturally because each active chart typically generates multiple setups in a session.

---

## Decision 3 — Deduplication and rate limiting

A single setup commonly stays active for many candles. Without dedup, Claude gets hit every 5 minutes with the same setup and the user gets re-notified.

**Choice: setup-fingerprint cache with TTL + "material change" re-trigger.**

### Fingerprint

```
fingerprint = hash(symbol, timeframe, dominantPattern, zoneMidpoint_rounded, score_bucket)
```

- `zoneMidpoint_rounded` — round to 0.25×ATR so the same zone from slightly shifted scans hashes the same.
- `score_bucket` — `floor(score)` so 4.1 → 4.2 doesn't re-trigger, but 4.0 → 5.0 does.

### Re-trigger conditions

A cached fingerprint re-triggers Claude **only if**:
- Score bucket increased (the setup got stronger).
- Flags changed in a structurally meaningful way (e.g., a new aligned BOS was added — moved out of chop zone).
- Price crossed from "not approaching" to "approaching" (structural transition).
- 30 minutes have elapsed since last verdict (stale refresh).

Otherwise we silently return the cached verdict to the UI.

### Rate limit

Client side: no more than 1 insight request per setup per 30s, capped at 10/min global. Server side: same as above plus the per-token daily quota.

---

## Decision 4 — Notification mechanism

**Choice: OS-level desktop notification for high-confidence setups, always an in-app sidebar card.**

### Why both

- **OS notification** wakes the trader when they're in another window. Essential for the "set it and forget it" use case the detection engine was built for.
- **Sidebar card** is the reference — the verdict stays visible as long as the setup is active, the user can re-read the thesis, filter history, etc.

### OS notification trigger

We only fire OS notifications when **all** of:
- `verdict.confidence >= 7` (filter out Claude's "eh, maybe" responses)
- `setup.priceApproaching == true` (price is within 1.5× ATR — actionable now)
- User has notifications enabled for this ticker in settings

Everything else lands in the sidebar silently.

### Implementation

- **macOS/Windows/Linux:** `flutter_local_notifications` package. It handles the platform differences and supports rich notifications (title, body, icon, click-to-focus-app).
- **Click behavior:** clicking the notification brings Halo to front and scrolls the sidebar to the relevant insight card.

### Rejected alternatives

- *In-app toast only* — useless when the trader is on another monitor.
- *System tray with count badge* — doesn't interrupt; user won't see it.
- *Sound alert only* — fine as an option, but alone doesn't convey which ticker.

---

## Decision 5 — UI placement (the "Nuxt sidebar" question)

The conversation memory referenced a "Nuxt sidebar" but the codebase is pure Flutter (no Nuxt, no webview-hosted UI). The sidebar is going to be a Flutter widget, not a Nuxt page.

**Choice: `InsightPanel` — a right-side docked panel in the Flutter app, collapsible, backed by a `StreamController<ClaudeVerdict>`.**

### Why

- The browser tabs already live in Flutter. Crossing into a webview for the sidebar means serializing state across a JS bridge, which is slow and fragile.
- Flutter's `StreamBuilder` is a perfect fit for "live-updating list of cards."
- Keeps the whole data path (engine → verdict → UI) in one language and one process.

### Layout

```
┌──────────────────────────────────────────┬──────────────┐
│  Browser (WebView)                       │  Insights    │
│  [TradingView / broker site]             │  ┌────────┐  │
│                                          │  │ AAPL   │  │
│                                          │  │ ▼ 4.5  │  │
│                                          │  │ 259.40 │  │
│                                          │  │ Claude:│  │
│                                          │  │  ...   │  │
│                                          │  └────────┘  │
│                                          │  ┌────────┐  │
│                                          │  │ SPY ...│  │
│                                          │  └────────┘  │
└──────────────────────────────────────────┴──────────────┘
```

Each card shows:
- Symbol / direction / score / timestamp
- Claude's confidence (color-coded: green ≥7, yellow 5–6, red ≤4)
- Entry / invalidation / target
- Thesis (expandable)
- "Dismiss" and "Pin" actions

---

## Decision 6 — Persistence

Verdicts need to survive app restart. Otherwise the user loses context after crashes.

**Choice: local SQLite via the `sqflite_common_ffi` package (desktop support), one table `insights`.**

### Schema

```sql
CREATE TABLE insights (
  id TEXT PRIMARY KEY,            -- setup fingerprint
  symbol TEXT NOT NULL,
  timeframe TEXT NOT NULL,
  created_at INTEGER NOT NULL,    -- epoch ms
  expires_at INTEGER,             -- when the setup's zone becomes stale
  verdict_json TEXT NOT NULL,     -- the full ClaudeVerdict
  dismissed INTEGER DEFAULT 0,
  pinned INTEGER DEFAULT 0
);
CREATE INDEX idx_insights_symbol_created ON insights(symbol, created_at DESC);
```

On app launch, the `InsightPanel` hydrates from this table (only non-dismissed, non-expired).

### Why SQLite over a file / shared_prefs

- Fast filtered queries ("show last 7 days for AAPL").
- Handles concurrent writes from the dispatcher without corruption.
- Trivial to migrate when we add fields later.

### Rejected alternatives

- JSON file on disk — fine for ≤100 entries, slow at 10k.
- `shared_preferences` — not designed for structured querying.

---

## Decision 7 — Threading

The detection engine runs on the main isolate (it's cheap: O(buffer size) per candle). The Claude network call is **not** cheap — it can take 3–15 seconds.

**Choice: `AIReasoningService` runs the request in a background isolate spawned per-call, returns via `Future<ClaudeVerdict>`.**

### Why

- Blocking the main isolate freezes the UI for seconds.
- Isolates give us true parallelism and crash isolation — if the proxy returns garbage and the JSON parser throws, it doesn't kill the UI.
- We don't need a long-lived worker pool; per-call spawn is fine at <10 req/min throughput.

---

## Decision 8 — Failure handling

Network is unreliable. Claude occasionally 500s. The proxy might be down.

**Behavior:**

| Condition | What the user sees |
|-----------|-------------------|
| Proxy timeout (>15s) | Card in sidebar with "⏳ Reasoning..." spinner. No notification. Retried once in 30s. |
| Proxy 5xx | Card shows "⚠ Insight unavailable — retrying." Exponential backoff up to 3 attempts then silent fail. |
| Proxy 4xx (quota exceeded) | Card shows "Quota exceeded — upgrade for more insights." No retry. |
| Malformed JSON | Logged. Card shows "Engine found the setup but AI analysis failed to parse." |
| User offline | Card shows "Offline — insight will generate when reconnected." Queued. |

No verdict = the engine's raw scored setup is still shown on the card (score, zone, direction) so the user at least sees the setup exists. The AI thesis is additive, not required.

---

## Decision 9 — Configuration / settings surface

New user-facing settings:

- **Enable AI insights** (on/off) — toggles the whole pipeline.
- **Notification confidence threshold** (default 7) — below this, sidebar only.
- **Per-ticker notification mute** (context menu on each ticker tab).
- **Daily insight limit** (display only, shows proxy quota remaining).

Stored in `shared_preferences`. Applied client-side before requests go to the proxy.

---

## Decision 10 — What we're *not* building in Sprint 3

To keep scope sane:

- **No multi-user / accounts.** v1 ships with a single anonymous token per device. Account system is Sprint 4+.
- **No insight sharing / export.** Users can't send a setup to a friend yet.
- **No backtest integration.** Verdicts aren't stored against future price action for win-rate scoring.
- **No streaming responses.** Claude's verdicts arrive as a single complete JSON object, not token-by-token. Desktop use case doesn't benefit much from streaming latency.
- **No voice alerts.** Desktop notification + sidebar is enough.

---

## Implementation order

1. **Proxy server** — minimal Node/Dart app that accepts the request shape, forwards to Anthropic, returns the structured response. Deploy to Fly.io. *[Day 1]*
2. **`AIReasoningService`** (Dart) — HTTP client, isolate spawn, fingerprint cache, retry logic. *[Day 1–2]*
3. **`VerdictDispatcher`** — wires engine output into the service, fans out to notifications + sidebar stream. *[Day 2]*
4. **SQLite persistence layer** — `InsightRepository` with CRUD + stream. *[Day 2]*
5. **`NotificationController`** — real implementation using `flutter_local_notifications`. *[Day 3]*
6. **`InsightPanel` widget** — `StreamBuilder` → list of cards, expandable thesis, dismiss/pin. *[Day 3–4]*
7. **Settings UI** — the 4 toggles above. *[Day 4]*
8. **Wire into `main.dart`** — instantiate everything, connect to existing `DetectionController`. *[Day 4]*
9. **Manual testing** — run against live BTC + SPY/AAPL, verify dedup, notifications fire, sidebar renders. *[Day 5]*
10. **LLM review loop** — send a handful of real verdicts to Claude Opus + Gemini to critique the prompt quality, iterate. *[Day 5+]*

---

## Security summary

- **API key:** server-side only, never ships in binary.
- **Per-user token:** stored in OS keychain, not shared_prefs.
- **TLS:** proxy requires HTTPS; app rejects invalid certs.
- **Input validation:** proxy caps payload size, rejects requests without required fields, strips anything else.
- **Prompt injection:** we only pass numeric fields and enum values from the detection engine to Claude — no raw user input reaches the model in v1, so injection surface is zero.
- **Logging:** proxy logs scrub candle data (user's chart is private) but keep prompt/response metadata for cost attribution.

---

## Performance summary

| Operation | Budget | How we hit it |
|-----------|--------|---------------|
| Engine → setup scored | <5ms | Already met — pure Dart, in-memory. |
| Fingerprint check | <1ms | Map lookup. |
| Proxy round-trip | <3s p50, <8s p99 | Claude Opus latency; we don't fight it. |
| Notification dispatch | <50ms | OS API call. |
| Sidebar render | <16ms | Flutter's diff. |
| SQLite insert | <5ms | One row, indexed. |

The user-perceived latency from "candle closes" to "setup visible in sidebar with spinner" is <100ms. The thesis arrives 3-ish seconds later. Good enough.

---

## Open questions / things to revisit

- **Proxy hosting cost** at scale. Fly.io free tier → when we have users, move to paid. Likely $5–20/mo until we're real.
- **Claude cost per insight.** Back-of-envelope: 4K input tokens cached (cheap) + 1K output tokens = ~$0.02 per call with Opus. At 200/day = $4/user/month. Sustainable if we charge or rate-limit.
- **Notification fatigue.** If 7+ confidence turns out to fire too often, we raise to 8. Easy tune.
- **Sidebar width / collapsibility** — depends on user testing. Ship with 320px default, resizable.
