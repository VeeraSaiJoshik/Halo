import '../detection/confluence.dart';

/// Stable fingerprint for a scored setup. Same zone + direction + score bucket
/// → same fingerprint, even across successive scans as minor values shift.
///
/// Determines whether we hit the server cache (cheap) or run fresh inference
/// (expensive). The bucketing is the cost-control lever — fine-grained values
/// would defeat dedup entirely.
class SetupFingerprint {
  /// Round the zone midpoint to the nearest 0.25× ATR so the same zone hashes
  /// the same across scans where ATR has nudged by a few cents.
  static String of(ScoredSetup setup, {required double atr}) {
    final bucket = atr > 0 ? (setup.zoneMidpoint / (atr * 0.25)).round() : 0;
    final scoreBucket = setup.score.floor();
    final direction = setup.dominantPattern.name.contains('ullish') ? 'bull' : 'bear';
    return '${setup.symbol}-${setup.timeframe}-$direction-$bucket-$scoreBucket';
  }
}
