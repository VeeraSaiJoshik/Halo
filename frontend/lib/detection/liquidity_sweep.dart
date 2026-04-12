import '../models/candle.dart';
import 'candle_buffer.dart';
import 'swing_points.dart';

enum SweepDirection { bullish, bearish }

/// A liquidity cluster — a price level where multiple swing points (equal highs
/// or equal lows) are clustered within a tolerance band. These levels have
/// accumulated stop orders and are prime sweep candidates.
class LiquidityCluster {
  final SweepDirection side; // bullish = cluster of equal lows, bearish = equal highs
  final double price;        // representative price of the cluster
  final int pointCount;      // how many swing points form this cluster
  final DateTime oldestTimestamp;
  final DateTime newestTimestamp;

  const LiquidityCluster({
    required this.side,
    required this.price,
    required this.pointCount,
    required this.oldestTimestamp,
    required this.newestTimestamp,
  });

  @override
  String toString() =>
      'LiquidityCluster(${side.name} @ $price, $pointCount points)';
}

/// A liquidity sweep — price traded through a liquidity cluster and reversed.
class LiquiditySweep {
  final SweepDirection direction;
  final LiquidityCluster cluster;
  final double sweepExtreme;    // the wick extreme that pierced the cluster
  final double reversalClose;   // close that reversed back
  final DateTime timestamp;     // candle that completed the sweep

  /// Penetration depth: how far beyond the cluster price the wick reached.
  double get penetrationDepth => (sweepExtreme - cluster.price).abs();

  /// Reversal strength: distance the close recovered from the extreme.
  double get reversalStrength => (reversalClose - sweepExtreme).abs();

  const LiquiditySweep({
    required this.direction,
    required this.cluster,
    required this.sweepExtreme,
    required this.reversalClose,
    required this.timestamp,
  });

  @override
  String toString() =>
      'LiquiditySweep(${direction.name} sweep @ ${cluster.price}, reversal: $reversalClose)';
}

/// Detects liquidity clusters and sweeps.
///
/// Algorithm:
///   1. Find all swing highs and lows in the buffer.
///   2. Cluster swing points within [clusterTolerance] of each other.
///   3. For each candle, check if its wick pierced a cluster and closed back inside.
class LiquiditySweepDetector {
  /// Two swing points are "equal" if their prices are within this many ATR multiples.
  final double clusterToleranceAtrMultiple;

  /// Minimum swing points in a cluster for it to be meaningful.
  final int minClusterPoints;

  /// Minimum reversal as ATR multiple (wick pierced but close reversed).
  final double minReversalAtrMultiple;

  final SwingPointDetector _swingDetector;

  LiquiditySweepDetector({
    this.clusterToleranceAtrMultiple = 0.15,
    this.minClusterPoints = 2,
    this.minReversalAtrMultiple = 0.2,
    int swingLookback = 3,
  }) : _swingDetector = SwingPointDetector(lookback: swingLookback);

  /// Find all liquidity clusters in the buffer.
  List<LiquidityCluster> findClusters(CandleBuffer buffer) {
    final swings = _swingDetector.scan(buffer);
    final atr = buffer.atr;
    if (atr == 0.0 || swings.isEmpty) return [];

    final tolerance = atr * clusterToleranceAtrMultiple;
    return _cluster(swings, tolerance);
  }

  /// Scan the full buffer for sweep events.
  List<LiquiditySweep> scan(CandleBuffer buffer) {
    final candles = buffer.candles;
    final atr = buffer.atr;
    if (candles.length < 5 || atr == 0.0) return [];

    final clusters = findClusters(buffer);
    if (clusters.isEmpty) return [];

    final result = <LiquiditySweep>[];
    final minReversal = atr * minReversalAtrMultiple;

    for (final candle in candles) {
      for (final cluster in clusters) {
        final sweep = _checkSweep(candle, cluster, minReversal);
        if (sweep != null) result.add(sweep);
      }
    }

    return result;
  }

  /// Check only the latest candle against existing clusters.
  LiquiditySweep? checkLatest(CandleBuffer buffer) {
    final last = buffer.last;
    if (last == null) return null;

    final atr = buffer.atr;
    if (atr == 0.0) return null;

    final clusters = findClusters(buffer);
    final minReversal = atr * minReversalAtrMultiple;

    for (final cluster in clusters) {
      final sweep = _checkSweep(last, cluster, minReversal);
      if (sweep != null) return sweep;
    }
    return null;
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  List<LiquidityCluster> _cluster(List<SwingPoint> swings, double tolerance) {
    // Separate highs and lows
    final highs = swings.where((s) => s.isHigh).toList();
    final lows = swings.where((s) => s.isLow).toList();

    final clusters = <LiquidityCluster>[];
    clusters.addAll(_clusterSide(highs, SweepDirection.bearish, tolerance));
    clusters.addAll(_clusterSide(lows, SweepDirection.bullish, tolerance));
    return clusters;
  }

  List<LiquidityCluster> _clusterSide(
    List<SwingPoint> points,
    SweepDirection side,
    double tolerance,
  ) {
    if (points.isEmpty) return [];

    // Sort by price
    final sorted = List<SwingPoint>.from(points)
      ..sort((a, b) => a.price.compareTo(b.price));

    final clusters = <LiquidityCluster>[];
    int i = 0;

    while (i < sorted.length) {
      final seed = sorted[i];
      final group = <SwingPoint>[seed];

      int j = i + 1;
      while (j < sorted.length && (sorted[j].price - seed.price).abs() <= tolerance) {
        group.add(sorted[j]);
        j++;
      }

      if (group.length >= minClusterPoints) {
        final avgPrice = group.map((p) => p.price).reduce((a, b) => a + b) / group.length;
        final timestamps = group.map((p) => p.timestamp).toList()
          ..sort();
        clusters.add(LiquidityCluster(
          side: side,
          price: avgPrice,
          pointCount: group.length,
          oldestTimestamp: timestamps.first,
          newestTimestamp: timestamps.last,
        ));
      }

      i = j;
    }

    return clusters;
  }

  LiquiditySweep? _checkSweep(Candle candle, LiquidityCluster cluster, double minReversal) {
    if (cluster.side == SweepDirection.bullish) {
      // Equal lows: look for wick piercing below, close reversing above
      if (candle.low < cluster.price && candle.close > cluster.price) {
        final reversal = candle.close - candle.low;
        if (reversal >= minReversal) {
          return LiquiditySweep(
            direction: SweepDirection.bullish,
            cluster: cluster,
            sweepExtreme: candle.low,
            reversalClose: candle.close,
            timestamp: candle.timestamp,
          );
        }
      }
    } else {
      // Equal highs: look for wick piercing above, close reversing below
      if (candle.high > cluster.price && candle.close < cluster.price) {
        final reversal = candle.high - candle.close;
        if (reversal >= minReversal) {
          return LiquiditySweep(
            direction: SweepDirection.bearish,
            cluster: cluster,
            sweepExtreme: candle.high,
            reversalClose: candle.close,
            timestamp: candle.timestamp,
          );
        }
      }
    }
    return null;
  }
}
