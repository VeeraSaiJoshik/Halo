import 'package:frontend/models/candle.dart';

class CandleAggregator {
  final int periodMinutes;
  final void Function(Candle) onCandle;
  final List<Candle> _buffer = [];

  CandleAggregator({
    required this.periodMinutes,
    required this.onCandle,
  }) : assert(periodMinutes > 0);

  void add(Candle oneMinCandle) {
    _buffer.add(oneMinCandle);

    if (_buffer.length >= periodMinutes) {
      _emit();
    }
  }

  void reset() => _buffer.clear();

  void _emit() {
    if (_buffer.isEmpty) return;

    final aggregated = Candle(
      timestamp: _buffer.first.timestamp,
      open: _buffer.first.open,
      high: _buffer.map((c) => c.high).reduce((a, b) => a > b ? a : b),
      low: _buffer.map((c) => c.low).reduce((a, b) => a < b ? a : b),
      close: _buffer.last.close,
      volume: _buffer.map((c) => c.volume).reduce((a, b) => a + b),
    );

    _buffer.clear();
    onCandle(aggregated);
  }
}
