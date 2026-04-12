import '../models/candle.dart';
import 'candle_buffer.dart';

enum SwingType { high, low }

class SwingPoint {
  final SwingType type;
  final double price;
  final DateTime timestamp;
  final int bufferIndex; // index in the buffer at detection time

  const SwingPoint({
    required this.type,
    required this.price,
    required this.timestamp,
    required this.bufferIndex,
  });

  bool get isHigh => type == SwingType.high;
  bool get isLow => type == SwingType.low;

  @override
  String toString() =>
      'SwingPoint(${type.name} @ $price, ${timestamp.toIso8601String()})';
}

/// Identifies swing highs and lows using a left/right lookback window.
///
/// A swing high at index i requires:
///   candles[i].high > candles[i-k].high  for all k in [1, lookback]
///   candles[i].high > candles[i+k].high  for all k in [1, lookback]
///
/// Same logic for swing lows using .low.
class SwingPointDetector {
  /// Number of candles to the left and right required to confirm a swing.
  final int lookback;

  SwingPointDetector({this.lookback = 3});

  /// Scan the full buffer and return all swing points.
  /// The most recent [lookback] candles cannot be confirmed yet.
  List<SwingPoint> scan(CandleBuffer buffer) {
    final candles = buffer.candles;
    final result = <SwingPoint>[];
    final n = candles.length;

    for (int i = lookback; i < n - lookback; i++) {
      if (_isSwingHigh(candles, i)) {
        result.add(SwingPoint(
          type: SwingType.high,
          price: candles[i].high,
          timestamp: candles[i].timestamp,
          bufferIndex: i,
        ));
      }
      if (_isSwingLow(candles, i)) {
        result.add(SwingPoint(
          type: SwingType.low,
          price: candles[i].low,
          timestamp: candles[i].timestamp,
          bufferIndex: i,
        ));
      }
    }

    return result;
  }

  /// Check only the most recently confirmable candle.
  /// Returns a swing point if the candle at index (n - lookback - 1) qualifies.
  SwingPoint? checkLatest(CandleBuffer buffer) {
    final candles = buffer.candles;
    final n = candles.length;
    if (n < lookback * 2 + 1) return null;

    final i = n - lookback - 1;

    if (_isSwingHigh(candles, i)) {
      return SwingPoint(
        type: SwingType.high,
        price: candles[i].high,
        timestamp: candles[i].timestamp,
        bufferIndex: i,
      );
    }
    if (_isSwingLow(candles, i)) {
      return SwingPoint(
        type: SwingType.low,
        price: candles[i].low,
        timestamp: candles[i].timestamp,
        bufferIndex: i,
      );
    }
    return null;
  }

  bool _isSwingHigh(List<Candle> candles, int i) {
    final pivot = candles[i].high;
    for (int k = 1; k <= lookback; k++) {
      if (candles[i - k].high >= pivot) return false;
      if (candles[i + k].high >= pivot) return false;
    }
    return true;
  }

  bool _isSwingLow(List<Candle> candles, int i) {
    final pivot = candles[i].low;
    for (int k = 1; k <= lookback; k++) {
      if (candles[i - k].low <= pivot) return false;
      if (candles[i + k].low <= pivot) return false;
    }
    return true;
  }
}
