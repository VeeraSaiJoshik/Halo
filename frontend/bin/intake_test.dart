import 'dart:io';

import 'package:frontend/controllers/DataIntakeController.dart';
import 'package:frontend/engine/stocks/ticker_identifier.dart';

import '../lib/engine/clients/alpaca_client.dart';
import '../lib/engine/clients/binance_client.dart';

Future<void> main(List<String> args) async {
  final binanceBaseUrl =
      Platform.environment['BINANCE_BASE_URL'] ?? 'https://api.binance.us';

  print('=== Ticker Identification Tests ===');
  final identifier = TickerIdentifier();
  final service = IntakeService(
    alpacaClient: null,
    binanceClient: BinanceClient(baseUrl: binanceBaseUrl),
  );

  final testTitles = <String>[
    'BTCUSD, 5 — TradingView - Google Chrome',
    'NASDAQ:AAPL, 15m — TradingView',
    'EURUSD,H1 - MetaTrader 5',
    'TSLA - thinkorswim',
    'Random Page Title',
  ];

  for (final title in testTitles) {
    final info = identifier.identify(title);
    print('  "$title" -> ${info ?? "UNPARSEABLE"}');
  }

  print('\n=== Binance Fetch Test ===');
  final binance = BinanceClient(baseUrl: binanceBaseUrl);
  print('  Using Binance base URL: $binanceBaseUrl');
  try {
    final candles = await binance.getKlines(
      'BTCUSDT',
      interval: '5m',
      limit: 5,
    );
    print('  Got ${candles.length} candles for BTCUSDT 5m');
    for (final c in candles) {
      print(
        '  ${c.timestamp.toUtc().toIso8601String()} '
        'O:${c.open} H:${c.high} L:${c.low} C:${c.close} V:${c.volume}',
      );
    }
  } catch (e) {
    print('  Error: $e');
  }

  final alpacaKey = Platform.environment['ALPACA_API_KEY'];
  final alpacaSecret = Platform.environment['ALPACA_API_SECRET'];
  if (alpacaKey != null && alpacaSecret != null) {
    print('\n=== Alpaca Fetch Test ===');
    final alpaca = AlpacaClient(apiKey: alpacaKey, secretKey: alpacaSecret);
    try {
      final candles = await alpaca.getHistoricalBars(
        'AAPL',
        timeframe: '5Min',
        limit: 5,
      );
      print('  Got ${candles.length} candles for AAPL 5Min');
      for (final c in candles) {
        print(
          '  ${c.timestamp.toUtc().toIso8601String()} '
          'O:${c.open} H:${c.high} L:${c.low} C:${c.close}',
        );
      }
    } catch (e) {
      print('  Error: $e');
    } finally {
      alpaca.close();
    }
  } else {
    print(
      '\n=== Alpaca Test Skipped '
      '(set ALPACA_API_KEY and ALPACA_API_SECRET) ===',
    );
  }

  print('\n=== Intake Service Smoke Test ===');
  service.onTickerSwitch = (symbol, timeframe, history) {
    print('  switchTicker($symbol, $timeframe) history=${history.length}');
  };
  service.onNewCandle = (candle) {
    print('  onCandle(${candle.timestamp.toUtc().toIso8601String()})');
  };
  try {
    await service.onTabTitleChanged('BTCUSD, 5 — TradingView');
  } catch (e) {
    print('  Smoke test fetch error: $e');
  }
  service.dispose();

  print('\nDone.');
}
