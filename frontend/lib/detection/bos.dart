import '../models/candle.dart';
import 'candle_buffer.dart';
import 'swing_points.dart';

enum BosDirection { bullish, bearish }

/// A Break of Structure event.
///
/// Bullish BOS: price closes above the most recent confirmed swing high.
/// Bearish BOS: price closes below the most recent confirmed swing low.
///
/// This signals a shift in market structure — the trend has broken and
/// momentum is accelerating in the BOS direction.
class Bos {
  final BosDirection direction;

  /// The swing point level that was broken.
  final double brokenLevel;

  /// The candle that closed beyond the level.
  final DateTime timestamp;

  /// How far the close is beyond the broken level (in price units).
  final double breakDistance;

  const Bos({
    required this.direction,
    required this.brokenLevel,
    required this.timestamp,
    required this.breakDistance,
  });

  bool get isBullish => direction == BosDirection.bullish;
  bool get isBearish => direction == BosDirection.bearish;

  @override
  String toString() =>
      'BOS(${direction.name} above/below $brokenLevel at $timestamp, dist: $breakDistance)';
}

/// Detects Break of Structure events.
///
/// Algorithm:
///   1. Extract swing highs and lows from the buffer.
///   2. Track the most recent confirmed swing high and swing low.
///   3. When the latest candle's close exceeds a swing high → bullish BOS.
///   4. When the latest candle's close falls below a swing low → bearish BOS.
///
/// A BOS is only reported once per broken level. The engine is responsible for
/// deduplicating across multiple `onCandle` calls.
class BosDetector {
  final SwingPointDetector _swingDetector;

  /// Minimum break distance as ATR multiple to filter out noise wicks.
  final double minBreakAtrMultiple;

  BosDetector({
    int swingLookback = 3,
    this.minBreakAtrMultiple = 0.05,
  }) : _swingDetector = SwingPointDetector(lookback: swingLookback);

  /// Scan the full buffer and return all BOS events found historically.
  List<Bos> scan(CandleBuffer buffer) {
    final candles = buffer.candles;
    final atr = buffer.atr;
    if (candles.length < 5 || atr == 0.0) return [];

    final swings = _swingDetector.scan(buffer);
    if (swings.isEmpty) return [];

    final minBreak = atr * minBreakAtrMultiple;
    final result = <Bos>[];

    // Walk candles forward, maintaining a running window of recent swing points
    // that have been confirmed before each candle's index.
    final highs = swings.where((s) => s.isHigh).toList();
    final lows = swings.where((s) => s.isLow).toList();

    for (int i = 1; i < candles.length; i++) {
      final candle = candles[i];

      // Most recent swing high confirmed before this candle
      final prevHighs = highs.where((s) => s.bufferIndex < i).toList();
      final prevLows = lows.where((s) => s.bufferIndex < i).toList();

      if (prevHighs.isNotEmpty) {
        final latestHigh = prevHighs.last;
        final breakDist = candle.close - latestHigh.price;
        if (breakDist > minBreak) {
          result.add(Bos(
            direction: BosDirection.bullish,
            brokenLevel: latestHigh.price,
            timestamp: candle.timestamp,
            breakDistance: breakDist,
          ));
        }
      }

      if (prevLows.isNotEmpty) {
        final latestLow = prevLows.last;
        final breakDist = latestLow.price - candle.close;
        if (breakDist > minBreak) {
          result.add(Bos(
            direction: BosDirection.bearish,
            brokenLevel: latestLow.price,
            timestamp: candle.timestamp,
            breakDistance: breakDist,
          ));
        }
      }
    }

    return result;
  }

  /// Check if the most recent candle in the buffer constitutes a BOS
  /// relative to the most recently confirmed swing points.
  Bos? checkLatest(CandleBuffer buffer) {
    final candles = buffer.candles;
    final atr = buffer.atr;
    if (candles.length < 5 || atr == 0.0) return null;

    final swings = _swingDetector.scan(buffer);
    if (swings.isEmpty) return null;

    final last = candles.last;
    final minBreak = atr * minBreakAtrMultiple;

    // Find the most recent swing high and low (confirmed, so bufferIndex < last)
    SwingPoint? latestHigh;
    SwingPoint? latestLow;

    for (final s in swings) {
      if (s.isHigh) latestHigh = s;
      if (s.isLow) latestLow = s;
    }

    if (latestHigh != null) {
      final breakDist = last.close - latestHigh.price;
      if (breakDist > minBreak) {
        return Bos(
          direction: BosDirection.bullish,
          brokenLevel: latestHigh.price,
          timestamp: last.timestamp,
          breakDistance: breakDist,
        );
      }
    }

    if (latestLow != null) {
      final breakDist = latestLow.price - last.close;
      if (breakDist > minBreak) {
        return Bos(
          direction: BosDirection.bearish,
          brokenLevel: latestLow.price,
          timestamp: last.timestamp,
          breakDistance: breakDist,
        );
      }
    }

    return null;
  }
}
