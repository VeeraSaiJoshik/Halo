class Candle {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const Candle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  Candle copyWith({
    DateTime? timestamp,
    double? open,
    double? high,
    double? low,
    double? close,
    double? volume,
  }) {
    return Candle(
      timestamp: timestamp ?? this.timestamp,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toUtc().toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }

  factory Candle.fromJson(Map<String, dynamic> json) {
    return Candle(
      timestamp: DateTime.parse(json['timestamp'] as String),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'Candle('
        'timestamp: $timestamp, '
        'open: $open, '
        'high: $high, '
        'low: $low, '
        'close: $close, '
        'volume: $volume'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Candle &&
        other.timestamp.toUtc().millisecondsSinceEpoch ==
            timestamp.toUtc().millisecondsSinceEpoch &&
        other.open == open &&
        other.high == high &&
        other.low == low &&
        other.close == close &&
        other.volume == volume;
  }

  @override
  int get hashCode => Object.hash(
        timestamp.toUtc().millisecondsSinceEpoch,
        open,
        high,
        low,
        close,
        volume,
      );
}
