# Production / Beta Readiness Notes

email used: ekbotsellc@gmail.com

- Confirm market data provider plan entitlements:
  - Finnhub candle access (`/stock/candle`, `/forex/candle`) currently not enabled on current token.
  - Validate exact paid tiers needed for symbols/timeframes you support.
- Finalize provider strategy by asset class:
  - Equities (Alpaca), Crypto (Binance US), Forex (Finnhub or alternate provider).
  - Add fallback provider for each critical asset class.
- Define and budget subscriptions:
  - Market data API tiers (rate limits, historical depth, exchange coverage).
  - Optional alerting/monitoring/logging services.
- Move secrets out of local `.env` for non-dev environments:
  - Use a secrets manager or secure deployment env vars.
  - Rotate exposed/reused API keys before beta launch.
- Add reliability features:
  - Retry/backoff, timeout strategy, and circuit-breaker behavior.
  - Better error classification for entitlement vs network vs invalid symbol.
- Add observability:
  - Structured logs, request IDs, and provider latency/error metrics.
  - Health checks for each provider dependency.
- Improve ingestion correctness:
  - Decide canonical timezone/session handling.
  - Handle partial/in-progress candles consistently.
  - Verify symbol normalization across providers.
- Harden testing before beta:
  - Separate unit/integration/live suites in CI.
  - Add fixture-based regression tests for provider payload changes.
  - Add smoke tests per provider with entitlement checks.
- Deployment/runtime readiness:
  - Define environment profiles (dev/staging/prod).
  - Add startup config validation (missing keys, invalid base URLs, disabled providers).
- Security/compliance review:
  - Audit logs for sensitive data leakage.
  - Verify terms-of-service compliance for each data vendor.
