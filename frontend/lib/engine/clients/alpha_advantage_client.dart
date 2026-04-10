import 'dart:convert';

import 'package:frontend/models/stocks.dart';
import 'package:http/http.dart' as http;

class AlphaAdvantageClient {
  final String apiKey;
  static const String route = "https://www.alphavantage.co/query";

  AlphaAdvantageClient({required this.apiKey});

  Future<List<StockName>> searchStocks(String query) async {
    final url = Uri.parse('$route?function=SYMBOL_SEARCH&keywords=$query&apikey=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final matches = data['bestMatches'] as List<dynamic>;
      return matches.map((match) => StockName.fromJson(match)).toList();
    } else {
      throw Exception('Failed to search stocks: ${response.statusCode}');
    }
  }
}