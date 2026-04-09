import 'package:detection_engine/intake/candle_aggregator.dart';
import 'package:detection_engine/models/candle.dart';
import 'package:test/test.dart';

void main() {
  test('aggregates five 1m candles into one 5m candle', () {
    final emitted = <Candle>[];
    final aggregator = CandleAggregator(
      periodMinutes: 5,
      onCandle: emitted.add,
    );

    final base = DateTime.utc(2026, 1, 1, 10, 0);
    final candles = [
      Candle(
        timestamp: base,
        open: 100,
        high: 102,
        low: 99,
        close: 101,
        volume: 10,
      ),
      Candle(
        timestamp: base.add(const Duration(minutes: 1)),
        open: 101,
        high: 103,
        low: 100,
        close: 102,
        volume: 20,
      ),
      Candle(
        timestamp: base.add(const Duration(minutes: 2)),
        open: 102,
        high: 104,
        low: 101,
        close: 103,
        volume: 30,
      ),
      Candle(
        timestamp: base.add(const Duration(minutes: 3)),
        open: 103,
        high: 105,
        low: 98,
        close: 100,
        volume: 40,
      ),
      Candle(
        timestamp: base.add(const Duration(minutes: 4)),
        open: 100,
        high: 106,
        low: 97,
        close: 104,
        volume: 50,
      ),
    ];

    for (final candle in candles) {
      aggregator.add(candle);
    }

    expect(emitted, hasLength(1));
    final c = emitted.first;
    expect(c.timestamp, base);
    expect(c.open, 100);
    expect(c.high, 106);
    expect(c.low, 97);
    expect(c.close, 104);
    expect(c.volume, 150);
  });
}
