# Halo — Design System

Halo is an AI‑native trading workspace built in Flutter. The visual language is **glassmorphism over an animated, theme‑tinted gradient field**, with a runtime‑switchable typography + color system. Every surface in the app is a translucent panel layered over the same painted background; identity is controlled centrally by `HaloThemeData`.

---

## 1. Visual Identity

| Pillar | What it means |
|---|---|
| **Glass over gradient** | The window is a single full‑bleed canvas. UI lives in semi‑transparent surfaces with `BackdropFilter` blurs on top of an animated multi‑blob gradient. |
| **Theme‑first** | Color, fonts, gradients, and accents are *not* hard‑coded in widgets — they read from `ref.watch(haloThemeProvider)`. Switching theme retints the entire app instantly. |
| **Tactile motion** | Every interactive surface tilts, scales, and glows on hover. Press states drop scale, release pops back via `Curves.easeOutBack`. |
| **Data is monospace** | Prices, percentages, symbols, model IDs always use `theme.ticker` / `theme.tickerLarge`. Prose and UI labels use the theme's sans/serif stack. |
| **Frameless desktop chrome** | Title bar is hidden (`TitleBarStyle.hidden`); the app draws its own traffic‑light buttons, tab strip, and 15px outer corner radius. |

---

## 2. Theme Architecture

### 2.1 Files

```
lib/themes/
├── halo_theme.dart       # HaloThemeData abstract base + HaloThemeType enum
├── theme_provider.dart   # haloThemeTypeProvider + haloThemeProvider (Riverpod)
├── golden_theme.dart     # 7 concrete implementations
├── terminal_theme.dart
├── meridian_theme.dart
├── blue_theme.dart
├── green_theme.dart
├── pink_theme.dart
└── red_theme.dart

design-system/
├── aurum.md              # Reference specs (note: code uses "golden", not "aurum")
├── terminal.md
└── meridian.md
```

### 2.2 Contract

`HaloThemeData` (abstract, in `halo_theme.dart`) is the single contract every widget reads from:

```dart
abstract class HaloThemeData {
  HaloThemeType get type;

  // Type scale
  TextStyle get displayLarge;     TextStyle get displayMedium;
  TextStyle get headlineLarge;    TextStyle get headlineMedium;
  TextStyle get titleLarge;       TextStyle get titleMedium;
  TextStyle get bodyLarge;        TextStyle get bodyMedium;
  TextStyle get labelLarge;       TextStyle get labelSmall;
  TextStyle get ticker;           TextStyle get tickerLarge;

  // Semantic text colors
  Color get textPrimary;          // headings / active labels
  Color get textSecondary;        // body / supporting copy
  Color get textMuted;            // metadata / captions
  Color get textAccent;           // live data / tickerLarge / highlights

  // Surface + ambient color system
  List<Color> get backgroundGradient;  // 2‑stop linear gradient (topLeft→bottomRight)
  List<Color> get blobColors;          // animated radial blobs
  Color  get glassOverlay;             // dark tint above blobs (~0.45 alpha)
  double get blobOpacity;              // 0.25 (terminal/meridian) – 0.50 (warm/saturated)
  Color  get accentColor;              // glow color, primary CTA tint
  Color  get whiteColor;               // theme‑tinted "white" — borders, icon fills
  Color  get backgroundColor;          // near‑black anchor for opaque containers
  Color  get primaryColor;             // mid‑tone — button base, hover surface
}
```

### 2.3 Consuming the theme

Every widget either:

```dart
final theme = ref.watch(haloThemeProvider);
Text("Halo", style: theme.displayMedium.copyWith(color: theme.whiteColor));
```

…or accepts a `HaloThemeData` parameter (`_Header`, `_PriceRow`, `NotificationWidget` internals). Avoid raw `TextStyle(fontSize: …)` in widget code — bypassing the theme breaks all 7 retints.

### 2.4 State + persistence

```dart
final haloThemeTypeProvider = StateProvider<HaloThemeType>((ref) => HaloThemeType.golden);
final haloThemeProvider     = Provider<HaloThemeData>((ref) =>
  switch (ref.watch(haloThemeTypeProvider)) {
    HaloThemeType.golden   => GoldenTheme(),
    HaloThemeType.terminal => TerminalTheme(),
    HaloThemeType.meridian => MeridianTheme(),
    // …blue, green, pink, red
  });
```

The selected theme is read from `SettingsHandler` at app boot (`MainApp.dart:initState`) and persisted via `settingsProvider.applyTheme(...)` from the Settings page.

---

## 3. The 7 Themes

| ID | Display Name | Tagline | Accent | Font Stack |
|---|---|---|---|---|
| `golden` | Golden | Liquid Gold | `#F59E0B` | Instrument Serif · Playfair Display · Inter · JetBrains Mono |
| `terminal` | Terminal | Technical Precision | `#00D97A` | JetBrains Mono · IBM Plex Sans |
| `meridian` | Meridian | Clean Swiss | `#3B82F6` | Space Grotesk · Archivo Black · DM Sans · Fira Code |
| `blue` | Blue | Deep Sapphire | `#60A5FA` | Instrument Serif · Playfair Display · Inter · JetBrains Mono |
| `green` | Green | Emerald Forest | `#34D399` | Instrument Serif · Playfair Display · Inter · JetBrains Mono |
| `pink` | Pink | Rose Bloom | `#F472B6` | Instrument Serif · Playfair Display · Inter · JetBrains Mono |
| `red` | Red | Crimson Fire | `#F87171` | Instrument Serif · Playfair Display · Inter · JetBrains Mono |

**Three "design language" themes** (Golden, Terminal, Meridian) carry distinct typographic personalities. The remaining four (Blue, Green, Pink, Red) reuse the Golden type stack and only swap the color palette — they're palette variants, not full design languages.

### 3.1 Color palettes (reference)

| Theme | bgGradient (top → bottom) | blobOpacity | Notes |
|---|---|---|---|
| Golden | `#3D1500` → `#210A00` | 0.50 | 6 amber/orange/yellow blobs; cream `whiteColor #F4E9D8` |
| Terminal | `#0A2818` → `#071A10` | 0.25 | 4 emerald/teal blobs; muted, dashboard‑grade |
| Meridian | amber 700 → amber 900 *(currently amber, code comment says "navy")* | 0.25 | 4 blue blobs; the bg gradient diverges from the spec |
| Blue | `#001535` → `#000A1C` | 0.50 | 6 sapphire/indigo/sky blobs |
| Green | `#002B16` → `#000E07` | 0.50 | 6 emerald/green/teal blobs |
| Pink | `#2D0020` → `#160010` | 0.50 | 6 rose/fuchsia/coral blobs |
| Red | (see `red_theme.dart`) | 0.50 | crimson palette |

> ⚠️ **Known mismatch:** `meridian_theme.dart:171` sets `backgroundGradient` to `[amber.shade700, amber.shade900]` rather than the documented `#0D1F4A → #0C1844` navy. Treat the code as truth or fix the gradient before relying on the spec.

### 3.2 Semantic text colors

All themes share the same neutral text scale, except for `textAccent` (which carries the theme color):

| Token | Golden / Blue / Green / Pink / Red | Terminal | Meridian |
|---|---|---|---|
| `textPrimary` | `#F8FAFC` | `#E2E8F0` | `#F1F5F9` |
| `textSecondary` | `#94A3B8` | `#64748B` | `#B8B094` *(warm tan — diverges from slate)* |
| `textMuted` | `#475569` | `#334155` | `#475569` |
| `textAccent` | theme accent (e.g. `#F59E0B` for Golden) | `#00D97A` | `#3B82F6` |

---

## 4. Type Scale

The token *roles* are stable across themes; only the typeface and metrics change. Consume tokens — never override `fontSize`/`fontFamily` inline.

| Token | Usage | Golden (Playfair/Inter/JBM) | Terminal (JBM/IBM Plex) | Meridian (Space Grotesk/DM Sans/Fira Code) |
|---|---|---|---|---|
| `displayLarge` | Hero headline (one per screen) | Instrument Serif 66/700/-0.5 | JBM 48/500/0 | Space Grotesk 52/700/-1.5 |
| `displayMedium` | Onboarding splash, empty‑state hero | Instrument Serif 45/700/-0.3 | JBM 36/500/0 | Archivo Black 40/400/-1.0 |
| `headlineLarge` | Section title | Playfair 32/600/-0.2 | JBM 24/500/0 | Space Grotesk 30/600/-0.5 |
| `headlineMedium` | Sub‑section / modal header | Playfair 25/500/0 | JBM 20/400/0 | Space Grotesk 22/600/-0.3 |
| `titleLarge` | Sidebar headers, prominent labels, button text | Inter 18/600 | IBM Plex Sans 16/600/+0.5 | DM Sans 18/600 |
| `titleMedium` | Tabbed labels, secondary buttons | Inter 16/500 | IBM Plex Sans 14/500/+0.5 | DM Sans 15/500 |
| `bodyLarge` | Paragraph copy | Inter 16/400, h=1.6 | IBM Plex Sans 15/400, h=1.4 | DM Sans 16/400, h=1.55 |
| `bodyMedium` | Helper text, descriptions | Inter 14/400, h=1.6 | IBM Plex Sans 13/400, h=1.4 | DM Sans 14/400, h=1.55 |
| `labelLarge` | UPPERCASE eyebrows, nav items | Inter 13/500/+1.5 | JBM 12/400/+1.5 | DM Sans 12/600/+0.5 |
| `labelSmall` | Tags, captions | Inter 11/500/+1.5 | JBM 10/400/+1.5 | DM Sans 11/500/+0.5 |
| `ticker` | Static prices, symbols, volumes | JBM 15/400/+0.5 | JBM 14/500/0 | Fira Code 15/400/0 |
| `tickerLarge` | Live‑updating / focused price (uses `textAccent`) | JBM 18/500/+0.5 | JBM 18/500/0 | Fira Code 18/500/0 |

### Rules
1. **One `displayLarge`/`displayMedium` per screen.** Hero impact dilutes if reused.
2. **Numbers ⇒ ticker tokens.** Never put a price in `bodyMedium` — proportional fonts misalign on reflow. Pair with `FontFeature.tabularFigures()` when columns matter.
3. **`tickerLarge` = live or focused.** It's tinted `textAccent`; using it on stale data dilutes the live‑data signal.
4. **UPPERCASE labels** are uppercased in code (`.toUpperCase()`), not via CSS — the +1.5 letterSpacing is calibrated for all‑caps rendering.
5. **Negative tracking** belongs only to display/headline tokens. Never on body, ticker, or DM Sans/Fira Code.
6. **Don't override `fontWeight` or `height` on a token.** If the weight is wrong, pick a different token.

---

## 5. Background System

The animated background is `BackgroundGradientAnimation` (`lib/widgets/background_gradient_animation.dart`). It paints, in order:

1. **Static linear gradient** — `theme.backgroundGradient`, topLeft → bottomRight.
2. **`GradientBlobsPainter`** — 4–6 radial blobs (`theme.blobColors`) drifting on independent sine paths over a 20s loop. Each blob is a radial gradient from `color.withAlpha(blobOpacity)` to transparent, ~`shortestSide × 0.6` radius.
3. **`BackdropFilter` blur** — `sigmaX/Y = 40` (default) flattening the layer beneath, then a `theme.glassOverlay` color (~45% black) tinting it.
4. **Grain layer** — `_GrainPainter` draws ~`shortestSide × 3.5` gaussian‑distributed white points (alpha `0x14`) per blob using a Box‑Muller transform, syncing motion with the blobs.
5. **Content** — child tree.

Blob count, hues, opacity, and overlay are entirely theme‑driven; calling `BackgroundGradientAnimation()` with no params produces a different ambient feel for every theme without code changes.

---

## 6. Surfaces & Glass

### 6.1 The body panel (`BodyPage.dart`)

The main content frame is the canonical "thick glass" pattern in Halo:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        border: Border.all(color: theme.whiteColor.withOpacity(0.10)),
      ),
      child: …,
    ),
  ),
)
```

| Recipe | Used where | Notes |
|---|---|---|
| `radius 10` + `blur 40` + `black 55%` + `whiteColor 10%` border | BodyPage main panel | The standard frosted card |
| `radius 14` + `blur 2` + linear gradient (`primary → background` @ 92% alpha) + double border (`whiteColor 60%` inner, `whiteColor 20%` outer, `0.5px`) + tri‑shadow (black 45%, accent glow 30%, dirColor glow 10%) | NotificationWidget | Heaviest, most decorated surface |
| `radius 30` + `blur 45` + `primaryColor 30%` + `whiteColor 15%` border | TabSwitcherOverlay | Pill shape, deepest blur |
| `radius 5` + per‑tab `blur 20` (active) / `blur 0` (inactive) + `whiteColor 10%` fill + tri‑border (top/left/right) | WindowTab | Active tab "lifts" via blur inversion |
| `radius 20` + `blur 40` + `whiteColor 7%` + `whiteColor 12%` border | DevMenu | Center modal, ⌘D toggle |
| `radius 5` + `blur 2` + `primary` base + `accent 60%` border + `accent` boxShadow | StandardButton | Sub‑section icon buttons |
| `radius 10` + ClipRRect + `blur 2` (inner) + `primaryColor` (selected) / `primaryColor 40%` (idle) + `whiteColor 80%` inner border + `whiteColor 20%` outer | PlushyButton | Onboarding & primary CTAs |
| `radius 5` + `primaryColor 96%` + black 45% bottom shadow | TopNavModel | Web view URL bar |

### 6.2 Glass conventions

- **Border alpha 0.06 – 0.20** for hairline edges; `0.45 – 0.6` for emphasized perimeters (notification, active tab).
- **Inner stroke at 0.5px**, outer perimeter at 1px. Use `strokeAlign: BorderSide.strokeAlignOutside` to keep corners crisp.
- **Two‑border stacking** (outer perimeter + inner highlight) is the signature Halo card edge — see NotificationWidget and PlushyButton.
- **Use `theme.whiteColor`, never `Colors.white`.** The "white" is theme‑tinted (cream for Golden, mint for Green, etc.) so borders read warm/cool with the rest of the theme.

---

## 7. Motion Grammar

Every interactive widget shares the same motion vocabulary. The constants below appear repeatedly across `StandardButton`, `PlushyButton`, `WindowTab`, `NavButton`, `_ThemeCard`, `_SignOutRow`, `_PreviewVerdictButton`.

| Cue | Idle | Hover | Press | Duration | Curve |
|---|---|---|---|---|---|
| **Scale** | 1.0 | 1.05 – 1.12 | 0.97 – 0.78 (varies) | 100 – 200ms | `easeOutBack` (release), `easeOut` (press) |
| **Tilt (rotation)** | 0 | ±0.025 – 0.08 turns (`directionMulti` or `reverse`) | — | 200 – 250ms | `easeOutBack` |
| **Glow / boxShadow** | accent 0% blur 8 | accent 55% blur 24 spread 3 | sustained selected: accent 50% blur 28 spread 5 | 200 – 300ms | `easeInOut` |
| **Frost sheen** | opacity 0 | opacity 1 (linear gradient `whiteColor 18% → 5% → 0%`) | — | 200ms | linear |
| **Background tint** | `primaryColor 40%` | `primaryColor 100%` | — | 200ms | `easeInOut` |
| **Border** | `whiteColor 7-15%` | `whiteColor 30-45%` | — | 150 – 200ms | `easeInOut` |

### Patterns
- **Symmetric tilt** — paired side icons rotate outward (`directionMulti = -1` left, `+1` right) so they feel like wings opening.
- **Pop‑on‑release** — pressed widgets scale *up* past 1.0 (`_pressed ? 1.08 : (_hovered ? 1.05 : 1.0)`) then settle — gives a "rubber" feel.
- **Color tweens for traffic lights** — close/min/fullscreen circles tween grey → red/orange/green over 200ms when the user enters the title bar.
- **Bus‑driven animations** — slide‑in side panels (`AddSubSection`) listen to the `appEventBusProvider` and run `AnimationController.forward()` on `AppEvent.leftAdd` / `rightAdd`.

---

## 8. Layout Anatomy

```
HomePage (Scaffold, transparent, ClipRRect 15px when not full screen)
└── BackgroundGradientAnimation
    ├── Stack
    │   ├── Column
    │   │   ├── TitleBar (height 40)
    │   │   │   ├── CommandButtons (red/orange/green traffic lights)
    │   │   │   ├── WindowTab × N (240×34, per stock)
    │   │   │   ├── + new‑tab (FontAwesome plus)
    │   │   │   └── ⚙ settings
    │   │   └── BodyPage (the glass panel)
    │   │       ├── Settings page (when settingsOpen)
    │   │       └── Tab content (Stack of Offstage'd tabs)
    │   │           └── Row of panels with _PanelDivider drag handles
    │   │               ├── PORTAL (CustomWebView)
    │   │               ├── GRAPH_VIEWER (CustomWebView)
    │   │               └── NOTIFICATIONS (AISummaryView)
    │   ├── Search overlay (CustomSearchBar, animated grow from 0×0 → 550×55)
    │   ├── DevMenu (⌘D, glass center modal)
    │   ├── TabSwitcherOverlay (Option+Tab, pill of stock icons)
    │   └── MouseRegionEngine
    └── NotificationWidget (anchored bottom‑right, 380×auto, slides 60×30 in)
```

### Multi‑pane bodies
A tab can host up to 3 panels side‑by‑side: `[PORTAL, GRAPH_VIEWER, NOTIFICATIONS]`. Panels are separated by a 12px draggable `_PanelDivider` (clamps `webviewSplit` to 0.1–0.9, `notifFraction` to 0.15–0.6). Inactive panels stay mounted inside `Offstage(offstage: true)` so WKWebView keeps content warm.

---

## 9. Component Catalogue

| Widget | File | Role |
|---|---|---|
| `BackgroundGradientAnimation` | `widgets/background_gradient_animation.dart` | The painted canvas (gradient + blobs + blur + grain) |
| `TitleBar` | `pages/TitleBar.dart` | Frameless‑window top bar |
| `CommandButtons` | `widgets/commandButtons.dart` | Animated traffic lights → `windowManager` |
| `WindowTab` | `widgets/window_tab.dart` | Per‑stock tab with logo, symbol, price badge, close/eye/notif slot |
| `CustomSearchBar` + `SearchField` + `StockBar` | `widgets/searchBar.dart`, `widgets/SearchWidgets/` | ⌘T spotlight search |
| `BodyPage` | `pages/BodyPage.dart` | Glass content frame + draggable panel splitter |
| `AddSubSection` | `widgets/OverlayWidgets/AddSubSection.dart` | Hover‑triggered side rail to add Graph/Portal/Notifications panel |
| `BottomNavModal` / `TopNavModal` | `widgets/OverlayWidgets/` | Bottom panel switcher / web view URL bar |
| `TabSwitcherOverlay` | `widgets/OverlayWidgets/TabSwitcherOverlay.dart` | Option+Tab pill |
| `NotificationWidget` | `widgets/NotificationWidget.dart` | Verdict toast (bottom‑right; bullish/bearish header, 0–10 confidence bar, Entry/Invalidation/Target rows, thesis, key risks, footer) |
| `DevMenu` | `widgets/DevMenu.dart` | ⌘D dev overlay (preview verdict, sign out, theme switcher) |
| `StandardButton` | `widgets/Buttons/StandardButton.dart` | Compact icon button — primary motion vocabulary baked in |
| `PlushyButton` | `widgets/Buttons/plushyButton.dart` | Plumper, primary‑CTA variant w/ stronger glow |
| `OnboardingPage` + form widgets | `pages/OnboardingPage.dart`, `widgets/OnboardingWidgets/` | Welcome → platform selection → auth web view → finish |
| `SettingsPage` | `pages/SettingsPage.dart` | "APPEARANCE → Theme" grid + "ACCOUNT → Sign out" |

---

## 10. Iconography

- Primary icon library: **`font_awesome_flutter`** (`FontAwesomeIcons.plus`, `gear`, `arrowTrendUp`, `crosshairs`, `shieldHalved`, `flagCheckered`, `microchip`, `xmark`, …). Default sizes: 11–16px.
- Material rounded icons (`Icons.check_rounded`, `Icons.logout_rounded`, `Icons.chevron_right_rounded`) are used when a softer look is needed (theme cards, sign‑out row).
- Custom raster icons in `assets/images/icons/` and `assets/images/` (`graph.png`, `search.png`, `icon.png`, `stocks.png`) — used for the side rail (`AddSubSection`) and bottom nav.

---

## 11. Keyboard & Input

The global key handler lives in `HomePage._onKey` (`pages/HomePage.dart`).

| Combo | Action |
|---|---|
| `⌘ T` | Open spotlight search |
| `⌘ G` | Toggle Graph (chart) panel |
| `⌘ B` | Toggle Portal (web) panel |
| `⌘ N` | Toggle Notifications panel |
| `⌘ 1` … `⌘ 9` | Switch to tab N |
| `⌘ D` | Toggle DevMenu |
| `Option + Tab` / `Option + Shift + Tab` | Cycle tabs via `TabSwitcherOverlay`; commit on Option release |
| `Esc` | Dismiss verdict notification → DevMenu → search → tab switcher (in that priority) |
| `↑` / `↓` | Move selection in search results |
| `Enter` | Select highlighted result |

Mouse cursors are explicit on every interactive surface (`SystemMouseCursors.click`, `resizeColumn`, `forbidden`).

---

## 12. Accessibility

- **Reduce‑motion:** `_NotificationOverlayHost` checks `MediaQuery.disableAnimations` and skips the slide animation when set.
- **Semantics:** Notification widget wraps the toast in `Semantics(liveRegion: true, label: …)`; direction pill carries `'Bullish verdict' / 'Bearish verdict'` labels; close button has `Semantics(button: true, label: 'Close')`.
- **Contrast (Aurum/Golden reference):** `textPrimary` ~18.5:1 (AAA), `textSecondary` ~7.2:1 (AA), `textAccent` ~8.9:1 (AA). `textMuted` only hits AA Large — restrict it to label/caption sizes (≤13px, weight ≥500).
- **Tabular numbers:** `FontFeature.tabularFigures()` is applied wherever digits stack vertically (price grids, footers, confidence count).

---

## 13. Anti‑Patterns

| Don't | Why | Do |
|---|---|---|
| `TextStyle(fontSize: 14, color: Colors.white)` inline | Bypasses theme; breaks on retint | Read `theme.bodyMedium` / `titleMedium` etc. |
| `Colors.white` for borders or text | Ignores theme `whiteColor` tinting | `theme.whiteColor.withOpacity(α)` |
| `bodyLarge` for a price | Proportional font misaligns columns | `ticker` (or `tickerLarge` for live/focused) |
| `tickerLarge` for static cached values | The accent color signals *live data* | `ticker` for static |
| Multiple `displayLarge` per screen | Dilutes hero impact | One per screen |
| Playfair / Space Grotesk for body | Headline‑calibrated faces fatigue at 14–16 | Inter / IBM Plex Sans / DM Sans |
| Letter‑spacing 0 on `labelLarge`/`labelSmall` | Destroys editorial rhythm | Keep `+1.5` (Golden/Inter) or `+0.5` (Meridian/Terminal) |
| Negative tracking on Fira Code / DM Sans / IBM Plex | Calibrated for Space Grotesk / serif headers only | Leave at 0 |
| Hover with no glow + tilt | Feels flat; breaks Halo's tactile grammar | Pair scale 1.05 + tilt + boxShadow + frost sheen |
| Ad‑hoc `BackdropFilter(blur 5)` cards | Inconsistent with the 2 / 20 / 40 / 45 system | Use 2 (subtle), 20 (tab), 40 (panel), 45 (deep modal) |

---

## 14. Quick Reference

```dart
// Always start a widget with:
final theme = ref.watch(haloThemeProvider);

// Surfaces
color: theme.primaryColor.withOpacity(0.55),
border: Border.all(color: theme.whiteColor.withOpacity(0.10)),
boxShadow: [BoxShadow(color: theme.accentColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],

// Text
Text(symbol,        style: theme.ticker);
Text(price,         style: theme.tickerLarge);              // accent‑tinted
Text('THESIS',      style: theme.labelSmall);               // already letterSpaced
Text(thesis,        style: theme.bodyMedium.copyWith(color: theme.textPrimary, height: 1.5));

// Background canvas
BackgroundGradientAnimation(child: …);   // pick up theme automatically

// Motion (reuse these constants)
const fast    = Duration(milliseconds: 150);
const medium  = Duration(milliseconds: 200);
const slow    = Duration(milliseconds: 300);
const popOut  = Curves.easeOutBack;
const settle  = Curves.easeInOut;
```

---

*This document reflects the codebase as of `main` @ `eb5bdd6`. The 7 themes plus animated gradient/blob/grain canvas, glass surfaces, and the tactile motion grammar form a coherent system; switch theme to verify any new widget retints correctly across all 7 (the Settings page → Appearance → Theme grid is the fastest visual smoke test).*
