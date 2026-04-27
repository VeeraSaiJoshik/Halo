# Local LLM Integration Guide

This is the contract for plugging a local LLM into Halo. Implement one Dart class, register it in the provider, and the rest of the app — dispatcher, sidebar, notifications, persistence — works automatically.

---

## TL;DR

1. Pick a model and a runtime (llama.cpp via FFI, ONNX runtime, GGML, whatever).
2. Implement `LocalLlm` in `lib/ai/local_llm/<your_impl>.dart`.
3. Override `localLlmProvider` in `main.dart` to return your implementation.
4. Done. Halo will start sending it `LlmRequest` objects and rendering the `Verdict`s it returns.

You do NOT need to touch:
- The detection engine
- The dispatcher / cache / dedup logic
- The sidebar UI
- Notifications
- Persistence (SQLite)

---

## The interface

`lib/ai/local_llm/local_llm.dart`

```dart
abstract class LocalLlm {
  String get modelId;
  bool get isReady;

  Future<void> load();
  Future<Verdict> generate(LlmRequest request);
  Future<void> dispose();
}
```

That's it. Three methods.

### `modelId`

A short string identifying the model. Surfaced in:
- The verdict's `modelId` field (visible in the sidebar card)
- Telemetry / logs

Examples: `"llama-3.2-3b-instruct-q4_k_m"`, `"phi-3-mini-4k-instruct-q4"`, `"qwen-2.5-1.5b-q5"`.

### `load()`

Called once before the first `generate()`. Open the model file, allocate buffers, run a tiny warm-up if needed.

- **Idempotent**: calling twice should be a no-op (check `isReady`).
- **Throws `LlmLoadException`** if the model can't be opened. The dispatcher will catch this, mark the AI layer as offline for the session, and the rest of Halo keeps working.

### `generate(LlmRequest)`

The hot path. Take the structured input, run inference, return a `Verdict`.

- Must complete in reasonable time. >30s and the user will think it's broken.
- Must produce a `Verdict` whose `direction` matches the input setup direction. Don't override the engine's call.
- If the model produces malformed JSON or a hallucinated field, throw `LlmGenerationException`. Don't silently return garbage.

### `dispose()`

Free weights, close file handles, kill any helper processes. Called on app shutdown.

---

## Input schema (`LlmRequest`)

This is what `generate()` receives. Defined in `lib/ai/local_llm/llm_request.dart`.

```jsonc
{
  "symbol": "AAPL",
  "timeframe": "5m",
  "assetProfile": "us_equities",      // "crypto" | "us_equities" | "forex"
  "currentPrice": 259.38,
  "atr": 0.2895,                       // 14-period ATR

  "setup": {
    "direction": "bearish",            // "bullish" | "bearish"
    "score": 4.5,                      // confluence score from the engine
    "zoneLower": 259.40,               // FVG zone bounds
    "zoneUpper": 259.56,
    "priceApproaching": true,          // price within 1.5×ATR of zone
    "flags": ["chopZone"]              // calibration flags — see below
  },

  "events": [
    {
      "type": "bearishFvg",            // see PatternType enum
      "direction": "bearish",
      "priceLevel": 259.48,
      "ageCandles": 0
    },
    {
      "type": "liquiditySweepBearish",
      "direction": "bearish",
      "priceLevel": 261.81,
      "ageCandles": 27
    },
    {
      "type": "bearishBos",
      "direction": "bearish",
      "priceLevel": 259.56,
      "ageCandles": 1
    }
  ],

  "recentCandles": [
    { "t": "2026-04-10T17:10:00Z", "o": 259.58, "h": 259.71, "l": 259.56, "c": 259.61, "v": 6656 },
    // … up to 20 candles, oldest first …
  ],

  "fingerprint": "a8f3e91c2b7d4e60"   // opaque dedup key — don't recompute
}
```

### `setup.flags`

Calibration flags from the engine. The LLM should use these to discount confidence:

| Flag | Meaning | Suggested confidence delta |
|---|---|---|
| `chopZone` | Opposing BOS ≥ aligned BOS near zone — congestion, not clean structure | -2 |
| `sameBarSweep` | Sweep formed on the same candle as the FVG (one event, not two) | -1 |
| `fastFill` | FVG already 50–95% consumed — imbalance had no holding power | -1 |
| `counterTrend` | Setup direction opposes recent BOS trend | -1 |

Apply these in your prompt template or post-processing logic. They're not optional — the engine has already proved across calibration that they predict failure modes.

### `events[].type`

Possible values (mirror of `PatternType` enum in `confluence.dart`):

```
bullishFvg              bearishFvg
liquiditySweepBullish   liquiditySweepBearish
bullishBos              bearishBos
bullishFvgWithSweep     bearishFvgWithSweep
fullBullishConfluence   fullBearishConfluence
```

---

## Output schema (`Verdict`)

What `generate()` must return. Defined in `lib/ai/verdict.dart`.

```jsonc
{
  "direction": "bearish",              // MUST match setup.direction
  "confidence": 7,                     // integer 1–10

  "entry": {
    "type": "limit",                   // "limit" | "market" | "stop"
    "price": 259.50,
    "zone": [259.40, 259.56]           // [lower, upper]
  },

  "invalidation": 259.70,              // stop-loss level
  "target": 258.80,                    // first realistic profit target

  "thesis": "Price rejected a fresh bearish FVG with a same-bar sweep ...",
  "keyRisks": [
    "thin volume into close",
    "opposing bullish BOS 18 candles back"
  ],

  "generatedAt": "2026-04-10T17:31:02Z",
  "modelId": "llama-3.2-3b-q4",
  "cached": false                      // set false from your impl; the cache layer flips it
}
```

### Hard rules the implementation MUST enforce

1. **`direction` matches the setup.** The engine has already decided bullish/bearish. Don't argue.
2. **Confidence is 1..10 integer**, clamped.
3. **`entry.price` lies inside `[zoneLower, zoneUpper]`.** No entries outside the zone.
4. **`invalidation` is on the wrong side of the zone**: above zoneUpper for bearish, below zoneLower for bullish.
5. **`target` is in the trade direction** from `currentPrice`: lower for bearish, higher for bullish.
6. **`thesis` is ≤400 chars and is plain prose** (no markdown, no bullet points).
7. **`keyRisks` has 0–3 entries**, each specific to *this* setup. Generic risks are not allowed.

Halo doesn't validate these at runtime today — your implementation owns correctness. If you ship garbage, the sidebar will display garbage.

---

## Confidence calibration (recommended)

This is what the `EchoLlm` stub does. A real model can do better, but this is the floor:

```
confidence = floor(score)
if 'chopZone' in flags:        confidence -= 2
if 'sameBarSweep' in flags:    confidence -= 1
if 'fastFill' in flags:        confidence -= 1
if 'counterTrend' in flags:    confidence -= 1
if score >= 4.5 and flags == []: confidence += 1
confidence = clamp(confidence, 1, 10)
```

Confidence semantics:
- **1–4**: don't trade
- **5–6**: marginal; user should look closer
- **7–8**: clean setup; the notification system fires at >= 7
- **9–10**: reserved for god-tier confluence — be stingy

---

## Wiring it in

Once you've implemented `MyLlmImpl extends LocalLlm`:

```dart
// lib/main.dart
import 'package:frontend/ai/ai_providers.dart';
import 'package:frontend/ai/local_llm/local_llm.dart';
import 'package:my_pkg/my_llm_impl.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        localLlmProvider.overrideWithValue(MyLlmImpl(modelPath: 'models/llama-3.2-3b.gguf')),
      ],
      child: const HaloApp(),
    ),
  );
}
```

That's it. The dispatcher picks up your impl through the provider, the rest works.

---

## Threading and performance

`generate()` runs on the **main isolate by default**. If your model is slow:

- **<200ms per call**: fine on the main isolate.
- **>200ms per call**: spawn a `Isolate` inside `generate()` and await its completion. The interface is already `Future`-returning; the dispatcher doesn't care where the work runs.

The dispatcher already protects you from runaway calls:
- One in-flight request per setup fingerprint (no parallel duplicate work).
- Cooldown between dispatches per fingerprint (`dispatchCooldown`, default 2 minutes).
- 30-minute dedup cache (`dedupTtl`).

So you'll get at most one `generate()` call per unique setup per ~30 minutes, even if the engine fires the same setup every candle.

---

## Packaging the model

Halo's whole point of going local is privacy and offline operation. **Do not make network calls from inside `LocalLlm`.** Bundle the model file as a Flutter asset.

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/models/your-model.gguf
```

Read it via `rootBundle.load('assets/models/your-model.gguf')` inside `load()`. Or, for very large models, prompt the user to download once and cache to `getApplicationSupportDirectory()`.

---

## Testing

The stub `EchoLlm` is the reference test target. See `test/echo_llm_test.dart` for the expected shape — copy that file when writing tests for your impl.

Minimum coverage:
- `load()` is idempotent
- `generate()` returns a verdict whose direction matches the input
- Flags reduce confidence as documented
- Entry/invalidation/target are on the correct side of the zone

---

## Failure modes the dispatcher already handles

You don't need to retry, log, or special-case anything. Just throw:

| You throw | Dispatcher does |
|---|---|
| `LlmLoadException` | Returns `VerdictFailed("model failed to load: ...")`. AI layer offline for the session. |
| `LlmGenerationException` | Returns `VerdictFailed("generation failed: ...")`. Sidebar shows "AI failed" card; user can retry. |
| Any other `Exception` | Wrapped as `VerdictFailed("generation error: $e")`. Same UI behavior. |

---

## What gets shown to the user

- **Sidebar card**: full verdict (direction, confidence chip, entry/invalidation/target row, thesis, expandable risks). Persists across restarts via SQLite.
- **OS notification**: fired when `confidence >= 7` AND `setup.priceApproaching == true`. Single line: "▼ AAPL 5m — bearish setup, confidence 7. Click to open."

Confidence threshold is configurable per-user later. For now: 7+ is the bar.

---

## Files at a glance

| File | What it does |
|---|---|
| `lib/ai/local_llm/local_llm.dart` | The abstract interface (3 methods) |
| `lib/ai/local_llm/llm_request.dart` | Input schema |
| `lib/ai/local_llm/echo_llm.dart` | Stub impl — read this for a working example |
| `lib/ai/verdict.dart` | Output schema |
| `lib/ai/local_reasoning_service.dart` | Caching + dedup wrapper around your impl |
| `lib/ai/verdict_dispatcher.dart` | Engine output → reasoning → notification + sidebar |
| `lib/ai/insight_repository.dart` | SQLite persistence |
| `lib/ai/ai_providers.dart` | Riverpod wiring (override `localLlmProvider` here) |
