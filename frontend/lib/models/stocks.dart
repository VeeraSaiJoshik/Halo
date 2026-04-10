class StockName {
  final String symbol;
  final String name;
  final String region;
  final double matchScore;
  late String imageUrl;

  StockName({
    required this.symbol,
    required this.name,
    required this.region,
    required this.matchScore,
  }) {
    imageUrl = "https://financialmodelingprep.com/image-stock/${symbol}.png";
  }

  static StockName fromJson(Map<String, dynamic> json) {
    return StockName(
      symbol: json['1. symbol'] as String,
      name: json['2. name'] as String,
      region: json['4. region'] as String,
      matchScore: double.parse(json['9. matchScore'] as String),
    );
  }
}