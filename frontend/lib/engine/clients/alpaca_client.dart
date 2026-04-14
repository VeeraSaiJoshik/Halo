import 'dart:convert';

import '../../models/candle.dart';
import 'package:http/http.dart' as http;

class AlpacaClient {
  final String apiKey;
  final String secretKey;
  final String baseUrl;
  final http.Client _httpClient;
  final bool _ownsClient;

  AlpacaClient({
    required this.apiKey,
    required this.secretKey,
    this.baseUrl = 'https://data.alpaca.markets',
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  Map<String, String> get _headers => {
        'APCA-API-KEY-ID': apiKey,
        'APCA-API-SECRET-KEY': secretKey,
      };

  Future<List<Candle>> getHistoricalBars(
    String symbol, {
    String timeframe = '5Min',
    int limit = 200,
    DateTime? start,
    DateTime? end,
  }) async {
    final params = <String, String>{
      'timeframe': timeframe,
      'limit': limit.toString(),
      'adjustment': 'split',
      'feed': 'iex',
      'sort': 'asc',
    };

    if (start != null) params['start'] = start.toUtc().toIso8601String();
    if (end != null) params['end'] = end.toUtc().toIso8601String();

    final uri = Uri.parse('$baseUrl/v2/stocks/$symbol/bars')
        .replace(queryParameters: params);
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Alpaca API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    print("Here is the data from Alpaca API: " + data.toString());
    final bars = data['bars'] as List<dynamic>?;
    if (bars == null || bars.isEmpty) return <Candle>[];

    return bars
        .whereType<Map<String, dynamic>>()
        .map(_barToCandle)
        .toList(growable: false);
  }

  Future<Candle?> getLatestBar(String symbol) async {
    final uri = Uri.parse('$baseUrl/v2/stocks/$symbol/bars/latest')
        .replace(queryParameters: const {'feed': 'iex'});

    final response = await _httpClient.get(uri, headers: _headers);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bar = data['bar'] as Map<String, dynamic>?;
    if (bar == null) return null;

    return _barToCandle(bar);
  }

  void close() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  Candle _barToCandle(Map<String, dynamic> bar) {
    return Candle(
      timestamp: _parseTimestamp(bar['t']),
      open: _asDouble(bar['o']),
      high: _asDouble(bar['h']),
      low: _asDouble(bar['l']),
      close: _asDouble(bar['c']),
      volume: _asDouble(bar['v']),
    );
  }

  DateTime _parseTimestamp(dynamic raw) {
    if (raw is String) {
      return DateTime.parse(raw);
    }
    if (raw is int) {
      final ms = raw > 1000000000000 ? raw : raw * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    if (raw is num) {
      final value = raw.toInt();
      final ms = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    throw Exception('Invalid timestamp: $raw');
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw Exception('Invalid numeric value: $value');
  }
}
