import 'dart:convert';
import 'dart:io';
import 'package:frontend/engine/clients/alpaca_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('getHistoricalBars parses bars payload', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, contains('/v2/stocks/AAPL/bars'));
      expect(request.url.queryParameters['timeframe'], '5Min');
      expect(request.url.queryParameters['limit'], '2');

      final body = jsonEncode({
        'bars': [
          {
            't': '2026-01-01T10:00:00Z',
            'o': 100.0,
            'h': 101.0,
            'l': 99.5,
            'c': 100.7,
            'v': 1234,
          },
          {
            't': '2026-01-01T10:05:00Z',
            'o': 100.7,
            'h': 102.0,
            'l': 100.2,
            'c': 101.9,
            'v': 1400,
          },
        ],
      });
      return http.Response(body, 200);
    });

    final client = AlpacaClient(
      apiKey: 'key',
      secretKey: 'secret',
      baseUrl: 'https://data.alpaca.markets',
      httpClient: mock,
    );

    final candles = await client.getHistoricalBars(
      'AAPL',
      timeframe: '5Min',
      limit: 2,
    );
    expect(candles, hasLength(2));
    expect(candles.first.open, 100.0);
    expect(candles.first.high, 101.0);
    expect(candles.first.low, 99.5);
    expect(candles.first.close, 100.7);
    expect(candles.first.volume, 1234);
  });

  test('getLatestBar parses latest payload', () async {
    final mock = MockClient((request) async {
      final body = jsonEncode({
        'bar': {
          't': '2026-01-01T10:10:00Z',
          'o': 102.0,
          'h': 103.0,
          'l': 101.5,
          'c': 102.4,
          'v': 900,
        },
      });
      return http.Response(body, 200);
    });

    final client = AlpacaClient(
      apiKey: 'key',
      secretKey: 'secret',
      httpClient: mock,
    );

    final bar = await client.getLatestBar('AAPL');
    expect(bar, isNotNull);
    expect(bar!.open, 102.0);
    expect(bar.high, 103.0);
    expect(bar.low, 101.5);
    expect(bar.close, 102.4);
    expect(bar.volume, 900);
  });

  test(
    'live integration: getHistoricalBars returns valid candles',
    () async {
      final key = Platform.environment['ALPACA_API_KEY'];
      final secret = Platform.environment['ALPACA_API_SECRET'];
      if (key == null || secret == null) {
        fail('ALPACA_API_KEY and ALPACA_API_SECRET must be set for this test.');
      }

      final client = AlpacaClient(apiKey: key, secretKey: secret);
      final candles = await client.getHistoricalBars(
        'AAPL',
        timeframe: '5Min',
        limit: 10,
      );

      expect(candles.length, greaterThan(0));
      expect(candles.length, lessThanOrEqualTo(10));
      for (final c in candles) {
        expect(c.high >= c.low, isTrue);
        expect(c.open > 0, isTrue);
        expect(c.close > 0, isTrue);
        expect(c.volume >= 0, isTrue);
      }
    },
    skip: Platform.environment['RUN_LIVE_API_TESTS'] == 'true'
        ? false
        : 'Set RUN_LIVE_API_TESTS=true to enable live API tests.',
  );
}
