# Detection & Scoring System — How It Works

## The Big Picture

Every time a new candle closes, the engine scans for three types of market events:
- **Fair Value Gaps (FVG)** — price inefficiencies left behind by aggressive moves
- **Liquidity Sweeps** — stop hunts where price pierced a key level then reversed
- **Break of Structure (BOS)** — price closes beyond the most recent swing high or low

When multiple events cluster around the same price zone, they get scored together as a **setup**. Only setups that cross the minimum score threshold get surfaced.

---

## The Three Detectors

### 1. Fair Value Gap (FVG)
A gap is formed by three consecutive candles where the middle candle moves so aggressively that it leaves a price "hole" between candle 1's high and candle 3's low (bullish), or candle 3's high and candle 1's low (bearish).

```
Bullish FVG:              Bearish FVG:
   C1    C2    C3            C1    C2    C3
         ████                      ████
   ▐██▌  ████  ▐██▌    ▐██▌  ████  ▐██▌
         ████          ▓▓▓▓▓▓▓▓▓▓▓  ← gap (unfilled)
   ▓▓▓▓▓▓▓▓▓▓▓           ████
         ↑ gap            ████
```

**What triggers it:** Gap size must exceed 10% of ATR (filters noise). The middle candle must be directional (bullish body for bullish FVG, bearish body for bearish FVG).

**Lifecycle:**
- `active` — gap exists, price hasn't returned to it
- `partial` — price has entered the gap but not closed it
- `filled` — price traded through the entire gap (event is discarded)

**Base score: 1.5 points**
**Bonus +0.5:** If the displacement candle is larger than 1.5× ATR (unusually strong move)

---

### 2. Liquidity Sweep
Retail traders place stops just above swing highs and below swing lows. Institutions know this. A sweep is when price briefly pierces through a cluster of equal highs/lows (triggering those stops), then reverses back — trapping the breakout traders.

**Step 1 — Find clusters:**
Swing highs or lows that are within 0.15× ATR of each other are grouped into a liquidity cluster. Minimum 2 swing points to form a cluster.

```
Equal highs cluster (bearish):     Equal lows cluster (bullish):
  ─ ─ ─ ─ ─ ─ ─ ─ ─                      ●   ●
       ●       ●                  ─ ─ ─ ─ ─ ─ ─ ─ ─
  stop orders sitting above        stop orders sitting below
```

**Step 2 — Detect the sweep:**
A candle whose wick pierces beyond the cluster but whose close reverses back inside — AND the reversal is at least 0.2× ATR. This is the "trap and reverse."

**Base score: 2.0 points** (highest single signal — sweeps have strong directional conviction)
**Bonus +0.5:** If the penetration depth exceeds 0.3× ATR (deep sweeps are more convincing)

---

### 3. Break of Structure (BOS)
A candle closes beyond the most recent confirmed swing high (bullish BOS) or swing low (bearish BOS). This signals that the prior structure has broken and momentum is accelerating.

**What triggers it:** Close must exceed the swing level by at least 0.05× ATR. This filters out micro-wicks that barely tag the level.

**Note:** BOS on its own is a lower-conviction signal — it's most powerful when combined with an FVG or sweep in the same zone.

**Base score: 1.5 points**

---

## Scoring & Confluence

### How Points Stack

When multiple signals fire within the same price zone (within 1× ATR of each other), their scores combine:

| Signals in Zone | Score | Interpretation |
|----------------|-------|----------------|
| FVG alone | 1.5 | Weak — watch only |
| BOS alone | 1.5 | Weak — watch only |
| Sweep alone | 2.0 | Moderate — pay attention |
| FVG + BOS | 3.0 | Good setup |
| Sweep + FVG | 4.0 | Strong — alert candidate |
| Sweep + BOS | 3.5 | Strong — alert candidate |
| Sweep + FVG + BOS | 5.5+ | Full confluence — AI trigger |

### Minimum Threshold
Default minimum score to surface a setup: **2.0 points**

Anything below 2.0 is discarded silently.

### When Does AI Get Called?
The AI reasoning layer (Claude) only gets called on setups that are:
1. Score ≥ threshold (configurable, suggest starting at 3.5 for AI)
2. `priceApproaching = true` — current price is within 1.5× ATR of the zone

This keeps AI costs low. Cheap algo detection runs on every candle. Expensive AI reasoning only fires when a real setup is forming AND price is in the neighborhood.

---

## What "Price Approaching" Means

Each setup has a zone (upper and lower price bound). If the current candle's close is within 1.5× ATR of the zone's midpoint, `priceApproaching` is set to true.

This is the gating condition for sending a setup to the AI. A 5-point confluence setup from 3 days ago that price has moved far away from is not actionable — so it doesn't get an AI call.

---

## Deduplication

The engine tracks every event it has already emitted using a key made of `type:direction:timestamp`. This prevents the same FVG or BOS from firing again on the next candle. Each pattern is reported exactly once.

---

## Full Scoring Example

Say you're watching AAPL on a 5-minute chart. ATR = $0.50.

1. Three candles form a **bullish FVG** at $185.20–$185.45. Gap size = $0.25 (50% of ATR ✓). Displacement candle body = $0.85 (1.7× ATR → bonus). **Score: 2.0**

2. Two previous swing lows at $185.18 and $185.22 form a **liquidity cluster** at ~$185.20. The very next candle wicks down to $185.10, then closes at $185.35. Wick pierce = $0.10, reversal = $0.25 (50% of ATR → qualifies). **Score: 2.0**

3. The FVG and sweep are both centered around $185.20, within 1× ATR of each other → they **combine into one setup**. Total score: **4.0**

4. Current price ($185.30) is within 1.5× ATR ($0.75) of zone midpoint ($185.32) → `priceApproaching = true`

5. Score 4.0 ≥ AI threshold 3.5, price approaching → **AI reasoning triggered.**

---

## Tuning Knobs

All thresholds are configurable when creating `DetectionEngine`:

| Parameter | Default | What It Controls |
|-----------|---------|-----------------|
| `minConfluenceScore` | 2.0 | Minimum score to surface a setup |
| `fvgMinAtrMultiple` | 0.1 | Minimum FVG gap size (× ATR) |
| `swingLookback` | 3 | Candles left+right to confirm a swing point |
| `bufferSize` | 200 | How many candles to hold in memory |

For a more sensitive detector (more alerts, more noise): lower `minConfluenceScore` to 1.5.
For a stricter detector (fewer, higher-quality alerts): raise to 3.0+.
