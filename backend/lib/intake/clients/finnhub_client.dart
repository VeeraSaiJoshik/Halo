import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/candle.dart';

class FinnhubClient {
  final String apiKey;
  final String baseUrl;
  final http.Client _httpClient;
  final bool _ownsClient;

  FinnhubClient({
    required this.apiKey,
    this.baseUrl = 'https://finnhub.io/api/v1',
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  Future<List<Candle>> getCandles(
    String symbol, {
    String resolution = '5',
    required DateTime from,
    required DateTime to,
  }) async {
    final normalizedSymbol = _normalizeSymbol(symbol);
    final endpoint = _resolveEndpoint(normalizedSymbol);

    final uri = Uri.parse('$baseUrl/$endpoint/candle').replace(
      queryParameters: <String, String>{
        'symbol': normalizedSymbol,
        'resolution': resolution,
        'from': (from.toUtc().millisecondsSinceEpoch ~/ 1000).toString(),
        'to': (to.toUtc().millisecondsSinceEpoch ~/ 1000).toString(),
        'token': apiKey,
      },
    );

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Finnhub API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['s'] != 'ok') return <Candle>[];

    final timestamps = (data['t'] as List<dynamic>? ?? const <dynamic>[]);
    final opens = (data['o'] as List<dynamic>? ?? const <dynamic>[]);
    final highs = (data['h'] as List<dynamic>? ?? const <dynamic>[]);
    final lows = (data['l'] as List<dynamic>? ?? const <dynamic>[]);
    final closes = (data['c'] as List<dynamic>? ?? const <dynamic>[]);
    final volumes = data['v'] as List<dynamic>?;

    final length = [
      timestamps.length,
      opens.length,
      highs.length,
      lows.length,
      closes.length,
    ].reduce((a, b) => a < b ? a : b);

    final candles = <Candle>[];
    for (var i = 0; i < length; i++) {
      final ts = timestamps[i];
      final open = _toDouble(opens[i]);
      final high = _toDouble(highs[i]);
      final low = _toDouble(lows[i]);
      final close = _toDouble(closes[i]);
      final volume = _volumeAt(volumes, i);

      if (ts is! num || open == null || high == null || low == null) continue;
      if (close == null) continue;

      candles.add(
        Candle(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            ts.toInt() * 1000,
            isUtc: true,
          ),
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
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

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double _volumeAt(List<dynamic>? volumes, int index) {
    if (volumes == null || index >= volumes.length) return 0.0;
    return _toDouble(volumes[index]) ?? 0.0;
  }

  String _resolveEndpoint(String normalizedSymbol) {
    if (_looksLikeForexSymbol(normalizedSymbol)) {
      return 'forex';
    }
    return 'stock';
  }

  String _normalizeSymbol(String rawSymbol) {
    final symbol = rawSymbol.trim().toUpperCase();
    if (_looksLikeForexSymbol(symbol)) {
      return _normalizeForexSymbol(symbol);
    }
    return symbol;
  }

  bool _looksLikeForexSymbol(String symbol) {
    final compact = symbol.replaceAll(RegExp(r'[^A-Z]'), '');
    if (symbol.startsWith('OANDA:')) return true;
    return compact.length == 6 && RegExp(r'^[A-Z]{6}$').hasMatch(compact);
  }

  String _normalizeForexSymbol(String symbol) {
    if (symbol.startsWith('OANDA:')) return symbol;

    final compact = symbol.replaceAll(RegExp(r'[^A-Z]'), '');
    if (!RegExp(r'^[A-Z]{6}$').hasMatch(compact)) {
      return symbol;
    }

    final base = compact.substring(0, 3);
    final quote = compact.substring(3, 6);
    return 'OANDA:${base}_$quote';
  }
}
