# Halo

A desktop Flutter app for multi-tab financial data analysis. Browse trading platforms, track stocks, crypto, and forex, with a clean glassmorphism UI.

---

## Features

### Multi-Tab Workspace
Open multiple independent tabs, each tracking its own set of assets. Tabs display active ticker symbols and can be switched between freely.

### Embedded Web Browser (Stocks View)
Each tab contains a full WebView for browsing trading platforms (TradingView, thinkorswim, MetaTrader, etc.). Includes back/forward navigation and a URL bar that appears on hover.

### Market Data Engine
The app detects the current ticker and timeframe from the active trading platform's page title, then automatically fetches candlestick (OHLCV) data from the appropriate source:
- **Crypto** → Binance
- **Stocks** → Alpaca
- **Forex** → Finnhub

Data is polled every 15 seconds for live updates.

### Browse & AI Summary Views
Bottom navigation lets you switch between the Stocks view, a Browse view, and an AI Summary view. Browse and AI Summary are currently placeholders.

### macOS Window Controls
Custom title bar with animated red/orange/green window control buttons (close, minimize, maximize).

---

## Setup & Running

**Prerequisites:** Flutter SDK installed and configured for macOS desktop.

```bash
flutter pub get
flutter run -d macos
```

### API Keys (optional)

To enable stock and forex data, set the following environment variables before running:

```bash
export ALPACA_API_KEY=your_key
export ALPACA_API_SECRET=your_secret
export FINNHUB_API_KEY=your_key
```

Crypto data via Binance requires no API key.
