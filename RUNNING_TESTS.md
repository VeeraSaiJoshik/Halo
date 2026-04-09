# Running Tests

All commands run from `frontend/`. Uses plain `dart` — no Flutter SDK needed.
```bash
cd /Users/kwame/Desktop/Halo/Halo/frontend
```

---

## Intake Test
Tests ticker parsing + live data fetching.

```bash
# Default (Binance, no auth)
dart run bin/intake_test.dart

# With Alpaca keys
ALPACA_API_KEY=xxx ALPACA_API_SECRET=yyy dart run bin/intake_test.dart
```

---

## Detection Test
Fetches 200 real candles, runs the full detection engine, and writes a markdown report to `frontend/reports/`. The report includes all raw market structure data, every scored setup, and the AI-trigger candidates — ready to paste into any LLM for analysis.

```bash
# Default: BTCUSDT 5m via Binance (no auth)
dart bin/detection_test.dart

# Custom symbol/timeframe
dart bin/detection_test.dart ETHUSDT 15m
dart bin/detection_test.dart SOLUSDT 1h

# US stock via Alpaca
ALPACA_API_KEY=xxx ALPACA_API_SECRET=yyy dart bin/detection_test.dart AAPL 5m alpaca
ALPACA_API_KEY=xxx ALPACA_API_SECRET=yyy dart bin/detection_test.dart SPY 15m alpaca
```

Report is written to `reports/{SYMBOL}_{TIMEFRAME}_{TIMESTAMP}.md`.
