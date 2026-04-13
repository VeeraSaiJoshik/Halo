import 'dart:convert';
import 'dart:io';

import 'package:frontend/engine/clients/finnhub_client.dart';
import 'package:frontend/models/candle.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('getCandles routes forex pair to forex endpoint', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, contains('/forex/candle'));
      expect(request.url.queryParameters['symbol'], 'OANDA:EUR_USD');
      expect(request.url.queryParameters['resolution'], '5');

      final body = jsonEncode({
        's': 'ok',
        't': [1712505600, 1712505900],
        'o': [1.1, 1.11],
        'h': [1.12, 1.13],
        'l': [1.09, 1.10],
        'c': [1.11, 1.12],
        'v': [1000, 1200],
      });
      return http.Response(body, 200);
    });

    final client = FinnhubClient(apiKey: 'test-key', httpClient: mock);
    final candles = await client.getCandles(
      'EURUSD',
      resolution: '5',
      from: DateTime.utc(2026, 1, 1, 10),
      to: DateTime.utc(2026, 1, 1, 11),
    );

    expect(candles, hasLength(2));
    expect(candles.first.open, 1.1);
    expect(candles.first.high, 1.12);
    expect(candles.first.low, 1.09);
    expect(candles.first.close, 1.11);
    expect(candles.first.volume, 1000);
  });

  test('getCandles routes equity ticker to stock endpoint', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, contains('/stock/candle'));
      expect(request.url.queryParameters['symbol'], 'AAPL');
      expect(request.url.queryParameters['resolution'], '5');

      final body = jsonEncode({
        's': 'ok',
        't': [1712505600],
        'o': [180.2],
        'h': [181.1],
        'l': [179.9],
        'c': [180.7],
        'v': [2000000],
      });
      return http.Response(body, 200);
    });

    final client = FinnhubClient(apiKey: 'test-key', httpClient: mock);
    final candles = await client.getCandles(
      'AAPL',
      resolution: '5',
      from: DateTime.utc(2026, 1, 1, 10),
      to: DateTime.utc(2026, 1, 1, 11),
    );

    expect(candles, hasLength(1));
    expect(candles.first.open, 180.2);
    expect(candles.first.high, 181.1);
    expect(candles.first.low, 179.9);
    expect(candles.first.close, 180.7);
    expect(candles.first.volume, 2000000);
  });

  test(
    'live integration: getCandles returns valid candles',
    () async {
      final key = Platform.environment['FINNHUB_API_KEY'];
      if (key == null) {
        fail('FINNHUB_API_KEY must be set for this test.');
      }

      final client = FinnhubClient(apiKey: key);
      final now = DateTime.now().toUtc();
      final from = now.subtract(const Duration(hours: 4));
      List<Candle> candles;
      try {
        candles = await client.getCandles(
          'EURUSD',
          resolution: '5',
          from: from,
          to: now,
        );
      } catch (e) {
        final message = e.toString();
        if (message.contains('403') ||
            message.toLowerCase().contains("don't have access")) {
          print(
            'Skipping Finnhub live candle assertion: token lacks candle endpoint entitlement.',
          );
          return;
        }
        rethrow;
      }

      expect(candles, isNotEmpty);
      for (final c in candles) {
        expect(c.high >= c.low, isTrue);
        expect(c.open > 0, isTrue);
        expect(c.close > 0, isTrue);
      }
    },
    skip: Platform.environment['RUN_LIVE_API_TESTS'] == 'true'
        ? false
        : 'Set RUN_LIVE_API_TESTS=true to enable live API tests.',
  );
}
