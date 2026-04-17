# Terminal — Design Specification

## Theme Identity

| Property    | Value                                                       |
| ----------- | ----------------------------------------------------------- |
| Name        | Terminal                                                    |
| Tagline     | Technical Precision                                         |
| Personality | Data-dense, authoritative, developer-grade. Monospace headlines evoke a Bloomberg terminal or raw trading feed. IBM Plex Sans keeps UI prose readable without sacrificing the technical character. Accent green is the canonical "terminal green" — active, live, on. |
| Audience    | Quantitative traders, power users who treat UIs as tools not ornaments. |

---

## Font Stack

| Role       | Typeface        | Source        | Rationale                                                        |
| ---------- | --------------- | ------------- | ---------------------------------------------------------------- |
| Display    | JetBrains Mono  | Google Fonts  | Fixed-pitch glyphs read as live data output; strong at large sizes |
| Headline   | JetBrains Mono  | Google Fonts  | Consistency with display; section headers feel like terminal prompts |
| Ticker     | JetBrains Mono  | Google Fonts  | Prices and symbols must never reflow — monospace is non-negotiable |
| Label      | JetBrains Mono  | Google Fonts  | Uppercase tags and captions inherit terminal character            |
| Title/Body | IBM Plex Sans   | Google Fonts  | Humanist grotesque — readable at small sizes, designed for UI text |

**Fallback chain:** `JetBrains Mono` → `monospace` | `IBM Plex Sans` → `system-ui, sans-serif`

---

## Color Palette

### Semantic Text Colors

| Token          | Hex       | Usage                                         |
| -------------- | --------- | --------------------------------------------- |
| textPrimary    | `#E2E8F0` | Headings, display text, active labels, ticker  |
| textSecondary  | `#64748B` | Body copy, supporting descriptions             |
| textMuted      | `#334155` | Labels, captions, de-emphasized info           |
| textAccent     | `#00D97A` | Terminal green — live price changes, active states, tickerLarge |

### Usage Notes
- Never use `textAccent` for static body text; it signals "live / active / positive".
- `textMuted` at `#334155` is intentionally dark — it recedes against a near-black background without disappearing.
- Do not use pure white (`#FFFFFF`) for any text role; `textPrimary` (`#E2E8F0`) is the lightest allowed.

---

## Type Scale

All sizes are in logical pixels (dp). `height` is the Flutter `TextStyle.height` multiplier (line-height = fontSize × height).

### Display — Hero text, welcome screen titles

| Token         | Font           | Size | Weight | Letter Spacing | Height | Color        |
| ------------- | -------------- | ---- | ------ | -------------- | ------ | ------------ |
| displayLarge  | JetBrains Mono | 48px | 500    | 0              | 1.15   | textPrimary  |
| displayMedium | JetBrains Mono | 36px | 500    | 0              | 1.15   | textPrimary  |

### Headline — Section titles, page headings

| Token         | Font           | Size | Weight | Letter Spacing | Height | Color        |
| ------------- | -------------- | ---- | ------ | -------------- | ------ | ------------ |
| headlineLarge  | JetBrains Mono | 24px | 500    | 0              | 1.2    | textPrimary  |
| headlineMedium | JetBrains Mono | 20px | 400    | 0              | 1.2    | textPrimary  |

### Title — Prominent labels, button text

| Token        | Font         | Size | Weight | Letter Spacing | Height | Color        |
| ------------ | ------------ | ---- | ------ | -------------- | ------ | ------------ |
| titleLarge   | IBM Plex Sans | 16px | 600    | 0.5            | 1.4    | textPrimary  |
| titleMedium  | IBM Plex Sans | 14px | 500    | 0.5            | 1.4    | textPrimary  |

### Body — Main and secondary content

| Token      | Font          | Size | Weight | Letter Spacing | Height | Color          |
| ---------- | ------------- | ---- | ------ | -------------- | ------ | -------------- |
| bodyLarge  | IBM Plex Sans | 15px | 400    | 0              | 1.4    | textSecondary  |
| bodyMedium | IBM Plex Sans | 13px | 400    | 0              | 1.4    | textSecondary  |

### Label — Uppercase tags, captions, URL bar, nav items

| Token      | Font           | Size | Weight | Letter Spacing | Height | Color      |
| ---------- | -------------- | ---- | ------ | -------------- | ------ | ---------- |
| labelLarge | JetBrains Mono | 12px | 400    | 1.5            | 1.2    | textMuted  |
| labelSmall | JetBrains Mono | 10px | 400    | 1.5            | 1.2    | textMuted  |

### Ticker — Prices, numbers, financial data (always monospace)

| Token       | Font           | Size | Weight | Letter Spacing | Height | Color       |
| ----------- | -------------- | ---- | ------ | -------------- | ------ | ----------- |
| ticker      | JetBrains Mono | 14px | 500    | 0              | 1.3    | textPrimary |
| tickerLarge | JetBrains Mono | 18px | 500    | 0              | 1.3    | textAccent  |

---

## Usage Rules

1. **Monospace for numbers, always.** Any price, percentage, volume, or financial figure must use `ticker` or `tickerLarge` — never `bodyLarge`/`bodyMedium`.
2. **`tickerLarge` for live-updating values only.** The accent green implies activity. Static cached values should use `ticker` (textPrimary).
3. **Letter-spacing 1.5 on labels is mandatory.** `labelLarge` and `labelSmall` should be set `UPPERCASE` in the widget — the spacing is calibrated for all-caps rendering.
4. **No weight escalation in body.** `bodyLarge` and `bodyMedium` stay at w400. Use `titleMedium` to create emphasis, not a bolder body.
5. **Titles carry 0.5 letter-spacing.** This slight openness prevents IBM Plex Sans from feeling compressed at 14–16px.
6. **Display and headline use zero letter-spacing.** JetBrains Mono at large sizes needs no additional tracking — the inherent character width provides rhythm.
7. **Stick to the semantic color tokens.** Do not specify raw hex values in widgets; always derive color from the theme's `textPrimary`, `textSecondary`, `textMuted`, or `textAccent`.

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
| --- | --- | --- |
| Using `bodyLarge` for a price | Proportional font causes column misalignment on reflow | Use `ticker` |
| Setting `tickerLarge` (accent green) on static text | Accent implies live/active data; misuse erodes signal value | Use `ticker` for static numbers |
| Adding letter-spacing to `displayLarge` | Monospace at 48px already has strong rhythm; tracking makes it feel mechanical | Keep letterSpacing: 0 |
| Using w700+ in any token | Terminal theme is technical but not aggressive; heavy weight breaks the precision aesthetic | Max weight is w600 (titleLarge) |
| Mixing JetBrains Mono and IBM Plex Sans in the same sentence | Creates visual friction in inline text | Segment by semantic role — monospace for data, sans for prose |
| Raw `TextStyle(fontSize: 14, ...)` in widget code | Bypasses the theme system; breaks when theme switches | Always read from `HaloThemeData` |
| Using `Colors.white` for text | Blows out contrast on dark backgrounds and ignores theme semantics | Use `textPrimary` (`#E2E8F0`) |
