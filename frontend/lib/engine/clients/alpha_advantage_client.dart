import 'dart:convert';

import 'package:frontend/models/stocks.dart';
import 'package:http/http.dart' as http;

class AlphaAdvantageClient {
  final String apiKey = String.fromEnvironment('ALPHA_VANTAGE_KEY');
  static const String route = "https://www.alphavantage.co/query";

  Future<List<StockName>> searchStocks(String query) async {
    final url = Uri.parse('$route?function=SYMBOL_SEARCH&keywords=$query&apikey=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final matches = data['bestMatches'] as List<dynamic>;
      
      List<StockName> stonks = matches.map(
        (match) => StockName.fromJson(match)
      ).toList().where(
        (stock) => stock.matchScore >= 0.7
      ).toList();

      List<StockName> finalList = stonks.sublist(0, stonks.length < 5 ? stonks.length : 5);

      return finalList;
    } else {
      throw Exception('Failed to search stocks: ${response.statusCode}');
    }
  }
}

AlphaAdvantageClient alphaAdvantageClient = AlphaAdvantageClient();