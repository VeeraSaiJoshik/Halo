import 'dart:io';

class ApiConfig {
  final String? alpacaApiKey;
  final String? alpacaSecretKey;
  final String? finnhubApiKey;
  final String alpacaBaseUrl;
  final String binanceBaseUrl;
  final String finnhubBaseUrl;

  const ApiConfig({
    this.alpacaApiKey,
    this.alpacaSecretKey,
    this.finnhubApiKey,
    this.alpacaBaseUrl = 'https://data.alpaca.markets',
    this.binanceBaseUrl = 'https://api.binance.com',
    this.finnhubBaseUrl = 'https://finnhub.io/api/v1',
  });

  factory ApiConfig.fromEnvironment() {
    return ApiConfig(
      alpacaApiKey: Platform.environment['ALPACA_API_KEY'],
      alpacaSecretKey: Platform.environment['ALPACA_API_SECRET'],
      finnhubApiKey: Platform.environment['FINNHUB_API_KEY'],
      alpacaBaseUrl: Platform.environment['ALPACA_BASE_URL'] ??
          'https://data.alpaca.markets',
      binanceBaseUrl:
          Platform.environment['BINANCE_BASE_URL'] ?? 'https://api.binance.com',
      finnhubBaseUrl:
          Platform.environment['FINNHUB_BASE_URL'] ?? 'https://finnhub.io/api/v1',
    );
  }
}
