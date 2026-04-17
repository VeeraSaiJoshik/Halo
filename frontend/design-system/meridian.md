# Meridian — Design System Specification

## Theme Identity

**Name:** Meridian
**Personality:** Clean Swiss — maximum clarity, Swiss grid precision, premium minimal. Built for stock traders who need information hierarchy at a glance, not decoration.
**Design Sources:** Tech Startup typography pattern (Space Grotesk + DM Sans) merged with Dashboard Data pattern (Fira Code for financial numerics).
**Tagline:** Clean Swiss

---

## Font Stack

| Role | Family | Usage |
|------|--------|-------|
| **Geometric Headlines** | Space Grotesk | Display, Headline — hero text, section titles, page headings |
| **Legible UI Text** | DM Sans | Title, Body, Label — navigation, body copy, tags, captions |
| **Financial Data** | Fira Code | Ticker, TickerLarge — prices, symbols, numerical financial data |

All fonts loaded via `google_fonts` package.

---

## Type Scale

All sizes in logical pixels (dp). `letterSpacing` values are in pixels. `height` is the Flutter line-height multiplier (lineHeight = fontSize × height).

### Display — Hero text, welcome screen titles

| Token | Font | Size | Weight | letterSpacing | height | Color |
|-------|------|------|--------|---------------|--------|-------|
| `displayLarge` | Space Grotesk | 52px | 700 | -1.5 | 1.05 | textPrimary |
| `displayMedium` | Space Grotesk | 40px | 700 | -1.0 | 1.10 | textPrimary |

### Headline — Section titles, page headings

| Token | Font | Size | Weight | letterSpacing | height | Color |
|-------|------|------|--------|---------------|--------|-------|
| `headlineLarge` | Space Grotesk | 30px | 600 | -0.5 | 1.15 | textPrimary |
| `headlineMedium` | Space Grotesk | 22px | 600 | -0.3 | 1.20 | textPrimary |

### Title — Prominent labels, button text

| Token | Font | Size | Weight | letterSpacing | height | Color |
|-------|------|------|--------|---------------|--------|-------|
| `titleLarge` | DM Sans | 18px | 600 | 0 | 1.40 | textPrimary |
| `titleMedium` | DM Sans | 15px | 500 | 0 | 1.40 | textPrimary |

### Body — Main and secondary content

| Token | Font | Size | Weight | letterSpacing | height | Color |
|-------|------|------|--------|---------------|--------|-------|
| `bodyLarge` | DM Sans | 16px | 400 | 0 | 1.55 | textSecondary |
| `bodyMedium` | DM Sans | 14px | 400 | 0 | 1.55 | textSecondary |

### Label — Uppercase tags, captions, URL bar, nav items

| Token | Font | Size | Weight | letterSpacing | height | Color |
|-------|------|------|--------|---------------|--------|-------|
| `labelLarge` | DM Sans | 12px | 600 | 0.5 | 1.30 | textMuted |
| `labelSmall` | DM Sans | 11px | 500 | 0.5 | 1.30 | textMuted |

### Ticker — Prices, symbols, financial data (always monospace)

| Token | Font | Size | Weight | letterSpacing | height | Color |
|-------|------|------|--------|---------------|--------|-------|
| `ticker` | Fira Code | 15px | 400 | 0 | 1.30 | textPrimary |
| `tickerLarge` | Fira Code | 18px | 500 | 0 | 1.30 | textAccent |

---

## Color Palette

### Semantic Text Colors

| Token | Hex | ARGB | Usage |
|-------|-----|------|-------|
| `textPrimary` | `#F1F5F9` | `0xFFF1F5F9` | Headlines, primary labels, ticker symbols, any foreground text requiring full attention |
| `textSecondary` | `#94A3B8` | `0xFF94A3B8` | Body copy, supporting descriptions, secondary information |
| `textMuted` | `#475569` | `0xFF475569` | Labels, captions, URL bar, de-emphasized metadata |
| `textAccent` | `#3B82F6` | `0xFF3B82F6` | Highlighted prices (tickerLarge), active states, interactive cues |

### Palette Context

The four text colors map to Slate scale values from a dark-mode palette:
- `textPrimary` → Slate-100 (near-white, readable on dark backgrounds)
- `textSecondary` → Slate-400 (medium grey, secondary hierarchy)
- `textMuted` → Slate-600 (dark grey, subordinate text)
- `textAccent` → Blue-500 (functional blue, financial positive/interactive)

---

## Usage Rules

1. **Headlines always Space Grotesk.** Never use DM Sans or Fira Code for display or headline tokens.
2. **Financial numerics always Fira Code.** Stock symbols, prices, percentage changes, and any number where columnar alignment matters must use `ticker` or `tickerLarge`.
3. **Negative tracking on Space Grotesk only.** The tight letterSpacing values (-0.3 to -1.5) are calibrated for Space Grotesk's wide geometric glyphs. Never apply negative tracking to DM Sans or Fira Code.
4. **Color maps to hierarchy, not emphasis.** Do not change a `bodyMedium` to `textPrimary` for visual emphasis — change the token level instead (e.g., use `titleMedium`).
5. **`textAccent` is functional.** Use it only for `tickerLarge` and interactive/active state indicators. Never use it decoratively.
6. **Consistent leading.** Display/Headline tokens use tight line heights (1.05–1.20) to create a Swiss-grid feel. Body tokens use relaxed leading (1.55) for sustained readability. Do not override `height`.
7. **`labelLarge` and `labelSmall` carry positive letterSpacing (0.5).** This is intentional — labels and captions gain clarity from slight optical expansion at small sizes.

---

## Anti-Patterns

- **Do not** use `TextStyle(...)` inline with hard-coded font families — always consume theme tokens.
- **Do not** use Space Grotesk for body text. Its geometric forms fatigue readers at small sizes over long paragraphs.
- **Do not** apply `textAccent` to static price displays — reserve it for live/changing prices or highlighted values via `tickerLarge`.
- **Do not** mix Fira Code with tracking. Its monospace nature is self-aligning; letterSpacing 0 is intentional.
- **Do not** override `fontWeight` on a token — if the weight is wrong, choose a different token.
- **Do not** use `Colors.white` or `Colors.black` directly in Text widgets — always use semantic color tokens from `HaloThemeData`.
- **Do not** use `displayLarge` or `displayMedium` inside scrollable lists. These are hero/one-per-screen tokens.
- **Do not** set `letterSpacing` to positive values on Space Grotesk — it destroys the tight Swiss-grid aesthetic.
