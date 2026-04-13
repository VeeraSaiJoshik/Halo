import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../models/candle.dart';

class BinanceClient {
  final String baseUrl;
  final http.Client _httpClient;
  final bool _ownsClient;

  BinanceClient({
    this.baseUrl = 'https://api.binance.com',
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  Future<List<Candle>> getKlines(
    String symbol, {
    String interval = '5m',
    int limit = 200,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v3/klines').replace(
      queryParameters: <String, String>{
        'symbol': symbol,
        'interval': interval,
        'limit': limit.toString(),
      },
    );

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Binance API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    final candles = <Candle>[];
    for (final kline in data) {
      if (kline is! List<dynamic> || kline.length < 6) continue;
      final ts = kline[0];
      if (ts is! num) continue;

      candles.add(
        Candle(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            ts.toInt(),
            isUtc: true,
          ),
          open: _toDouble(kline[1]),
          high: _toDouble(kline[2]),
          low: _toDouble(kline[3]),
          close: _toDouble(kline[4]),
          volume: _toDouble(kline[5]),
        ),
      );
    }

    return candles;
  }

  void close() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw Exception('Invalid numeric value: $value');
  }
}
