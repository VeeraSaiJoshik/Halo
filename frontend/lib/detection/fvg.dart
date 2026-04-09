import 'package:frontend/models/candle.dart';
import 'candle_buffer.dart';

enum FvgDirection { bullish, bearish }

enum FvgStatus {
  active,   // gap exists, price hasn't returned
  partial,  // price has partially entered the gap
  filled,   // gap fully closed (price traded through entire gap)
}

/// A Fair Value Gap (FVG) — also called an imbalance or inefficiency.
///
/// Bullish FVG: formed by 3 candles where candle[1] has a large bullish body
///   and the gap between candle[0].high and candle[2].low is unfilled.
///   → zone: [candle[0].high, candle[2].low]
///
/// Bearish FVG: formed by 3 candles where candle[1] has a large bearish body
///   and the gap between candle[2].high and candle[0].low is unfilled.
///   → zone: [candle[2].high, candle[0].low]
class Fvg {
  final FvgDirection direction;
  final double upper;  // top of the gap zone
  final double lower;  // bottom of the gap zone
  final DateTime timestamp; // timestamp of the middle (displacement) candle
  final double displacementSize; // body size of the middle candle

  FvgStatus status;
  double fillPercent; // 0.0 → 1.0

  Fvg({
    required this.direction,
    required this.upper,
    required this.lower,
    required this.timestamp,
    required this.displacementSize,
    this.status = FvgStatus.active,
    this.fillPercent = 0.0,
  });

  double get gapSize => upper - lower;

  bool get isBullish => direction == FvgDirection.bullish;
  bool get isBearish => direction == FvgDirection.bearish;

  /// Midpoint of the gap — the most likely reaction price.
  double get midpoint => (upper + lower) / 2;

  /// Update fill status based on current price (typically close of latest candle).
  void update(double currentLow, double currentHigh) {
    if (status == FvgStatus.filled) return;

    if (isBullish) {
      // Bullish FVG fills when price trades down into it
      if (currentLow <= lower) {
        status = FvgStatus.filled;
        fillPercent = 1.0;
      } else if (currentLow < upper) {
        fillPercent = (upper - currentLow) / gapSize;
        status = FvgStatus.partial;
      }
    } else {
      // Bearish FVG fills when price trades up into it
      if (currentHigh >= upper) {
        status = FvgStatus.filled;
        fillPercent = 1.0;
      } else if (currentHigh > lower) {
        fillPercent = (currentHigh - lower) / gapSize;
        status = FvgStatus.partial;
      }
    }
  }

  @override
  String toString() =>
      'FVG(${direction.name} [$lower–$upper] ${status.name} fill:${(fillPercent * 100).toStringAsFixed(0)}%)';
}

/// Detects and tracks Fair Value Gaps in a candle buffer.
class FvgDetector {
  /// Minimum gap size as a multiple of ATR. Gaps smaller than this are noise.
  final double minAtrMultiple;

  FvgDetector({this.minAtrMultiple = 0.1});

  /// Scan full buffer and return all FVGs found (active, partial, filled).
  /// Caller is responsible for filtering by status if needed.
  List<Fvg> scan(CandleBuffer buffer) {
    final candles = buffer.candles;
    final atr = buffer.atr;
    final result = <Fvg>[];

    if (candles.length < 3) return result;

    for (int i = 1; i < candles.length - 1; i++) {
      final fvg = _tryForm(candles[i - 1], candles[i], candles[i + 1], atr);
      if (fvg != null) result.add(fvg);
    }

    // Update fill status for each FVG against the last candle
    final last = candles.last;
    for (final fvg in result) {
      fvg.update(last.low, last.high);
    }

    return result;
  }

  /// Check the most recently completable 3-candle window (last 3 candles in buffer).
  /// Returns a new FVG if one just formed, null otherwise.
  Fvg? checkLatest(CandleBuffer buffer) {
    final candles = buffer.candles;
    final atr = buffer.atr;
    if (candles.length < 3) return null;

    final n = candles.length;
    return _tryForm(candles[n - 3], candles[n - 2], candles[n - 1], atr);
  }

  Fvg? _tryForm(Candle c0, Candle c1, Candle c2, double atr) {
    final minGap = atr * minAtrMultiple;

    // Bullish FVG: gap between c0.high and c2.low
    final bullishGap = c2.low - c0.high;
    if (bullishGap > minGap && c1.close > c1.open) {
      return Fvg(
        direction: FvgDirection.bullish,
        lower: c0.high,
        upper: c2.low,
        timestamp: c1.timestamp,
        displacementSize: (c1.close - c1.open).abs(),
      );
    }

    // Bearish FVG: gap between c2.high and c0.low
    final bearishGap = c0.low - c2.high;
    if (bearishGap > minGap && c1.close < c1.open) {
      return Fvg(
        direction: FvgDirection.bearish,
        lower: c2.high,
        upper: c0.low,
        timestamp: c1.timestamp,
        displacementSize: (c1.close - c1.open).abs(),
      );
    }

    return null;
  }
}
