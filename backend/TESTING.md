# Testing Quick Guide

This project has unit tests and optional live API integration checks.

## Fast Start

- Run normal test suite (live checks skipped):
  ```bash
  cd /Users/kwame/Desktop/Halo/Halo/backend
  ./scripts/run_tests.sh
  ```
- Run full suite with live API checks (uses `.env`):
  ```bash
  cd /Users/kwame/Desktop/Halo/Halo/backend
  ./scripts/run_tests.sh live
  ```
- Run one file:
  ```bash
  cd /Users/kwame/Desktop/Halo/Halo/backend
  ./scripts/run_tests.sh file test/finnhub_client_test.dart
  ```

## What The Bash Script Does

- Script path: `scripts/run_tests.sh`
- `default` mode:
  - Runs `dart test -r expanded --chain-stack-traces`
  - Live tests stay skipped unless `RUN_LIVE_API_TESTS=true`
- `live` mode:
  - Loads env vars from `.env`
  - Exports `RUN_LIVE_API_TESTS=true`
  - Runs the same full `dart test` command
- `file` mode:
  - Runs a specific test file with expanded output

## Test File Map

- `test/ticker_identifier_test.dart`
  - Verifies tab-title parsing for TradingView, thinkorswim, MetaTrader, and cache behavior.
- `test/ticker_resolver_test.dart`
  - Verifies symbol routing (Alpaca vs Binance vs Finnhub) and timeframe conversion.
- `test/candle_normalizer_test.dart`
  - Verifies raw payload normalization into the internal `Candle` model.
- `test/candle_aggregator_test.dart`
  - Verifies 1-minute candle aggregation (OHLCV math correctness).
- `test/alpaca_client_test.dart`
  - Unit tests for response parsing + optional live Alpaca fetch.
- `test/binance_client_test.dart`
  - Unit tests for response parsing + optional live Binance fetch.
- `test/finnhub_client_test.dart`
  - Unit tests for forex/stock routing + optional live Finnhub fetch.

## Environment Variables For Live Tests

- `ALPACA_API_KEY`
- `ALPACA_API_SECRET`
- `FINNHUB_API_KEY`
- `BINANCE_BASE_URL` (for US setup use `https://api.binance.us`)
- `RUN_LIVE_API_TESTS=true` (set by script in `live` mode)

## Optional: See Real Candle Numbers

- Run harness:
  ```bash
  cd /Users/kwame/Desktop/Halo/Halo/backend
  set -a; source .env; set +a
  dart run bin/intake_test.dart
  ```
