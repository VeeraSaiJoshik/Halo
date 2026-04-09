class TickerInfo {
  final String symbol;
  final String timeframe;
  final String platform;

  const TickerInfo({
    required this.symbol,
    required this.timeframe,
    this.platform = 'unknown',
  });

  @override
  String toString() => '$symbol · $timeframe ($platform)';
}

class TickerIdentifier {
  String _lastTitle = '';
  TickerInfo? _lastResult;

  TickerInfo? identify(String tabTitle) {
    if (tabTitle == _lastTitle && _lastResult != null) {
      return _lastResult;
    }

    _lastTitle = tabTitle;
    _lastResult = _tryParse(tabTitle);
    return _lastResult;
  }

  TickerInfo? _tryParse(String title) {
    return _tryTradingView(title) ??
        _tryThinkOrSwim(title) ??
        _tryMetaTrader(title) ??
        _tryGeneric(title);
  }

  TickerInfo? _tryTradingView(String title) {
    final re = RegExp(
      r'(?:[A-Z]+:)?([A-Z0-9./]+)[,\s]+(\d+[mhdwm]?(?:in)?)\s*[—–-]\s*TradingView',
      caseSensitive: false,
    );
    final match = re.firstMatch(title);
    if (match != null) {
      return TickerInfo(
        symbol: match.group(1)!.toUpperCase(),
        timeframe: _normalizeTimeframe(match.group(2)!),
        platform: 'tradingview',
      );
    }

    final reNoTf = RegExp(
      r'(?:[A-Z]+:)?([A-Z0-9./]+)\s*[—–-]\s*TradingView',
      caseSensitive: false,
    );
    final matchNoTf = reNoTf.firstMatch(title);
    if (matchNoTf != null) {
      return TickerInfo(
        symbol: matchNoTf.group(1)!.toUpperCase(),
        timeframe: '5m',
        platform: 'tradingview',
      );
    }

    return null;
  }

  TickerInfo? _tryThinkOrSwim(String title) {
    final re = RegExp(
      r'^([A-Z0-9.]+)\s*-\s*thinkorswim',
      caseSensitive: false,
    );
    final match = re.firstMatch(title);
    if (match != null) {
      return TickerInfo(
        symbol: match.group(1)!.toUpperCase(),
        timeframe: '5m',
        platform: 'thinkorswim',
      );
    }
    return null;
  }

  TickerInfo? _tryMetaTrader(String title) {
    final re = RegExp(
      r'^([A-Z0-9]+),?\s*([A-Z]?\d+)\s*-\s*MetaTrader',
      caseSensitive: false,
    );
    final match = re.firstMatch(title);
    if (match != null) {
      return TickerInfo(
        symbol: match.group(1)!.toUpperCase(),
        timeframe: _normalizeTimeframe(match.group(2)!),
        platform: 'metatrader',
      );
    }
    return null;
  }

  TickerInfo? _tryGeneric(String title) {
    final re = RegExp(r'\b([A-Z]{1,5})\b');
    final match = re.firstMatch(title);
    if (match != null) {
      final candidate = match.group(1)!;
      const ignore = {'THE', 'AND', 'FOR', 'NEW', 'TAB', 'HOME', 'PAGE'};
      if (!ignore.contains(candidate)) {
        return TickerInfo(
          symbol: candidate,
          timeframe: '5m',
          platform: 'unknown',
        );
      }
    }
    return null;
  }

  String _normalizeTimeframe(String raw) {
    final s = raw.trim().toUpperCase();

    if (s.startsWith('M') && s.length > 1) {
      final n = int.tryParse(s.substring(1));
      if (n != null) return '${n}m';
    }
    if (s.startsWith('H') && s.length > 1) {
      final n = int.tryParse(s.substring(1));
      if (n != null) return '${n}h';
    }
    if (s == 'D1' || s == 'D' || s == 'DAILY') return '1d';
    if (s == 'W1' || s == 'W' || s == 'WEEKLY') return '1w';

    final n = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n != null) {
      if (s.contains('H')) return '${n}h';
      if (s.contains('D')) return '${n}d';
      if (s.endsWith('MIN') || s.endsWith('M')) return '${n}m';
      if (n <= 60) return '${n}m';
    }

    return '5m';
  }
}
