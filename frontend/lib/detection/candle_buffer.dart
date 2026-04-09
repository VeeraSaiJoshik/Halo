import '../models/candle.dart';

/// Rolling buffer of OHLCV candles, capped at [maxSize].
/// Also tracks ATR(14) incrementally for use by detection algorithms.
class CandleBuffer {
  final int maxSize;
  final List<Candle> _candles = [];

  // ATR(14) state — maintained incrementally
  double _atr = 0.0;
  static const int _atrPeriod = 14;

  CandleBuffer({this.maxSize = 200});

  /// Load a batch of historical candles (e.g. on ticker switch).
  /// Replaces current buffer contents.
  void loadHistory(List<Candle> candles) {
    _candles.clear();
    final trimmed =
        candles.length > maxSize ? candles.sublist(candles.length - maxSize) : candles;
    _candles.addAll(trimmed);
    _recalcAtr();
  }

  /// Add a single new candle (e.g. from live polling).
  void add(Candle candle) {
    _candles.add(candle);
    if (_candles.length > maxSize) {
      _candles.removeAt(0);
    }
    _updateAtr(candle);
  }

  /// All candles in chronological order.
  List<Candle> get candles => List.unmodifiable(_candles);

  /// Number of candles in the buffer.
  int get length => _candles.length;

  bool get isEmpty => _candles.isEmpty;
  bool get isNotEmpty => _candles.isNotEmpty;

  /// Most recent candle.
  Candle? get last => _candles.isEmpty ? null : _candles.last;

  /// Current ATR(14). Returns 0 if not enough data.
  double get atr => _atr;

  /// Candle at index [i] (0 = oldest).
  Candle operator [](int i) => _candles[i];

  // ── ATR calculation ────────────────────────────────────────────────────────

  void _recalcAtr() {
    if (_candles.length < 2) {
      _atr = 0.0;
      return;
    }

    // Compute true ranges for all candles after the first
    final trs = <double>[];
    for (int i = 1; i < _candles.length; i++) {
      trs.add(_trueRange(_candles[i], _candles[i - 1]));
    }

    if (trs.length < _atrPeriod) {
      _atr = trs.reduce((a, b) => a + b) / trs.length;
      return;
    }

    // Wilder's smoothed ATR
    double atr = trs.sublist(0, _atrPeriod).reduce((a, b) => a + b) / _atrPeriod;
    for (int i = _atrPeriod; i < trs.length; i++) {
      atr = (atr * (_atrPeriod - 1) + trs[i]) / _atrPeriod;
    }
    _atr = atr;
  }

  void _updateAtr(Candle newCandle) {
    if (_candles.length < 2) {
      _atr = 0.0;
      return;
    }
    final prev = _candles[_candles.length - 2];
    final tr = _trueRange(newCandle, prev);

    if (_atr == 0.0) {
      _recalcAtr();
    } else {
      _atr = (_atr * (_atrPeriod - 1) + tr) / _atrPeriod;
    }
  }

  double _trueRange(Candle current, Candle prev) {
    final hl = current.high - current.low;
    final hc = (current.high - prev.close).abs();
    final lc = (current.low - prev.close).abs();
    return [hl, hc, lc].reduce((a, b) => a > b ? a : b);
  }
}
