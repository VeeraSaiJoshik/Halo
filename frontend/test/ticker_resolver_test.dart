import 'package:frontend/engine/ticker_resolver.dart';
import 'package:test/test.dart';

void main() {
  final resolver = TickerResolver();

  test('AAPL resolves to Alpaca', () {
    final resolved = resolver.resolve('AAPL', '5m');
    expect(resolved.source, DataSource.alpaca);
    expect(resolved.apiSymbol, 'AAPL');
    expect(resolved.apiTimeframe, '5Min');
  });

  test('BTCUSD resolves to Binance', () {
    final resolved = resolver.resolve('BTCUSD', '5m');
    expect(resolved.source, DataSource.binance);
    expect(resolved.apiSymbol, 'BTCUSDT');
    expect(resolved.apiTimeframe, '5m');
  });

  test('EURUSD resolves to Finnhub', () {
    final resolved = resolver.resolve('EURUSD', '1h');
    expect(resolved.source, DataSource.finnhub);
    expect(resolved.apiSymbol, 'EURUSD');
    expect(resolved.apiTimeframe, '60');
  });

  test('SOLUSDT resolves to Binance', () {
    final resolved = resolver.resolve('SOLUSDT', '15m');
    expect(resolved.source, DataSource.binance);
    expect(resolved.apiSymbol, 'SOLUSDT');
    expect(resolved.apiTimeframe, '15m');
  });
}
