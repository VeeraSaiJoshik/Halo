import 'package:test/test.dart';

import 'package:frontend/ai/local_llm/echo_llm.dart';
import 'package:frontend/ai/local_llm/llm_request.dart';
import 'package:frontend/ai/verdict.dart';

// Builds a realistic LlmRequest the same way LocalReasoningService does.
LlmRequest _request({
  required String symbol,
  required String direction,
  required double score,
  required double zoneLower,
  required double zoneUpper,
  required double currentPrice,
  required double atr,
  String timeframe = '5m',
  String assetProfile = 'us_equities',
  List<String> flags = const [],
  List<EventSummary> events = const [],
}) {
  final mid = (zoneLower + zoneUpper) / 2;
  return LlmRequest(
    symbol: symbol,
    timeframe: timeframe,
    assetProfile: assetProfile,
    currentPrice: currentPrice,
    atr: atr,
    setup: SetupSummary(
      direction: direction,
      score: score,
      zoneLower: zoneLower,
      zoneUpper: zoneUpper,
      priceApproaching: true,
      flags: flags,
    ),
    events: events.isEmpty
        ? [
            EventSummary(
              type: direction == 'bullish' ? 'bullishFvg' : 'bearishFvg',
              direction: direction,
              priceLevel: mid,
              ageCandles: 1,
            ),
            EventSummary(
              type: direction == 'bullish'
                  ? 'liquiditySweepBullish'
                  : 'liquiditySweepBearish',
              direction: direction,
              priceLevel: direction == 'bullish'
                  ? zoneLower - atr * 1.5
                  : zoneUpper + atr * 1.5,
              ageCandles: 12,
            ),
            EventSummary(
              type: direction == 'bullish' ? 'bullishBos' : 'bearishBos',
              direction: direction,
              priceLevel: direction == 'bullish' ? zoneLower : zoneUpper,
              ageCandles: 2,
            ),
          ]
        : events,
    recentCandles: List.generate(
      20,
      (i) => CandleSnapshot(
        timestamp:
            DateTime.now().subtract(Duration(minutes: (20 - i) * 5)),
        open: currentPrice - 0.05,
        high: currentPrice + 0.12,
        low: currentPrice - 0.12,
        close: currentPrice,
        volume: 9000,
      ),
    ),
    fingerprint: 'test-${symbol.toLowerCase()}-${direction[0]}',
  );
}

void main() {
  late EchoLlm llm;

  setUp(() async {
    llm = EchoLlm();
    await llm.load();
  });

  tearDown(() => llm.dispose());

  test('bearish AAPL — clean high-score setup', () async {
    final req = _request(
      symbol: 'AAPL',
      direction: 'bearish',
      score: 4.8,
      zoneLower: 184.90,
      zoneUpper: 185.14,
      currentPrice: 184.72,
      atr: 0.31,
    );

    final v = await llm.generate(req);

    _verify(v, req);
    _print('AAPL bearish 4.8 (clean)', v);

    expect(v.confidence, 5); // floor(4.8)=4, score>=4.5 no flags → +1 = 5
  });

  test('bearish SPY — chopZone penalty', () async {
    final req = _request(
      symbol: 'SPY',
      direction: 'bearish',
      score: 4.0,
      zoneLower: 521.80,
      zoneUpper: 522.34,
      currentPrice: 521.18,
      atr: 0.88,
      flags: ['chopZone'],
    );

    final v = await llm.generate(req);

    _verify(v, req);
    _print('SPY bearish 4.0 (chopZone)', v);

    expect(v.confidence, 2); // floor(4.0)=4 − 2 = 2
  });

  test('bullish BTC — full confluence clean', () async {
    final req = _request(
      symbol: 'BTC',
      direction: 'bullish',
      score: 5.2,
      zoneLower: 67800,
      zoneUpper: 68100,
      currentPrice: 68240,
      atr: 312.50,
      timeframe: '15m',
      assetProfile: 'crypto',
    );

    final v = await llm.generate(req);

    _verify(v, req);
    _print('BTC bullish 5.2 (clean)', v);

    expect(v.confidence, 6); // floor(5.2)=5 + 1 bonus = 6
  });

  test('multi-flag degraded setup clamps to minimum', () async {
    final req = _request(
      symbol: 'AAPL',
      direction: 'bullish',
      score: 4.0,
      zoneLower: 186.10,
      zoneUpper: 186.35,
      currentPrice: 186.40,
      atr: 0.29,
      flags: ['chopZone', 'sameBarSweep', 'fastFill', 'counterTrend'],
    );

    final v = await llm.generate(req);

    _verify(v, req);
    _print('AAPL bullish 4.0 (all flags)', v);

    expect(v.confidence, 1); // floor(4)=4 − 2 − 1 − 1 − 1 = −1 → clamp to 1
    expect(v.keyRisks.length, greaterThanOrEqualTo(1));
  });

  test('full pipeline output — SPY bearish 5.5 full confluence', () async {
    final req = _request(
      symbol: 'SPY',
      direction: 'bearish',
      score: 5.5,
      zoneLower: 519.80,
      zoneUpper: 520.30,
      currentPrice: 519.30,
      atr: 0.92,
    );

    final v = await llm.generate(req);

    _verify(v, req);

    print('\n  ══════════════════════════════════════');
    print('  SPY 5m BEARISH — full pipeline output');
    print('  ══════════════════════════════════════');
    print('  confidence : ${v.confidence}/10');
    print('  entry      : \$${v.entry.price.toStringAsFixed(2)}  (zone ${v.entry.zoneLower}–${v.entry.zoneUpper})');
    print('  stop       : \$${v.invalidation.toStringAsFixed(2)}');
    print('  target     : \$${v.target.toStringAsFixed(2)}');
    print('  thesis     : ${v.thesis}');
    print('  risks      : ${v.keyRisks.join(' | ')}');
    print('  model      : ${v.modelId}');
    print('  ══════════════════════════════════════\n');

    expect(v.confidence, 6); // floor(5.5)=5, score>=4.5 no flags → +1 = 6
  });
}

void _verify(Verdict v, LlmRequest req) {
  final s = req.setup;
  final isBull = s.direction == 'bullish';

  expect(v.direction, s.direction);
  expect(v.confidence, inInclusiveRange(1, 10));
  expect(v.entry.price, inInclusiveRange(s.zoneLower, s.zoneUpper));
  if (isBull) {
    expect(v.invalidation, lessThan(s.zoneLower));
    expect(v.target, greaterThan(req.currentPrice));
  } else {
    expect(v.invalidation, greaterThan(s.zoneUpper));
    expect(v.target, lessThan(req.currentPrice));
  }
  expect(v.thesis, isNotEmpty);
  expect(v.modelId, 'echo-stub');
}

void _print(String label, Verdict v) {
  print('  [$label] conf=${v.confidence} '
      'entry=${v.entry.price.toStringAsFixed(2)} '
      'stop=${v.invalidation.toStringAsFixed(2)} '
      'target=${v.target.toStringAsFixed(2)}');
}
