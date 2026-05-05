/// Structured response returned by the local LLM after analyzing a setup.
///
/// This shape is the contract between the LLM (whatever your partner picks —
/// llama.cpp, ggml, ONNX runtime, etc.) and the rest of Halo. The LLM does
/// not need to know about Halo's internals; it only needs to produce a JSON
/// object matching the schema documented in `docs/LOCAL_LLM_INTEGRATION.md`.
class Verdict {
  final String direction; // 'bullish' | 'bearish'
  final int confidence;   // 1-10
  final EntryPlan entry;
  final double invalidation;
  final double target;
  final String thesis;
  final List<String> keyRisks;
  final DateTime generatedAt;

  /// Free-form identifier the LLM implementation can use to mark which model
  /// produced the verdict ("llama-3.2-3b-q4", "phi-3-mini", "echo-stub", …).
  /// Useful for debugging and showing model attribution in the UI.
  final String modelId;

  /// True when this verdict came from the in-memory dedup cache rather than
  /// a fresh LLM run. Lets the UI show a "(cached)" hint if it wants.
  final bool cached;

  const Verdict({
    required this.direction,
    required this.confidence,
    required this.entry,
    required this.invalidation,
    required this.target,
    required this.thesis,
    required this.keyRisks,
    required this.generatedAt,
    required this.modelId,
    required this.cached,
  });

  bool get isBullish => direction == 'bullish';

  factory Verdict.fromJson(Map<String, dynamic> json) {
    return Verdict(
      direction: json['direction'] as String,
      confidence: (json['confidence'] as num).toInt(),
      entry: EntryPlan.fromJson(json['entry'] as Map<String, dynamic>),
      invalidation: (json['invalidation'] as num).toDouble(),
      target: (json['target'] as num).toDouble(),
      thesis: json['thesis'] as String,
      keyRisks: (json['keyRisks'] as List).map((e) => e.toString()).toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      modelId: json['modelId'] as String? ?? 'unknown',
      cached: json['cached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'direction': direction,
        'confidence': confidence,
        'entry': entry.toJson(),
        'invalidation': invalidation,
        'target': target,
        'thesis': thesis,
        'keyRisks': keyRisks,
        'generatedAt': generatedAt.toIso8601String(),
        'modelId': modelId,
        'cached': cached,
      };
}

class EntryPlan {
  final String type; // 'limit' | 'market' | 'stop'
  final double price;
  final double zoneLower;
  final double zoneUpper;

  const EntryPlan({
    required this.type,
    required this.price,
    required this.zoneLower,
    required this.zoneUpper,
  });

  factory EntryPlan.fromJson(Map<String, dynamic> json) {
    final zone = (json['zone'] as List).map((e) => (e as num).toDouble()).toList();
    return EntryPlan(
      type: json['type'] as String,
      price: (json['price'] as num).toDouble(),
      zoneLower: zone.isNotEmpty ? zone[0] : 0,
      zoneUpper: zone.length > 1 ? zone[1] : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'price': price,
        'zone': [zoneLower, zoneUpper],
      };
}
