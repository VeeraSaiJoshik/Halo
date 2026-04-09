import 'dart:convert';
import 'dart:io';

import 'package:frontend/engine/clients/binance_client.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('getKlines parses kline payload', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v3/klines');
      expect(request.url.queryParameters['symbol'], 'BTCUSDT');
      expect(request.url.queryParameters['interval'], '5m');
      expect(request.url.queryParameters['limit'], '2');

      final body = jsonEncode([
        [
          1712505600000,
          '68000.1',
          '68200.0',
          '67900.2',
          '68100.5',
          '123.45',
        ],
        [
          1712505900000,
          '68100.5',
          '68300.0',
          '68050.0',
          '68250.3',
          '150.00',
        ],
      ]);
      return http.Response(body, 200);
    });

    final client = BinanceClient(
      baseUrl: 'https://api.binance.com',
      httpClient: mock,
    );

    final candles = await client.getKlines(
      'BTCUSDT',
      interval: '5m',
      limit: 2,
    );

    expect(candles, hasLength(2));
    expect(candles.first.open, closeTo(68000.1, 0.00001));
    expect(candles.first.high, closeTo(68200.0, 0.00001));
    expect(candles.first.low, closeTo(67900.2, 0.00001));
    expect(candles.first.close, closeTo(68100.5, 0.00001));
    expect(candles.first.volume, closeTo(123.45, 0.00001));
  });

  test(
    'live integration: getKlines returns valid candles',
    () async {
      final baseUrl =
          Platform.environment['BINANCE_BASE_URL'] ?? 'https://api.binance.us';
      final client = BinanceClient(baseUrl: baseUrl);
      final candles = await client.getKlines(
        'BTCUSDT',
        interval: '5m',
        limit: 10,
      );
      expect(candles.length, 10);
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
