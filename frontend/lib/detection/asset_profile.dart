import '../engine/ticker_resolver.dart';

/// Per-asset-class tuning parameters for the detection engine.
///
/// Different asset classes have structurally different price behaviour:
///   - Crypto trades 24/7, wicks are large, volume is noisy
///   - US equities have sessions, tighter wicks, volume is meaningful
///   - Forex has sessions + interbank liquidity patterns
///
/// These profiles are selected automatically from [DataSource] during
/// [DetectionEngine.switchTicker] — no manual configuration needed.
class AssetProfile {
  /// Display name for logging / reports.
  final String name;

  /// Candles after which a signal is considered stale (half-weight in scoring).
  final int staleCandles;

  /// Minimum displacement candle body as ATR multiple to register an FVG.
  /// Below this, the "displacement" is just noise.
  final double minDispAtrMult;

  /// Minimum sweep reversal as ATR multiple to confirm a stop-hunt.
  final double sweepRevMult;

  /// Cluster grouping tolerance as ATR multiple (how close swing points
  /// must be to count as "equal highs/lows").
  final double clusterTolMult;

  /// Maximum FVG gap width as ATR multiple — wider gaps are full candle
  /// ranges, not clean imbalances.
  final double fvgMaxAtrMult;

  /// Minimum FVG gap width as ATR multiple.
  final double fvgMinAtrMult;

  /// ATR multiple above which displacement is "large" (+0.5 score bonus).
  final double largeDispAtrMult;

  /// ATR multiple above which displacement is "very large" / "god candle"
  /// (+1.0 score bonus).
  final double veryLargeDispAtrMult;

  /// Fill percentage above which an FVG is considered consumed and dropped.
  final double maxFillPct;

  /// Candles after which an FVG is hard-expired regardless of fill status.
  /// An unfilled gap from 6 hours ago on a 5m chart is structurally irrelevant.
  final int fvgExpiryCandles;

  /// Sweep repeat count above which exhaustion decay applies.
  /// A cluster swept 4+ times has likely had its liquidity drained.
  final int sweepExhaustionCount;

  /// Score multiplier applied when opposing BOS ≥ aligned BOS near a zone.
  /// Crypto chops more aggressively so gets a heavier penalty than equities/forex.
  final double chopZoneMultiplier;

  /// Minimum FVG gap size as ATR multiple — gaps smaller than this are rounding noise.
  final double fvgMinGapAtrMult;

  /// Minimum wick penetration past the cluster price as ATR multiple.
  /// A $0.02 pierce on a $0.50 ATR didn't hunt stops — it just touched the level.
  final double sweepMinPenMult;

  const AssetProfile({
    required this.name,
    required this.staleCandles,
    required this.minDispAtrMult,
    required this.sweepRevMult,
    required this.clusterTolMult,
    required this.fvgMaxAtrMult,
    required this.fvgMinAtrMult,
    required this.largeDispAtrMult,
    required this.veryLargeDispAtrMult,
    required this.maxFillPct,
    required this.fvgExpiryCandles,
    required this.sweepExhaustionCount,
    required this.chopZoneMultiplier,
    required this.fvgMinGapAtrMult,
    required this.sweepMinPenMult,
  });

  // ── Presets ──────────────────────────────────────────────────────────────────

  /// Crypto (BTC, ETH, SOL, …) — continuous 24/7 trading, large wicks,
  /// noisy volume, no session structure.
  static const crypto = AssetProfile(
    name: 'crypto',
    staleCandles: 30,
    minDispAtrMult: 0.5,
    sweepRevMult: 0.2,
    clusterTolMult: 0.15,
    fvgMaxAtrMult: 1.5,
    fvgMinAtrMult: 0.1,
    largeDispAtrMult: 1.5,
    veryLargeDispAtrMult: 2.0,
    maxFillPct: 0.9,
    fvgExpiryCandles: 100,
    sweepExhaustionCount: 4,
    chopZoneMultiplier: 0.65,
    fvgMinGapAtrMult: 0.12,
    sweepMinPenMult: 0.04,
  );

  /// US equities (stocks, ETFs) — 6.5-hour session, tighter wicks,
  /// volume is reliable, session gaps matter.
  static const usEquities = AssetProfile(
    name: 'us_equities',
    staleCandles: 20,
    minDispAtrMult: 0.35,
    sweepRevMult: 0.25,
    clusterTolMult: 0.12,
    fvgMaxAtrMult: 1.2,
    fvgMinAtrMult: 0.08,
    largeDispAtrMult: 1.2,
    veryLargeDispAtrMult: 1.8,
    maxFillPct: 0.9,
    fvgExpiryCandles: 78,
    sweepExhaustionCount: 3,
    chopZoneMultiplier: 0.75,
    fvgMinGapAtrMult: 0.15,
    sweepMinPenMult: 0.06,
  );

  /// Forex (EUR/USD, GBP/USD, …) — session-based but near-24hr, tight
  /// spreads, interbank liquidity clusters.
  static const forex = AssetProfile(
    name: 'forex',
    staleCandles: 25,
    minDispAtrMult: 0.4,
    sweepRevMult: 0.3,
    clusterTolMult: 0.10,
    fvgMaxAtrMult: 1.3,
    fvgMinAtrMult: 0.08,
    largeDispAtrMult: 1.3,
    veryLargeDispAtrMult: 1.9,
    maxFillPct: 0.9,
    fvgExpiryCandles: 96,
    sweepExhaustionCount: 3,
    chopZoneMultiplier: 0.75,
    fvgMinGapAtrMult: 0.12,
    sweepMinPenMult: 0.05,
  );

  // ── Auto-selection ────────────────────────────────────────────────────────

  /// Returns the appropriate profile for a given [DataSource].
  static AssetProfile fromSource(DataSource source) {
    switch (source) {
      case DataSource.binance:
      case DataSource.coinbase:
        return crypto;
      case DataSource.alpaca:
        return usEquities;
      case DataSource.finnhub:
        return forex;
    }
  }

  @override
  String toString() => 'AssetProfile($name)';
}
