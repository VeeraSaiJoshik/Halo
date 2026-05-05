import '../verdict.dart';
import 'llm_request.dart';
import 'local_llm.dart';

/// No-op LLM stub that produces a deterministic verdict from the request alone.
/// Used during development so the dispatcher, repository, sidebar, and
/// notifications all run end-to-end without a real model packaged in yet.
///
/// Replace this with your partner's real implementation once their model is
/// ready. The interface stays the same; just swap the provider in
/// [aiProviders].
///
/// The "reasoning" here is purely mechanical:
///   - confidence = floor(score), clamped 1..10
///   - confidence -= 2 if 'chopZone' flag present
///   - confidence -= 1 if 'sameBarSweep' or 'fastFill' or 'counterTrend' present
///   - direction always matches the setup
///   - entry price = midpoint of the zone
///   - invalidation = upper bound + 1 ATR (bearish) / lower bound - 1 ATR (bullish)
///   - target = 2 ATR away in setup direction
class EchoLlm implements LocalLlm {
  @override
  String get modelId => 'echo-stub';

  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> load() async {
    _ready = true;
  }

  @override
  Future<Verdict> generate(LlmRequest request) async {
    final s = request.setup;
    int confidence = s.score.floor();
    if (s.flags.contains('chopZone')) confidence -= 2;
    if (s.flags.contains('sameBarSweep')) confidence -= 1;
    if (s.flags.contains('fastFill')) confidence -= 1;
    if (s.flags.contains('counterTrend')) confidence -= 1;
    if (s.score >= 4.5 && s.flags.isEmpty) confidence += 1;
    confidence = confidence.clamp(1, 10);

    final isBull = s.direction == 'bullish';
    final mid = (s.zoneLower + s.zoneUpper) / 2;
    final invalidation = isBull
        ? s.zoneLower - request.atr
        : s.zoneUpper + request.atr;
    final target = isBull
        ? request.currentPrice + request.atr * 2
        : request.currentPrice - request.atr * 2;

    return Verdict(
      direction: s.direction,
      confidence: confidence,
      entry: EntryPlan(
        type: 'limit',
        price: mid,
        zoneLower: s.zoneLower,
        zoneUpper: s.zoneUpper,
      ),
      invalidation: invalidation,
      target: target,
      thesis:
          'Stub verdict: ${s.direction} setup at ${request.symbol} '
          'with score ${s.score.toStringAsFixed(1)}. '
          'Real reasoning will arrive once the local model is wired in.',
      keyRisks: [
        if (s.flags.contains('chopZone')) 'Zone sits in congestion',
        if (s.flags.contains('sameBarSweep')) 'Sweep and FVG formed on same candle',
        if (s.flags.contains('counterTrend')) 'Setup opposes recent BOS trend',
      ],
      generatedAt: DateTime.now(),
      modelId: modelId,
      cached: false,
    );
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
