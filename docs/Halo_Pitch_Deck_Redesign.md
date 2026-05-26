# Halo Pitch Deck — Redesign Brief

This translates the existing 10‑slide pitch deck (`docs/Halo_Pitch_Deck.pdf`) into the Halo design system defined in `frontend/design.md`. Source of truth for all tokens: `frontend/lib/themes/halo_theme.dart`.

---

## 0. Direction: Commit to **Terminal**

The current deck already leans terminal — geometric/monospace fragments (`— 01  /  THE PROBLEM`, `1GB MODEL • LLAMA.CPP`, `FLUTTER • DART • RIVERPOD`), mint accent on near‑black, "browser window" frames. Pushing the rest of the deck into the Terminal language is the smallest move with the biggest coherence gain. Audience fit: traders/quants, VCs in fintech.

> **Alternative:** If the deck is going to a generalist VC audience, Meridian (Space Grotesk + DM Sans + Fira Code, blue `#3B82F6`) is the more "polished" read. Pick one; do not mix.

The brief below assumes **Terminal**. If you swap to Meridian, replace every JetBrains Mono with Space Grotesk for headlines / DM Sans for body / Fira Code for numerics, and `#00D97A` with `#3B82F6`.

---

## 1. Global Tokens

### 1.1 Color (Terminal)

| Role | Token | Hex |
|---|---|---|
| Page background | `theme.backgroundColor` | `#030D07` |
| Card surface | `theme.primaryColor` | `#09261A` |
| Hairline / borders | `theme.whiteColor` @ 6–20% | `#F4E9D8` (tinted) |
| Body text | `textSecondary` | `#64748B` |
| Headline text | `textPrimary` | `#E2E8F0` |
| Eyebrow / metadata | `textMuted` | `#334155` |
| Accent (live, active) | `textAccent` | `#00D97A` |
| Bearish / warning | direct hex (matches `NotificationWidget`) | `#EF4444` |
| Bullish / target | direct hex | `#22C55E` |

> The current deck mint (≈`#5EE7C4`) is not a system color. Replace **all** mint pixels with `#00D97A` for active/accent and `theme.textPrimary` (`#E2E8F0`) for "non‑accent white".

### 1.2 Type stack (Terminal)

| Role | Use for | Font / Size / Weight / Tracking |
|---|---|---|
| Headline (slide title) | "6 windows. Zero synthesis." | JetBrains Mono **44–48 / 500 / 0** |
| Sub‑headline | The line under the title | IBM Plex Sans **18 / 400 / 0**, color `textSecondary` |
| Eyebrow | `— 01  /  THE PROBLEM` | JetBrains Mono **12 / 400 / +1.5** UPPERCASE, color `textAccent` for the dash + number, `textMuted` for the slash and label |
| Card title | "Fair Value Gaps", "Privacy" | IBM Plex Sans **20 / 600 / +0.5**, color `textPrimary` |
| Card body | The card description | IBM Plex Sans **14 / 400 / 0**, color `textSecondary`, height 1.4 |
| Tag chip | `FVG` `LSP` `BOS` | JetBrains Mono **11 / 500 / +1.5** UPPERCASE, color `textAccent` |
| Numeric / data | `67,420`, `8/10`, `01 / 10` | JetBrains Mono **18–32 / 500 / 0**, tabular figures |
| Footer wordmark | `HALO` | JetBrains Mono **11 / 400 / +2.0** UPPERCASE, color `textMuted` |
| Pull‑quote / kicker | "None of these talk to each other." | IBM Plex Sans **15 / 500 / 0**, color `#EF4444` (warning) — **not italic** |
| Affirming kicker | "No interpretation required. …" | IBM Plex Sans **15 / 500 / 0**, color `textAccent` — **not italic** |

> **Drop italics everywhere.** They're not in the design system (no theme defines an italic style). Use weight (500) + color to create emphasis.

### 1.3 Surfaces

Every card/surface follows the BodyPage glass recipe, frozen as a static raster (Keynote can't do BackdropFilter):

```
Fill:        primaryColor 55% (#09261A @ 0.55) over near-black bg
Border:      whiteColor 10% inner, 0.5px
Radius:      10px
Shadow:      none on regular cards; cards-with-glow get accent 30% / blur 28 / spread 2
```

For the **highlighted column / featured card** (Halo column on slide 07, "active step" pattern):
```
Border:      textAccent 45% (#00D97A @ 0.45), 1.5px
Background:  textAccent 7% (#00D97A @ 0.07)
Glow:        textAccent 35% blur 24 spread 2 (drop shadow in Keynote)
```

### 1.4 Background

Replace flat `#0A0F1F` with a **theme background plate**:
- Linear gradient `#0A2818 → #071A10` topLeft → bottomRight (Terminal `backgroundGradient`)
- Optional: layer a low‑opacity radial blob asset (export a 1920×1080 PNG of `BackgroundGradientAnimation` paused at frame 0 from the app, placed at 25% opacity)
- Terminal's `glassOverlay` darkens it back to near‑black, so the gradient should read *barely visible* — like the current near‑flat dark, just with green warmth

### 1.5 Footer (every slide except 01 and 10)

Single 1px hairline `whiteColor 10%`. Below it, baseline‑aligned:
- Left: `HALO` — JetBrains Mono 11 / +2.0 / `textMuted`
- Right: `02 / 10` — JetBrains Mono 11 / 0 / `textMuted` with `tabular-nums`
- 24px outer margin

### 1.6 Eyebrow pattern (every content slide)

```
— 01  /  THE PROBLEM
```
- The em‑dash + number (`— 01`) in `textAccent` (`#00D97A`)
- The slash + label (`/ THE PROBLEM`) in `textMuted`
- Spacing between number and slash: 2 spaces; between slash and label: 2 spaces
- Letter‑spacing on the label: +1.5

---

## 2. Slide‑by‑slide

### Slide 01 — Title

**Current:** Geometric sans "HALO" wordmark; mint "Detect. Reason. Act."; white tagline; italic muted sub‑tagline; concentric ring icon top‑right.

**Target:**
- **Wordmark "HALO":** JetBrains Mono 180 / 500 / +12 (very wide), `textPrimary` (`#E2E8F0`). Position center‑left, baseline at vertical center. Keep the heavy letter‑spacing — it's the only place we go this wide; reads as terminal output.
- **"Detect. Reason. Act.":** JetBrains Mono 28 / 500 / +1.0, `textAccent` (`#00D97A`). Same baseline grid as the current layout.
- **Tagline:** IBM Plex Sans 22 / 400, `textPrimary` @ 90%. "The AI trading desk that runs on your machine."
- **Sub‑tagline:** IBM Plex Sans 14 / 400, `textMuted` (`#334155` won't read on dark — bump to `textSecondary` `#64748B`). **Drop italics.** "Real‑time pattern detection · on‑device LLM verdicts · Crypto, US equities, forex." (use middle dots `·`, not em dashes)
- **Top‑right icon:** Replace the concentric ring with `FontAwesomeIcons.crosshairs` at 64px, color `textAccent`. Pull from the same icon library the app uses (ties deck to product).
- **Background:** Terminal gradient plate (see 1.4).
- **Footer:** Render footer here too — `HALO` / `01 / 10`. Currently rendered, keep it; just retype with the new tokens.

### Slide 02 — The Problem

**Current:** Eyebrow "— 01 / THE PROBLEM"; "6 windows. Zero synthesis."; 5 browser‑frame cards (TradingView/Webull/Reddit‑X/News/Scanner); red italic kicker; 3 bullets.

**Target:**
- **Eyebrow:** Apply Terminal eyebrow pattern (1.6).
- **Headline:** JetBrains Mono 48 / 500 / 0, `textPrimary`. Tighten to one line if it fits ("6 windows. Zero synthesis.").
- **5 "browser window" cards:** Replace the macOS traffic‑light frame stylization with Halo's actual `WindowTab` chrome (it's the same idea but on‑brand):
  - Card 240×100, radius 5
  - Top edge: 3 traffic‑light dots in **`CommandButtons` colors** — grey idle (`#9CA3AF`); but since these are static, render them dimmed grey `whiteColor 35%` (no hover)
  - Inside: 17×17 logo placeholder + **monospace symbol** (`TRADINGVIEW`, `WEBULL`, `REDDIT/X`, `NEWS`, `SCANNER`) in `theme.ticker` style
  - Below symbol: "Charts" / "Execution" / "Sentiment" / "Headlines" / "Screening" in `labelSmall` UPPERCASE, `textMuted`
  - Border `whiteColor 10%`, fill `primaryColor 55%`
- **Kicker:** "None of these talk to each other." — IBM Plex Sans 16 / 500, color `#EF4444` (matches NotificationWidget bearish). **No italics.**
- **Bullet list:** Replace `•` with a 3px circle in `textAccent @ 70%` (matches `_RiskList` in NotificationWidget). Body text in IBM Plex Sans 15 / 400, `textSecondary`. 8px gap between bullets.
- **Footer:** standard.

### Slide 03 — The Solution

**Current:** Three colored cards: 01 DETECT (mint), 02 REASON (purple), 03 ACT (green). Each has a colored top‑bar.

**Target:**
- **Eyebrow + headline:** standard pattern.
- **Three cards:** Drop the per‑step color rotation (purple is off‑system). Use the **same accent (`#00D97A`)** for all three — they're all "active" because Halo does all three. The current visual differentiation can be done by content, not color.
  - Card 280×280, fill `primaryColor 55%`, border `whiteColor 10%`, radius 10
  - Top‑bar inside the card: 3px tall, full‑width, `textAccent` (`#00D97A`)
  - Step number: JetBrains Mono 12 / 400 / +1.5, `textAccent` — render as `01`, `02`, `03`
  - Step word ("DETECT", "REASON", "ACT"): JetBrains Mono 36 / 500 / 0, `textPrimary`
  - Body: IBM Plex Sans 14 / 400, `textSecondary`, height 1.4
- **Connector:** Optional — between the three cards draw a hairline track + small `▶` glyph in `textAccent` between each, to imply the pipeline (Detect → Reason → Act).
- **Tagline:** "No interpretation required. No window‑switching. No cloud bill." — IBM Plex Sans 15 / 500, `textAccent`, **not italic**, centered above footer.

### Slide 04 — Detection Engine

**Current:** Three cards with cyan‑bordered tag chips (FVG / LSP / BOS) + headline + body.

**Target:** Already very close to spec. Adjustments:
- Tag chips: `FVG`, `LSP`, `BOS` — JetBrains Mono 11 / 500 / +1.5 UPPERCASE, color `textAccent`, in a pill: 8×4 padding, radius 4, fill `textAccent 12%`, border `textAccent 45%`. (Mirrors the `_DirectionPill` from NotificationWidget.)
- Card title: "Fair Value Gaps" — IBM Plex Sans 20 / 600, `textPrimary`.
- Card body: IBM Plex Sans 14 / 400, `textSecondary`, height 1.4.
- Sub‑headline: "ICT / Smart Money Concepts — millions of retail followers, zero dedicated tooling." — IBM Plex Sans 16 / 400, `textSecondary`, **not italic**.
- Bottom kicker: "Deduplication, fingerprint caching, level validation — clean signals, never spam." — `textAccent`, IBM Plex Sans 14 / 500, **not italic**, centered above footer.

### Slide 05 — AI Verdict Layer

**This slide should mirror `NotificationWidget.dart` precisely** — it's marketing the actual product UI.

**Target verdict mockup (left column):**
- Card: radius 14, double border (`whiteColor 60%` inner 0.5px, `whiteColor 20%` outer 0.5px), shadow stack (black 45% blur 28 +12y; `accentColor` glow 30% blur 28 spread 2; `#22C55E` glow 10% blur 32 — bullish slide)
- **Header strip** with bottom hairline `whiteColor 6%`:
  - Direction pill: `▲ BULLISH` — `arrowTrendUp` icon 11px + label JBM 10 / 600 / +1.6, color `#22C55E` (bullish green)
  - Pill fill: `#22C55E 14%`, border `#22C55E 55%`, radius 999, padding 10×6
  - Right side: a CACHED meta‑pill if showing the cached state — JBM 10, `textMuted`, fill `whiteColor 5%`, border `whiteColor 8%`
- **Confidence row:**
  - "8" in JBM 18 / 500, `#22C55E`, tabular‑nums
  - "/10" in JBM 12, `whiteColor 40%`
  - 10‑segment progress bar: each segment height 6, radius 3, gap 4; first 8 filled `#22C55E 85%`, last 2 `whiteColor 40%`
- **Price grid** (3 stacked rows, fill `whiteColor 2.5%`, hairlines `whiteColor 6%`, outer radius 10):
  - Row 1: `crosshairs` icon 12px in 28×28 tile (`accent 12%` fill) + label `ENTRY` (`labelSmall`) + sub‑pill `LIMIT` + price `67,420` (JBM 18 / 500, tabular)
  - Row 2: `shieldHalved` + `INVALIDATION` + price `66,890`, accent `#EF4444`
  - Row 3: `flagCheckered` + `TARGET` + price `68,950`, accent `#22C55E`
- **THESIS section:** label `THESIS` (`labelSmall`) + body in `bodyMedium` (IBM Plex Sans 13 / 400 / height 1.5) `textPrimary`. Sample text: "Bullish FVG retest at 67.4k confluences with H4 BOS. Momentum confirms via displaced candle close."
- **KEY RISKS:** label + bulleted list with 5px circle bullets in `accent 70%`. Sample: "CPI print in 90 min; wick into 66.7k invalidates structure."
- **Footer:** `microchip` icon 10px + `LLAMA-3.2-3B-Q4` (JBM 11, `textMuted`) + 3px circle separator + `12m ago · 14:32` (JBM 11, tabular, `textMuted`)

**Right column (the bullets):**
- "EVERY VERDICT SHIPS WITH" eyebrow (`labelLarge` UPPERCASE +1.5, `textAccent`)
- Bullet items in IBM Plex Sans 16 / 400, `textPrimary`, with the same 3px circle bullets as elsewhere
- Bottom callout block (the "1GB MODEL · LLAMA.CPP · ZERO CLOUD" pill): JBM 11 / 500 / +1.5 UPPERCASE, `textAccent`, separated by ` · ` middle dots, in a pill with `textAccent 8%` fill and `textAccent 35%` border. Sub‑line "Runs entirely on‑device, no API bill." in IBM Plex Sans 13 / 400 / **no italic**, `textSecondary`.

### Slide 06 — Why Local

**Current:** 2×2 card grid (Privacy / Zero Cost / Low Latency / Resilient).

**Target:**
- Each card: 460×180, fill `primaryColor 55%`, border `whiteColor 10%`, radius 10, padding 24
- **Eyebrow inside card:** `PRIVACY` / `ZERO COST` / `LOW LATENCY` / `RESILIENT` — JBM 11 / 400 / +1.5 UPPERCASE, `textAccent`
- **Hero stat** (the bold short line, "Nothing leaves the device.", "No API bill, ever.", "Tens of milliseconds.", "Works offline."): IBM Plex Sans 22 / 600 / 0, `textPrimary`
- **Body:** IBM Plex Sans 14 / 400, `textSecondary`, height 1.4
- **Bottom tagline strip:** "Cloud‑AI vendors charge $20–80/month. And read everything you trade." — IBM Plex Sans 14 / 400, `textMuted`, **not italic**, centered above footer

> Optional polish: on the "LOW LATENCY" card, render the stat as a `tickerLarge`-style accented number — `<10ms` in JetBrains Mono 32 / 500, `textAccent`, with "tens of milliseconds" as supporting body below. Pulls Halo's data‑first identity into the slide.

### Slide 07 — Vs The Field

**Current:** Comparison table, Halo column highlighted with mint border.

**Target:**
- Headline: keep "Charts ≠ analysis. Execution ≠ edge." — JBM 48 / 500. The `≠` glyph reads like terminal output, leans into the theme.
- Table:
  - Column headers: `TRADINGVIEW`, `WEBULL`, `HALO` — JBM 12 / 500 / +1.5 UPPERCASE
    - First two columns: `textMuted`
    - Halo column header: `textAccent` (`#00D97A`)
  - Row labels: IBM Plex Sans 15 / 400, `textPrimary`
  - Cells: replace icon set with a single tight set:
    - `✓` → FontAwesome `check`, 13px, `#22C55E` (positive)
    - `✗` → FontAwesome `xmark`, 13px, `#EF4444` (negative)
    - `—` → 10px hairline, `textMuted`, centered
  - Halo column: full‑height pill border `textAccent 45%`, fill `textAccent 7%`, radius 10, glow shadow `textAccent 35% blur 24 spread 2`
  - Row hairlines: `whiteColor 6%`, 1px
- Tagline: "The only tool that detects, reasons, and acts — locally." — `textAccent`, IBM Plex Sans 15 / 500, **not italic**

### Slide 08 — Traction

**Current:** 2×2 card grid + tech stack footer ("FLUTTER · DART · RIVERPOD · LLAMA.CPP · SQLITE · WEBSOCKET").

**Target:**
- **Sub‑headline:** "This is shipping software, not a deck." — IBM Plex Sans 18 / 500, `textSecondary`, **not italic**
- **Cards** (same 2×2 grid as slide 06): each card has the green status dot already — keep it, but render as 8×8 circle in `textAccent`, with an outer 12×12 ring at `textAccent 30%` (matches the live‑status pattern from `WindowTab`'s eye/notif badge area)
- **Card eyebrow:** `DESKTOP APP LIVE`, `DATA FEEDS WIRED`, `AI VERDICT LAYER`, `EXECUTION AUTH` — JBM 11 / 400 / +1.5 UPPERCASE, `textAccent`
- **Card title:** "macOS + Windows", "3 asset classes", etc. — IBM Plex Sans 22 / 600, `textPrimary`
- **Card body:** IBM Plex Sans 13 / 400, `textSecondary`, height 1.4
- **Tech stack footer:** Above the slide footer hairline, render as a centered row of monospace pills — `FLUTTER`, `DART`, `RIVERPOD`, `LLAMA.CPP`, `SQLITE`, `WEBSOCKET`, separated by ` · ` middle dots. JBM 11 / 400 / +2.0 UPPERCASE, `textAccent` with 60% opacity. (Drop ALL CAPS rendering on the hairline — let letter‑spacing do the work.)

### Slide 09 — What's Next

**Current:** 5 numbered items with circular badges.

**Target:**
- **Headline:** "From single setup to autonomous desk." — JBM 44 / 500
- **List:** vertical stack, 16px gap between rows
- **Number badge:** 36×36 circle, border `textAccent 50%`, fill `textAccent 8%`, with the number `01`–`05` inside in JBM 12 / 500, `textAccent`. (Mirrors the `_DirectionPill` style from NotificationWidget.)
- **Item title:** "Auto‑screening" — IBM Plex Sans 18 / 600, `textPrimary`
- **Item body:** "Continuous market scan across watchlists." — IBM Plex Sans 14 / 400, `textSecondary`
- Optional: horizontal hairline `whiteColor 6%` between rows

### Slide 10 — Closing

**Current:** Concentric ring icon, "Detect. Reason. Act.", closing line.

**Target:**
- **Hero icon:** Same `crosshairs` glyph as slide 01 (or keep the concentric rings but redraw in `textAccent` `#00D97A`, with the inner dot at `#22C55E` for "live"). 96px.
- **"Detect.  Reason.  Act.":** JBM 36 / 500 / +1.0, `textAccent`. (Same as slide 01 but slightly larger.)
- **Close line:** "Help us build the AI trading desk that doesn't rent your data." — IBM Plex Sans 18 / 400, `textPrimary` @ 90%
- **Optional:** Below the close line, render a "contact" pill: JBM 11 / 500 / +1.5 UPPERCASE, `textAccent`, in `textAccent 8%` fill / `textAccent 35%` border pill — `you@halo.app · halo.app/investors`. Treat it like the model‑info pill on slide 05.
- **Footer:** standard.

---

## 3. Asset Production (the parts I can produce as files)

If you'd like, I can render the following as PNGs you can import into Keynote as picture fills:

1. **Background plate** — 1920×1080 PNG of the Terminal `BackgroundGradientAnimation` paused, ready to use as a slide master fill.
2. **Verdict mockup (slide 05)** — 1:1 raster of `NotificationWidget` from the running app with the sample bullish BTC/USD verdict, transparent background, drop‑shadow baked in.
3. **Crosshairs hero icon** — 256px transparent PNG in `textAccent`.
4. **5‑card "browser window" set (slide 02)** — pre‑laid PNG row of the new Halo‑styled symbol cards.

Generating these requires running the Flutter app once, taking screenshots of the relevant widgets, and trimming. Say the word and I'll produce the asset bundle in `docs/deck_assets/`.

---

## 4. Quick fixes to do first (smallest cost, biggest visual lift)

If a full slide‑by‑slide pass is too much, the following four changes alone get you ~70% of the way there:

1. **Replace mint `#5EE7C4` with `#00D97A` everywhere.** Single global color swap.
2. **Drop every italic.** Replace italic styling with weight 500 + color (warning red `#EF4444`, accent `#00D97A`, or muted `textSecondary`).
3. **Retype the wordmark + eyebrows in JetBrains Mono.** Most slides already use a near‑monospace eyebrow; just commit.
4. **Remove the purple step on slide 03.** Recolor all three step cards in accent green; the differentiation comes from the words DETECT/REASON/ACT, not from a color rotation.

After those four, slide 05 (the verdict mockup) is the only slide that genuinely needs a redesign pass — it should look exactly like the in‑app `NotificationWidget` to sell the product.
