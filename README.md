# Halo

A desktop Flutter app for multi-tab financial data analysis. Browse trading platforms, track stocks, crypto, and forex, with a clean glassmorphism UI. Using NLP technology, social data is leveraged from a multitude of platforms (X, News Channels, Reddit, Discord, etc) to alert traders of financial patterns IRL. All baked into a seamless browser experience.

---

## Features

### Multi-Tab Workspace
Open multiple independent tabs, each pinned to a stock symbol. Each tab shows the ticker logo, symbol, live price, and daily percent-change badge. Tabs persist their internal state (scroll, panel layout, notifications) while switched out.

### Tab Switcher Overlay
Hold **Option + Tab** to bring up a popup showing all open tabs as icons in a row. Each Tab press cycles the highlight; **Option + Shift + Tab** reverses. Release Option to commit; Esc cancels.

### Stock Search
Press **⌘T** to open the search bar. Powered by Yahoo Finance — type a query and filter to equities, ETFs, indices, and mutual funds. Navigate results with **↑ / ↓** and **Enter**, or **click** any result to open it as a new tab.

### Embedded Web Browser (Per-Tab WebViews)
Each tab can host two embedded browser panels:
- **Portal:** the Webull public quote page for the tab's symbol — no login required.
- **Chart:** TradingView's charting interface, lazy-loaded the first time a tab requests the chart view (keeps tab opens fast).

A hover-revealed nav bar at the top of each WebView exposes reload and close.

### Split Panels & Notifications Pane
Within a single tab you can stack any combination of: Portal, Chart, and a Notifications pane. Adjacent panels are separated by **draggable dividers** so you can resize live. The Notifications pane carries pattern alerts emitted by the detection engine.

### Market Data & Pattern Detection Engine
The app detects the active ticker, resolves it to the right data source, and polls live OHLCV candles:
- **Crypto** → Binance
- **US Equities** → Alpaca
- **Forex** → Finnhub

A real-time detection engine runs over the candle stream and identifies:
- Fair Value Gaps (bullish / bearish)
- Liquidity Sweeps (bullish / bearish)
- Breaks of Structure
- Combined patterns: FVG + Sweep, full bullish/bearish confluence

Each pattern is scored, asset-class-tuned (separate parameter profiles for crypto, US equities, and forex), and surfaced as a notification on the relevant tab.

### Onboarding & Broker Authentication
First launch walks you through linking accounts on supported platforms:
- **Brokerages:** Webull (phone, email, or QR code), Robinhood (email)
- **Charting:** TradingView (email), Finviz (email), thinkorswim (ID)

Each platform's auth flow runs inside an isolated WebView with cookie scoping, then captures the session for use inside the app's tabs.

### Themes
Seven switchable themes via the Settings page — typography, accent color, and gradient all change live:
- **Golden** (Liquid Gold)
- **Terminal** (Technical Precision)
- **Meridian** (Clean Swiss)
- **Blue** (Deep Sapphire)
- **Green** (Emerald Forest)
- **Pink** (Rose Bloom)
- **Red** (Crimson Fire)

### Settings Page
Reachable from the gear icon in the title bar. Currently exposes theme selection and session sign-out (clears stored cookies and session state).

### Glassmorphism UI
Frosted backdrop blurs, animated gradient backgrounds, and a custom macOS-style title bar with red/orange/green window controls.

### Dev Menu
**⌘D** toggles a hidden developer menu for debugging.

---

## Roadmap

The features below are in design or in progress — they extend the current foundation rather than replace it.

### Per-Ticker Research Workspace
Each tab today shows a quote page and a chart. The vision is a full **per-ticker workspace** that consolidates everything you'd otherwise stitch together across tabs in a normal browser:
- **Fundamentals & filings** — earnings, revenue trend, balance-sheet snapshots, recent SEC filings, insider transactions.
- **News stream** — symbol-tagged headlines pulled from financial wires and aggregators, deduplicated and timestamp-aligned to chart events.
- **Social sentiment** — X, Reddit, Discord, and major news outlets piped through the NLP layer to produce a live sentiment signal per ticker, plotted alongside the chart.
- **Pattern history** — replayable timeline of every FVG, liquidity sweep, BOS, and confluence event the detection engine has flagged on the symbol.
- **Notes & annotations** — durable, per-ticker scratchpad and chart annotations that persist across sessions.

The intent: opening a tab for `AAPL` should feel less like opening Webull, and more like opening a curated *AAPL workspace* with everything an active trader needs in one place.

### Automatic Screening
A continuously-running screen across the user's universe (or the broader market) that surfaces tickers worth attention right now. Built on top of the existing detection engine and social NLP signals:
- **Pattern-driven scanning** — every confluence event the engine fires (e.g., "bullish FVG + sweep on 5m") becomes a candidate alert across every monitored symbol, not just the active tab.
- **Cross-signal triage** — combine technical patterns with sentiment spikes, unusual volume, and news catalysts to rank candidates by strength.
- **User-tuned watchlists** — define screens like "S&P 500 with bullish confluence + positive social delta in the last hour" and have results stream in live.

### AI Recommendations
The placeholder AI Summary pane evolves into an **active recommendation surface**:
- **Setup explanations** — when the engine flags a pattern, the AI generates a plain-language brief: what the pattern is, why it matters on this ticker right now, what would invalidate it, and recent comparable setups.
- **Personalized suggestions** — based on the user's past tab activity, watchlist, and trade behavior, surface tickers and timeframes the user is statistically likely to care about.
- **Risk & position sizing** — paired with the active broker session, suggest position sizes consistent with the user's account size and recent volatility on the instrument.
- **End-of-day digest** — a generated recap of what the user watched, what fired, and what to watch tomorrow.

The unifying idea: the detection engine produces *signals*, the social NLP layer produces *context*, and the AI layer turns both into *decisions* the user can act on.

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘T` | Open stock search |
| `⌘1` … `⌘9` | Jump to tab 1–9 |
| `Option + Tab` | Cycle forward through tabs (with overlay) |
| `Option + Shift + Tab` | Cycle backward through tabs |
| `⌘B` | Show Portal view in current tab |
| `⌘G` | Show Chart view in current tab |
| `⌘N` | Toggle Notifications pane |
| `⌘D` | Toggle dev menu |
| `↑ / ↓` | Move selection in search results |
| `Enter` | Select highlighted search result |
| `Esc` | Dismiss the active overlay |

---

## Setup & Running

**Prerequisites:** Flutter SDK installed and configured for macOS desktop.

```bash
flutter pub get
flutter run -d macos --dart-define-from-file=env.json
```

### API Keys (optional)

To enable stock and forex live data, set the following in `env.json` (see `example_env.json`):

```json
{
  "ALPACA_API_KEY":    "your_key",
  "ALPACA_API_SECRET": "your_secret",
  "FINNHUB_API_KEY":   "your_key"
}
```

Crypto data via Binance requires no API key.
