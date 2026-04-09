enum DataSource { alpaca, finnhub, binance, coinbase }

class ResolvedTicker {
  final String symbol;
  final String apiSymbol;
  final DataSource source;
  final String timeframe;
  final String apiTimeframe;

  const ResolvedTicker({
    required this.symbol,
    required this.apiSymbol,
    required this.source,
    required this.timeframe,
    required this.apiTimeframe,
  });
}

class TickerResolver {
  static const _cryptoPairs = {
    'BTCUSD',
    'BTCUSDT',
    'ETHUSD',
    'ETHUSDT',
    'SOLUSD',
    'SOLUSDT',
    'BNBUSD',
    'BNBUSDT',
    'XRPUSD',
    'XRPUSDT',
    'ADAUSD',
    'ADAUSDT',
    'DOGEUSD',
    'DOGEUSDT',
    'AVAXUSD',
    'AVAXUSDT',
    'LINKUSD',
    'LINKUSDT',
    'MATICUSD',
    'MATICUSDT',
    'DOTUSD',
    'DOTUSDT',
  };

  static const _forexPairs = {
    'EURUSD',
    'GBPUSD',
    'USDJPY',
    'USDCHF',
    'AUDUSD',
    'USDCAD',
    'NZDUSD',
    'EURGBP',
    'EURJPY',
    'GBPJPY',
  };

  ResolvedTicker resolve(String symbol, String timeframe) {
    final upper = symbol.toUpperCase().replaceAll('/', '');

    if (_cryptoPairs.contains(upper)) {
      return ResolvedTicker(
        symbol: symbol,
        apiSymbol: _toBinanceSymbol(upper),
        source: DataSource.binance,
        timeframe: timeframe,
        apiTimeframe: _toBinanceInterval(timeframe),
      );
    }

    if (_forexPairs.contains(upper)) {
      return ResolvedTicker(
        symbol: symbol,
        apiSymbol: upper,
        source: DataSource.finnhub,
        timeframe: timeframe,
        apiTimeframe: _toFinnhubResolution(timeframe),
      );
    }

    // Heuristics for unknown symbols: prefer forex when it looks like a
    // standard 6-letter currency pair, otherwise treat common crypto suffixes
    // as crypto.
    if (_looksLikeForex(upper)) {
      return ResolvedTicker(
        symbol: symbol,
        apiSymbol: upper,
        source: DataSource.finnhub,
        timeframe: timeframe,
        apiTimeframe: _toFinnhubResolution(timeframe),
      );
    }

    if (_looksLikeCrypto(upper)) {
      return ResolvedTicker(
        symbol: symbol,
        apiSymbol: _toBinanceSymbol(upper),
        source: DataSource.binance,
        timeframe: timeframe,
        apiTimeframe: _toBinanceInterval(timeframe),
      );
    }

    return ResolvedTicker(
      symbol: symbol,
      apiSymbol: upper,
      source: DataSource.alpaca,
      timeframe: timeframe,
      apiTimeframe: _toAlpacaTimeframe(timeframe),
    );
  }

  bool _looksLikeCrypto(String s) {
    return s.length >= 6 &&
        (s.endsWith('USDT') || s.endsWith('USD') || s.endsWith('BTC'));
  }

  bool _looksLikeForex(String s) {
    return s.length == 6 && RegExp(r'^[A-Z]{6}$').hasMatch(s);
  }

  String _toBinanceSymbol(String s) {
    if (s.endsWith('USD') && !s.endsWith('USDT')) {
      return '${s}T';
    }
    return s;
  }

  String _toBinanceInterval(String tf) => tf;

  String _toAlpacaTimeframe(String tf) {
    final re = RegExp(r'^(\d+)([mhd])$');
    final match = re.firstMatch(tf);
    if (match == null) return '5Min';
    final n = match.group(1)!;
    final unit = match.group(2)!;
    switch (unit) {
      case 'm':
        return '${n}Min';
      case 'h':
        return '${n}Hour';
      case 'd':
        return '${n}Day';
      default:
        return '5Min';
    }
  }

  String _toFinnhubResolution(String tf) {
    final re = RegExp(r'^(\d+)([mhd])$');
    final match = re.firstMatch(tf);
    if (match == null) return '5';
    final n = int.parse(match.group(1)!);
    final unit = match.group(2)!;
    switch (unit) {
      case 'm':
        return '$n';
      case 'h':
        return '${n * 60}';
      case 'd':
        return 'D';
      default:
        return '5';
    }
  }
}
