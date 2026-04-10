class StockName {
  final String symbol;
  final String name;
  final String region;

  StockName({
    required this.symbol,
    required this.name,
    required this.region,
  });

  static StockName fromJson(Map<String, dynamic> json) {
    return StockName(
      symbol: json['1. symbol'] as String,
      name: json['2. name'] as String,
      region: json['4. region'] as String,
    );
  }
}