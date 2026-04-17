# Aurum — Design Specification

**Theme ID:** `HaloThemeType.aurum`
**Tagline:** Editorial Luxury
**Version:** 1.0.0

---

## 1. Personality

Aurum is the prestige layer of the Halo design system. It borrows visual language from high-end financial editorial — think the front page of a major financial newspaper printed on cream stock, then relit in near-black with gold leaf. Every typographic decision reinforces two feelings simultaneously: *authority* (Playfair Display serifs, tight tracking on headlines, generous white-space) and *precision* (Inter for all functional text, monospace JetBrains Mono for live market data).

The name "Aurum" is Latin for gold — a reference to the single accent color that anchors the entire palette.

---

## 2. Font Stack

| Role | Typeface | Package |
|---|---|---|
| Display & Headline | Playfair Display | `google_fonts` |
| Body, Title, Label, UI | Inter | `google_fonts` |
| Ticker / Financial data | JetBrains Mono | `google_fonts` |

Load order fallback (web/desktop): Playfair Display → Georgia → serif; Inter → system-ui → sans-serif; JetBrains Mono → Menlo → monospace.

---

## 3. Full Type Scale

All sizes are logical pixels (dp/sp). `height` is Flutter's line-height multiplier (lineHeight = size × height).

### 3.1 Display — hero text, welcome screen titles

| Token | Font | Size | Weight | letterSpacing | height | Color |
|---|---|---|---|---|---|---|
| `displayLarge` | Playfair Display | 56px | 700 | -0.5 | 1.1 | textPrimary |
| `displayMedium` | Playfair Display | 45px | 700 | -0.3 | 1.1 | textPrimary |

Usage: full-bleed hero sections, onboarding splash screen, empty-state headlines. Never use at smaller than 375px viewport width.

### 3.2 Headline — section titles, page headings

| Token | Font | Size | Weight | letterSpacing | height | Color |
|---|---|---|---|---|---|---|
| `headlineLarge` | Playfair Display | 32px | 600 | -0.2 | 1.2 | textPrimary |
| `headlineMedium` | Playfair Display | 25px | 500 | 0 | 1.3 | textPrimary |

Usage: page titles, modal headers, card section headings.

### 3.3 Title — prominent labels, button text

| Token | Font | Size | Weight | letterSpacing | height | Color |
|---|---|---|---|---|---|---|
| `titleLarge` | Inter | 18px | 600 | 0 | 1.4 | textPrimary |
| `titleMedium` | Inter | 16px | 500 | 0 | 1.4 | textPrimary |

Usage: sidebar section headers, platform names, prominent UI labels, button text.

### 3.4 Body — main and secondary content

| Token | Font | Size | Weight | letterSpacing | height | Color |
|---|---|---|---|---|---|---|
| `bodyLarge` | Inter | 16px | 400 | 0 | 1.6 | textSecondary |
| `bodyMedium` | Inter | 14px | 400 | 0 | 1.6 | textSecondary |

Usage: paragraph copy, descriptions, form helper text, tooltips. The generous 1.6 line-height is intentional — it reflects editorial typography conventions.

### 3.5 Label — uppercase tags, captions, nav items

| Token | Font | Size | Weight | letterSpacing | height | Color |
|---|---|---|---|---|---|---|
| `labelLarge` | Inter | 13px | 500 | 1.5 | 1.2 | textMuted |
| `labelSmall` | Inter | 11px | 500 | 1.5 | 1.2 | textMuted |

Usage: step indicators, category chips, URL bar text, navigation item labels. Always render UPPERCASE in UI; apply `.toUpperCase()` in code — do not set it in the style.

### 3.6 Ticker — financial data

| Token | Font | Size | Weight | letterSpacing | height | Color |
|---|---|---|---|---|---|---|
| `ticker` | JetBrains Mono | 15px | 400 | 0.5 | 1.3 | textPrimary |
| `tickerLarge` | JetBrains Mono | 18px | 500 | 0.5 | 1.3 | textAccent (gold) |

Usage: price displays, percentage changes, volume figures, symbol labels. `tickerLarge` is reserved for the primary instrument being viewed (e.g., the current stock price in focus).

---

## 4. Color Palette

### 4.1 Text Colors

| Token | Hex | ARGB | Usage |
|---|---|---|---|
| `textPrimary` | `#F8FAFC` | `0xFFF8FAFC` | Headlines, primary labels, bright UI text |
| `textSecondary` | `#94A3B8` | `0xFF94A3B8` | Body copy, secondary descriptions |
| `textMuted` | `#475569` | `0xFF475569` | Captions, disabled states, metadata |
| `textAccent` | `#F59E0B` | `0xFFF59E0B` | Gold accent — tickerLarge, highlights, active indicators |

### 4.2 Contrast Ratios (approximate, on near-black #0A0A0F background)

| Token | Contrast ratio | WCAG |
|---|---|---|
| textPrimary (`#F8FAFC`) | ~18.5:1 | AAA |
| textSecondary (`#94A3B8`) | ~7.2:1 | AA |
| textMuted (`#475569`) | ~3.4:1 | AA Large only |
| textAccent (`#F59E0B`) | ~8.9:1 | AA |

textMuted must only be used at label sizes (11–13px) with weight ≥ 500, which qualifies as "large text" under WCAG 2.1.

---

## 5. Usage Rules

### 5.1 Hierarchy

1. One `displayLarge` or `displayMedium` per screen maximum.
2. Playfair Display (display + headline tokens) is for headings only — never use it for body copy or labels.
3. Inter (title + body + label tokens) is for all functional/interactive text.
4. JetBrains Mono (ticker tokens) is exclusively for numeric financial data and symbol identifiers.

### 5.2 Color Application

- Use `textPrimary` for text the user must read to act.
- Use `textSecondary` for context that supports the primary text.
- Use `textMuted` for metadata, timestamps, and step counters.
- Use `textAccent` sparingly — one or two places per screen at most. Overuse destroys the gold's premium signal.

### 5.3 Spacing & Rhythm

- Vertical spacing between display and its subtitle: 8px.
- Between headline and body paragraph: 12px.
- Between body paragraphs: 16px.
- CTA button separation from body text: minimum 48px.

### 5.4 Letter Spacing Behaviour

- Negative letter-spacing on display/headline tokens tightens the large Playfair glyphs to look intentional, not accidental.
- Positive letter-spacing on label tokens (1.5) creates the "small-caps optical" feel common in luxury editorial.
- Never override letter-spacing to 0 on label tokens — it breaks the editorial aesthetic.

---

## 6. Anti-Patterns

| Anti-pattern | Why it breaks Aurum |
|---|---|
| Playfair Display for body text | Serifs at 14–16px read poorly on screen; it also collapses the visual hierarchy |
| `textAccent` on body text | Gold is a premium signal; diluting it with paragraph use makes it meaningless |
| Letter-spacing 0 on `labelLarge`/`labelSmall` | Destroys the luxury editorial feel of the label tier |
| Using `textMuted` for interactive text | Fails contrast requirements for interactive elements |
| Mixing weight 700 with `headlineMedium` (25px) | 500 is intentional — 700 at 25px reads as display, colliding with the display tier |
| More than one `displayLarge`/`displayMedium` per screen | Dilutes the heroic impact |
| Using JetBrains Mono for non-numeric text | Monospace signals data; using it for labels introduces visual noise |
| Overriding `height` (line-height) on body tokens | The 1.6 ratio is load-bearing for editorial readability; tighter = cluttered |
