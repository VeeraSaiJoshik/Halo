import 'dart:convert';

import 'package:frontend/models/stocks.dart';
import 'package:http/http.dart' as http;

class YahooFinanceClient {
  static const String route = "https://query1.finance.yahoo.com/v1/finance/search?q=";

  Future<List<StockName>> searchStocks(String query) async {
    final url = Uri.parse('$route$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final quotes = data['quotes'] as List<dynamic>;

      print(quotes);
      
      const allowedTypes = {'EQUITY', 'ETF', 'INDEX', 'MUTUALFUND'};

      List<StockName> stonks = quotes.map(
        (quote) => StockName(
          symbol: quote['symbol'] as String,
          name: quote['shortname'] as String,
          region: "",
          stockType: quote['quoteType'] as String,
          matchScore: 0.0
        )
      ).toList().where((stock) => allowedTypes.contains(stock.stockType)).toList();

      List<StockName> finalList = stonks.sublist(0, stonks.length < 3 ? stonks.length : 3);

      return finalList;
    } else {
      throw Exception('Failed to search stocks: ${response.statusCode}');
    }
  }
}

YahooFinanceClient yahooFinanceClient = YahooFinanceClient();