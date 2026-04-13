# Changes — `data-processing-engine` branch

This branch introduces the **Detection Engine**: a real-time market structure analysis system that runs on top of the existing candle intake pipeline. It detects three types of high-probability price action events and scores them into actionable setups.

---

## New: Detection Engine (`frontend/lib/detection/`)

Seven new files form the detection layer, plus a top-level orchestrator that wires them together.

### `detection_engine.dart` — Top-level orchestrator

The `DetectionEngine` class is the single entry point the rest of the app needs to care about. It integrates with the existing `IntakeService` via two callbacks:

```dart
engine.switchTicker(symbol, timeframe, history, source: source);
engine.onCandle(candle); // → returns List<ScoredSetup>
```

- On `switchTicker`: loads history into the buffer, auto-selects an `AssetProfile` based on `DataSource` (Binance → crypto thresholds, Alpaca → equities thresholds), resets state, and does a full scan of the loaded history so patterns are immediately available.
- On `onCandle`: runs an incremental scan (only checks what could have just formed), deduplicates against already-emitted events, and returns scored setups above the minimum threshold.
- Exposes read-only accessors for UI/debug: `activeFvgs`, `liquidityClusters`, `swingPoints`, `atr`.

---

### `candle_buffer.dart` — Rolling candle buffer

A capped `List<Candle>` (default 200 candles) that also maintains **ATR(14)** incrementally using Wilder's smoothing. All detectors take a `CandleBuffer` as input — no raw list passing.

---

### `fvg.dart` — Fair Value Gap detector

Detects **price imbalances** left by aggressive directional moves.

- A 3-candle pattern: the middle candle moves so hard that a gap opens between candle 1's high and candle 3's low (bullish), or candle 3's high and candle 1's low (bearish).
- Minimum gap size is gated by ATR multiple (`minAtrMultiple`, default 0.1) to ignore noise.
- Tracks lifecycle: `active` → `partial` (price entered but didn't close it) → `filled` (fully closed, discarded).
- `scan()` checks the full buffer; `checkLatest()` only checks the last 3 candles for real-time use.

**Base score: 1.5 pts**

---

### `swing_points.dart` — Swing high/low identifier

Identifies swing highs and lows using a left/right lookback window (`lookback`, default 3). A swing high at index `i` requires candles `[i-3..i-1]` and `[i+1..i+3]` to all have lower highs. Used as input to both the sweep and BOS detectors.

---

### `liquidity_sweep.dart` — Liquidity sweep detector

Detects **stop hunts**: price briefly pierces a cluster of equal highs/lows (trapping breakout traders), then reverses.

Two-step process:
1. **Find clusters**: groups swing highs or swing lows that are within `clusterToleranceAtrMultiple` (0.15× ATR) of each other. Minimum 2 swing points per cluster.
2. **Detect sweeps**: a candle whose wick exceeds the cluster price but whose close reverses back inside, with a minimum reversal of `minReversalAtrMultiple` (0.2× ATR).

Exposes `findClusters()` separately so the UI can render cluster levels without triggering a full sweep scan.

**Base score: 2.0 pts** (highest single-signal score — sweeps carry the most directional conviction)

---

### `bos.dart` — Break of Structure detector

Fires when price **closes beyond** the most recent confirmed swing high (bullish BOS) or swing low (bearish BOS), signalling a structural trend shift.

- Minimum break distance is 0.05× ATR to filter micro-wicks that barely touch the level.
- On its own it's lower conviction; its value is amplified when combined with FVG/sweep in the same zone.

**Base score: 1.5 pts**

---

### `confluence.dart` — Confluence scorer

Groups events that fall within the same price zone (within `zoneToleranceAtrMultiple`, default 1× ATR) and scores them into `ScoredSetup` objects.

**Scoring rules:**

| Pattern | Base score |
|---|---|
| FVG (bullish or bearish) | 1.5 |
| Liquidity sweep | 2.0 |
| Break of structure | 1.5 |
| FVG + sweep combo | 4.0 |
| Full confluence (FVG + sweep + BOS) | 6.0 |

Bonuses applied on top of base:
- `+0.5` if displacement candle is > 1.5× ATR (unusually strong move)
- `+0.5` if sweep penetration depth > 0.3× ATR (deep sweep)
- `+0.5` if setup is recent (within `staleCandles` threshold from `AssetProfile`)
- **Chop penalty**: score multiplied by `chopZoneMultiplier` (< 1.0) if opposing BOS count ≥ aligned BOS count near the zone

Only setups that meet `minScore` (default 2.0) are returned.

---

### `asset_profile.dart` — Per-asset-class tuning

Holds all tuning constants as a single object selected automatically at `switchTicker` time. Three presets:

| | Crypto | Equities | Forex |
|---|---|---|---|
| Chop zone multiplier | 0.65 | 0.75 | 0.75 |
| FVG expiry (candles) | 50 | 30 | 40 |
| Sweep exhaustion count | 4 | 3 | 3 |
| Stale candles threshold | 30 | 20 | 25 |
| Cluster tolerance (ATR×) | 0.15 | 0.10 | 0.12 |

Crypto gets heavier chop penalties because it chops more aggressively than session-based markets.

---

## Modified: Intake Service

**`frontend/lib/engine/stocks/intake_service.dart`**

- `OnCandlesReady` callback signature extended: now includes `DataSource source` as a fourth argument.
- The internal `onTickerSwitch?.call(...)` now passes `_currentResolved!.source` so the detection engine can auto-select the correct `AssetProfile`.

---

## Modified: Client imports

**`alpaca_client.dart`, `binance_client.dart`, `finnhub_client.dart`, `candle_aggregator.dart`, `candle_normalizer.dart`**

Import paths changed from package-absolute (`package:frontend/models/candle.dart`) to relative (`../../models/candle.dart`). Functional no-op — required for the new `bin/` test runner to resolve correctly without the full package context.

---

## New: Tests

| File | What it tests |
|---|---|
| `frontend/bin/detection_test.dart` | Full integration tests for FVG, sweep, BOS, and confluence scoring |
| `frontend/bin/intake_test.dart` | Intake service end-to-end flow |
| `frontend/test/alpaca_client_test.dart` | Alpaca API client |
| `frontend/test/binance_client_test.dart` | Binance API client |
| `frontend/test/candle_aggregator_test.dart` | Candle aggregation logic |
| `frontend/test/candle_normalizer_test.dart` | Candle normalization |
| `frontend/test/finnhub_client_test.dart` | Finnhub API client |
| `frontend/test/ticker_identifier_test.dart` | Ticker identification |
| `frontend/test/ticker_resolver_test.dart` | Ticker resolver |

---

## New: Documentation

- **`DETECTION_SCORING.md`** — developer-facing explainer for the detection and scoring system, including ASCII diagrams of FVG formation and liquidity cluster patterns.
- **`RUNNING_TESTS.md`** — instructions for running the test suite.

---

## New: Calibration Reports (`frontend/reports/`)

17 LLM-assisted calibration reports generated during development:

- **BTC/USDT 5m** — 13 reports (Apr 9–10)
- **SPY 5m** — 6 reports (Apr 10)
- **AAPL 5m** — 6 reports (Apr 10)

These document how detection parameters were tuned against real market data across multiple review sessions. They are reference artifacts, not runtime files.

---

## Commit history (oldest → newest)

| Commit | Summary |
|---|---|
| `2c29c35` | Base detection engine implementation |
| `5419764` | Top-level `DetectionEngine` orchestrator added |
| `acc1216` | Initial fine-tuning pass + asset-specific parameters |
| `5a43b01` | Scoring refinements: linear BOS decay, sliding fill penalty, cluster stability |
| `9bc0115` | FVG expiry, sweep exhaustion decay, zero-volume data quality flag |
| `acc5083` | Chop zone penalty, BOS cap, bearish FVG price-past invalidation |
| `40e5358` | Profile-specific chop zone multiplier (crypto 0.65 vs equities/forex 0.75) |
| `68c1756` | Calibration reports from Sprint 2 LLM review sessions added |
| `a79509e` | Equities calibration round 2: sweep penetration filter, exhaustion fixes |
| `b97b360` | Final equities calibration: SPY/AAPL reports, FVG geometry note |
| `7b090fe` | Merge conflict resolution |
