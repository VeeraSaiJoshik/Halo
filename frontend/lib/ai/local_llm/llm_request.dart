/// Input passed to a [LocalLlm] implementation. This is the shape Halo's
/// detection engine produces and what the model sees.
///
/// IMPORTANT: this is the *only* input contract. If the LLM needs the data in
/// a different format (e.g. as a chat-templated prompt string), it is the
/// implementation's job to transform this object before generating. The same
/// transformation logic must live inside the LocalLlm so the rest of Halo
/// stays generic.
class LlmRequest {
  final String symbol;
  final String timeframe;

  /// 'crypto', 'us_equities', or 'forex'. Used by the LLM to pick the right
  /// rules / staleness thresholds when reasoning about the setup.
  final String assetProfile;

  final double currentPrice;
  final double atr;

  final SetupSummary setup;
  final List<EventSummary> events;

  /// Last N candles preceding the setup, oldest first. Used for context only.
  /// Implementations may down-sample or truncate as needed for context budget.
  final List<CandleSnapshot> recentCandles;

  /// Stable hash of (symbol, timeframe, dominant pattern, zone, score bucket).
  /// Implementations should NOT recompute this; treat it as opaque.
  final String fingerprint;

  const LlmRequest({
    required this.symbol,
    required this.timeframe,
    required this.assetProfile,
    required this.currentPrice,
    required this.atr,
    required this.setup,
    required this.events,
    required this.recentCandles,
    required this.fingerprint,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'timeframe': timeframe,
        'assetProfile': assetProfile,
        'currentPrice': currentPrice,
        'atr': atr,
        'setup': setup.toJson(),
        'events': events.map((e) => e.toJson()).toList(),
        'recentCandles': recentCandles.map((c) => c.toJson()).toList(),
        'fingerprint': fingerprint,
      };
}

class SetupSummary {
  final String direction; // 'bullish' | 'bearish'
  final double score;     // confluence score from the engine
  final double zoneLower;
  final double zoneUpper;
  final bool priceApproaching;

  /// Calibration flags from the engine — the LLM uses these to discount
  /// confidence (e.g. 'chopZone' should pull confidence down by ~2 points).
  /// See LOCAL_LLM_INTEGRATION.md for the canonical list.
  final List<String> flags;

  const SetupSummary({
    required this.direction,
    required this.score,
    required this.zoneLower,
    required this.zoneUpper,
    required this.priceApproaching,
    required this.flags,
  });

  Map<String, dynamic> toJson() => {
        'direction': direction,
        'score': score,
        'zoneLower': zoneLower,
        'zoneUpper': zoneUpper,
        'priceApproaching': priceApproaching,
        'flags': flags,
      };
}

class EventSummary {
  /// One of: 'bullishFvg', 'bearishFvg', 'liquiditySweepBullish',
  /// 'liquiditySweepBearish', 'bullishBos', 'bearishBos'.
  final String type;
  final String direction; // 'bullish' | 'bearish'
  final double priceLevel;

  /// Age in candles relative to the latest candle in [recentCandles]. 0 means
  /// it formed on the current candle.
  final int ageCandles;

  const EventSummary({
    required this.type,
    required this.direction,
    required this.priceLevel,
    required this.ageCandles,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'direction': direction,
        'priceLevel': priceLevel,
        'ageCandles': ageCandles,
      };
}

class CandleSnapshot {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const CandleSnapshot({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
        't': timestamp.toIso8601String(),
        'o': open,
        'h': high,
        'l': low,
        'c': close,
        'v': volume,
      };
}
