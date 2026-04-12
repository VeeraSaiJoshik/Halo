import 'fvg.dart';
import 'liquidity_sweep.dart';
import 'bos.dart';

/// All detectable pattern types, including confluence combos.
enum PatternType {
  bullishFvg,
  bearishFvg,
  liquiditySweepBullish,
  liquiditySweepBearish,
  bullishBos,
  bearishBos,
  // Confluence combos
  bullishFvgWithSweep,
  bearishFvgWithSweep,
  fullBullishConfluence, // FVG + sweep + BOS all bullish
  fullBearishConfluence, // FVG + sweep + BOS all bearish
}

/// A raw detection event — single pattern, pre-scoring.
class DetectionEvent {
  final PatternType type;
  final String symbol;
  final String timeframe;
  final double priceLevel; // the key price level for this event
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const DetectionEvent({
    required this.type,
    required this.symbol,
    required this.timeframe,
    required this.priceLevel,
    required this.timestamp,
    required this.metadata,
  });

  @override
  String toString() =>
      'DetectionEvent(${type.name} @ $priceLevel on $symbol $timeframe)';
}

/// A confluence-scored setup — one or more detection events that fired
/// within the same zone, scored and ready for the AI reasoning layer.
class ScoredSetup {
  final List<DetectionEvent> events;
  final double score;
  final String symbol;
  final String timeframe;
  final PatternType dominantPattern;

  /// Price zone the setup is centered around.
  final double zoneUpper;
  final double zoneLower;

  /// Whether price is currently approaching (within 0.5 ATR of) the zone.
  final bool priceApproaching;

  const ScoredSetup({
    required this.events,
    required this.score,
    required this.symbol,
    required this.timeframe,
    required this.dominantPattern,
    required this.zoneUpper,
    required this.zoneLower,
    required this.priceApproaching,
  });

  double get zoneMidpoint => (zoneUpper + zoneLower) / 2;

  @override
  String toString() =>
      'ScoredSetup(${dominantPattern.name} score:$score $symbol $timeframe)';
}

/// Scores raw detections into setups by:
///   1. Grouping events that are in the same price zone (within tolerance).
///   2. Assigning point values per pattern type.
///   3. Applying bonuses for recency, displacement strength, sweep depth.
///   4. Filtering setups below [minScore].
class ConfluenceScorer {
  /// Minimum score for a setup to be returned.
  final double minScore;

  /// Zone grouping tolerance — events within this many ATR units of each other
  /// are considered part of the same setup.
  final double zoneToleranceAtrMultiple;

  static const Map<PatternType, double> _baseScores = {
    PatternType.bullishFvg: 1.5,
    PatternType.bearishFvg: 1.5,
    PatternType.liquiditySweepBullish: 2.0,
    PatternType.liquiditySweepBearish: 2.0,
    PatternType.bullishBos: 1.5,
    PatternType.bearishBos: 1.5,
    PatternType.bullishFvgWithSweep: 4.0,
    PatternType.bearishFvgWithSweep: 4.0,
    PatternType.fullBullishConfluence: 6.0,
    PatternType.fullBearishConfluence: 6.0,
  };

  ConfluenceScorer({
    this.minScore = 2.0,
    this.zoneToleranceAtrMultiple = 1.0,
  });

  /// Score a set of detection events and return setups that meet [minScore].
  List<ScoredSetup> score(
    List<DetectionEvent> events, {
    required double currentPrice,
    required double atr,
  }) {
    if (events.isEmpty) return [];

    final zoneTolerance = atr * zoneToleranceAtrMultiple;
    final groups = _groupByZone(events, zoneTolerance);
    final setups = <ScoredSetup>[];

    for (final group in groups) {
      final setup = _scoreGroup(group, currentPrice, atr);
      if (setup != null && setup.score >= minScore) {
        setups.add(setup);
      }
    }

    // Sort by score descending
    setups.sort((a, b) => b.score.compareTo(a.score));
    return setups;
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  List<List<DetectionEvent>> _groupByZone(
    List<DetectionEvent> events,
    double tolerance,
  ) {
    // Sort by price level
    final sorted = List<DetectionEvent>.from(events)
      ..sort((a, b) => a.priceLevel.compareTo(b.priceLevel));

    final groups = <List<DetectionEvent>>[];
    int i = 0;

    while (i < sorted.length) {
      final group = [sorted[i]];
      int j = i + 1;
      while (j < sorted.length &&
          (sorted[j].priceLevel - sorted[i].priceLevel).abs() <= tolerance) {
        group.add(sorted[j]);
        j++;
      }
      groups.add(group);
      i = j;
    }

    return groups;
  }

  ScoredSetup? _scoreGroup(
    List<DetectionEvent> group,
    double currentPrice,
    double atr,
  ) {
    double score = 0.0;

    // Base score: sum of all events (combo patterns override simple ones)
    final hasCombo = group.any((e) =>
        e.type == PatternType.bullishFvgWithSweep ||
        e.type == PatternType.bearishFvgWithSweep ||
        e.type == PatternType.fullBullishConfluence ||
        e.type == PatternType.fullBearishConfluence);

    if (hasCombo) {
      // Use the highest combo score
      final comboScore = group
          .where((e) => _baseScores.containsKey(e.type))
          .map((e) => _baseScores[e.type]!)
          .fold(0.0, (a, b) => a > b ? a : b);
      score = comboScore;
    } else {
      // Sum individual scores (different types stack)
      final seen = <PatternType>{};
      for (final e in group) {
        if (!seen.contains(e.type)) {
          score += _baseScores[e.type] ?? 1.0;
          seen.add(e.type);
        }
      }
    }

    // Bonus: displacement strength (if FVG has large displacement)
    for (final e in group) {
      if (e.type == PatternType.bullishFvg || e.type == PatternType.bearishFvg) {
        final dispSize = (e.metadata['displacementSize'] as double?) ?? 0.0;
        if (atr > 0 && dispSize > atr * 1.5) score += 0.5;
      }
    }

    // Bonus: sweep penetration depth
    for (final e in group) {
      if (e.type == PatternType.liquiditySweepBullish ||
          e.type == PatternType.liquiditySweepBearish) {
        final depth = (e.metadata['penetrationDepth'] as double?) ?? 0.0;
        if (atr > 0 && depth > atr * 0.3) score += 0.5;
      }
    }

    if (group.isEmpty) return null;

    // Price zone: envelope around the median price level
    final prices = group.map((e) => e.priceLevel).toList()..sort();
    final zoneCenter = prices[prices.length ~/ 2];
    final halfWidth = atr * 0.5;
    final zoneUpper = zoneCenter + halfWidth;
    final zoneLower = zoneCenter - halfWidth;

    final approaching = (currentPrice - zoneCenter).abs() < atr * 1.5;

    // Determine dominant pattern
    final dominant = _dominantPattern(group);

    return ScoredSetup(
      events: group,
      score: score,
      symbol: group.first.symbol,
      timeframe: group.first.timeframe,
      dominantPattern: dominant,
      zoneUpper: zoneUpper,
      zoneLower: zoneLower,
      priceApproaching: approaching,
    );
  }

  PatternType _dominantPattern(List<DetectionEvent> group) {
    // Prefer confluence combos, then sweeps, then FVG, then BOS
    const priority = [
      PatternType.fullBullishConfluence,
      PatternType.fullBearishConfluence,
      PatternType.bullishFvgWithSweep,
      PatternType.bearishFvgWithSweep,
      PatternType.liquiditySweepBullish,
      PatternType.liquiditySweepBearish,
      PatternType.bullishFvg,
      PatternType.bearishFvg,
      PatternType.bullishBos,
      PatternType.bearishBos,
    ];

    for (final p in priority) {
      if (group.any((e) => e.type == p)) return p;
    }
    return group.first.type;
  }
}

// ── Helper: build DetectionEvents from raw detector outputs ─────────────────

DetectionEvent fvgToEvent(Fvg fvg, String symbol, String timeframe) {
  final type =
      fvg.isBullish ? PatternType.bullishFvg : PatternType.bearishFvg;
  return DetectionEvent(
    type: type,
    symbol: symbol,
    timeframe: timeframe,
    priceLevel: fvg.midpoint,
    timestamp: fvg.timestamp,
    metadata: {
      'upper': fvg.upper,
      'lower': fvg.lower,
      'gapSize': fvg.gapSize,
      'displacementSize': fvg.displacementSize,
      'fillPercent': fvg.fillPercent,
      'status': fvg.status.name,
    },
  );
}

DetectionEvent sweepToEvent(LiquiditySweep sweep, String symbol, String timeframe) {
  final type = sweep.direction == SweepDirection.bullish
      ? PatternType.liquiditySweepBullish
      : PatternType.liquiditySweepBearish;
  return DetectionEvent(
    type: type,
    symbol: symbol,
    timeframe: timeframe,
    priceLevel: sweep.cluster.price,
    timestamp: sweep.timestamp,
    metadata: {
      'clusterPrice': sweep.cluster.price,
      'clusterPoints': sweep.cluster.pointCount,
      'sweepExtreme': sweep.sweepExtreme,
      'reversalClose': sweep.reversalClose,
      'penetrationDepth': sweep.penetrationDepth,
      'reversalStrength': sweep.reversalStrength,
    },
  );
}

DetectionEvent bosToEvent(Bos bos, String symbol, String timeframe) {
  final type =
      bos.isBullish ? PatternType.bullishBos : PatternType.bearishBos;
  return DetectionEvent(
    type: type,
    symbol: symbol,
    timeframe: timeframe,
    priceLevel: bos.brokenLevel,
    timestamp: bos.timestamp,
    metadata: {
      'brokenLevel': bos.brokenLevel,
      'breakDistance': bos.breakDistance,
    },
  );
}
