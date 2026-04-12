import 'package:frontend/engine/candle_normalizer.dart';
import 'package:frontend/engine/ticker_resolver.dart';
import 'package:test/test.dart';

void main() {
  final normalizer = CandleNormalizer();

  test('normalizes Alpaca bars', () {
    final candles = normalizer.normalize(DataSource.alpaca, {
      'bars': [
        {
          't': '2026-01-01T10:00:00Z',
          'o': 10,
          'h': 12,
          'l': 9.5,
          'c': 11.2,
          'v': 1000,
        },
      ],
    });

    expect(candles, hasLength(1));
    expect(candles.first.open, 10);
    expect(candles.first.high, 12);
    expect(candles.first.low, 9.5);
    expect(candles.first.close, 11.2);
    expect(candles.first.volume, 1000);
  });

  test('normalizes Binance klines', () {
    final candles = normalizer.normalize(DataSource.binance, [
      [1712505600000, '68000.1', '68200.0', '67900.2', '68100.5', '123.45'],
    ]);

    expect(candles, hasLength(1));
    expect(candles.first.open, closeTo(68000.1, 0.00001));
    expect(candles.first.high, closeTo(68200.0, 0.00001));
    expect(candles.first.low, closeTo(67900.2, 0.00001));
    expect(candles.first.close, closeTo(68100.5, 0.00001));
    expect(candles.first.volume, closeTo(123.45, 0.00001));
  });

  test('normalizes Finnhub candles', () {
    final candles = normalizer.normalize(DataSource.finnhub, {
      's': 'ok',
      't': [1712505600],
      'o': [1.1010],
      'h': [1.1025],
      'l': [1.1002],
      'c': [1.1018],
      'v': [4567],
    });

    expect(candles, hasLength(1));
    expect(candles.first.open, closeTo(1.1010, 0.000001));
    expect(candles.first.high, closeTo(1.1025, 0.000001));
    expect(candles.first.low, closeTo(1.1002, 0.000001));
    expect(candles.first.close, closeTo(1.1018, 0.000001));
    expect(candles.first.volume, 4567);
  });
}
