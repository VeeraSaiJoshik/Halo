import 'package:frontend/engine/ticker_identifier.dart';
import 'package:test/test.dart';

void main() {
  final id = TickerIdentifier();

  test('TradingView with timeframe', () {
    final r = id.identify('BTCUSD, 5 — TradingView - Google Chrome');
    expect(r?.symbol, 'BTCUSD');
    expect(r?.timeframe, '5m');
    expect(r?.platform, 'tradingview');
  });

  test('TradingView with exchange prefix', () {
    final r = id.identify('NASDAQ:AAPL, 5m — TradingView');
    expect(r?.symbol, 'AAPL');
    expect(r?.timeframe, '5m');
  });

  test('ThinkOrSwim', () {
    final r = id.identify('AAPL - thinkorswim');
    expect(r?.symbol, 'AAPL');
    expect(r?.platform, 'thinkorswim');
  });

  test('MetaTrader', () {
    final r = id.identify('EURUSD,H1 - MetaTrader 5');
    expect(r?.symbol, 'EURUSD');
    expect(r?.timeframe, '1h');
  });

  test('caching - same title returns cached result', () {
    final r1 = id.identify('AAPL, 5 — TradingView');
    final r2 = id.identify('AAPL, 5 — TradingView');
    expect(identical(r1, r2), true);
  });
}
