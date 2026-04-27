import 'package:test/test.dart';

import 'package:frontend/ai/local_llm/echo_llm.dart';
import 'package:frontend/ai/local_llm/llm_request.dart';

LlmRequest _request({
  required String direction,
  required double score,
  List<String> flags = const [],
  double zoneLower = 100,
  double zoneUpper = 102,
  double currentPrice = 101,
  double atr = 1.0,
}) {
  return LlmRequest(
    symbol: 'TEST',
    timeframe: '5m',
    assetProfile: 'us_equities',
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
    events: const [],
    recentCandles: const [],
    fingerprint: 'fp-test',
  );
}

void main() {
  group('EchoLlm', () {
    test('load is idempotent and isReady reflects state', () async {
      final llm = EchoLlm();
      expect(llm.isReady, isFalse);
      await llm.load();
      expect(llm.isReady, isTrue);
      await llm.load();
      expect(llm.isReady, isTrue);
      await llm.dispose();
      expect(llm.isReady, isFalse);
    });

    test('verdict direction matches setup direction', () async {
      final llm = EchoLlm();
      await llm.load();
      final bull = await llm.generate(_request(direction: 'bullish', score: 4.0));
      final bear = await llm.generate(_request(direction: 'bearish', score: 4.0));
      expect(bull.direction, 'bullish');
      expect(bear.direction, 'bearish');
    });

    test('chopZone flag drops confidence by 2', () async {
      final llm = EchoLlm();
      await llm.load();
      // Use score 4.0 so the +1 bonus doesn't apply to either case — isolates
      // the chopZone penalty from the clean-bonus.
      final clean = await llm.generate(_request(direction: 'bearish', score: 4.0));
      final chop = await llm.generate(
        _request(direction: 'bearish', score: 4.0, flags: ['chopZone']));
      expect(chop.confidence, equals(clean.confidence - 2));
    });

    test('clean high-score setup gets the +1 bonus', () async {
      final llm = EchoLlm();
      await llm.load();
      final v = await llm.generate(_request(direction: 'bullish', score: 5.0));
      // floor(5.0)=5 then +1 bonus = 6
      expect(v.confidence, 6);
    });

    test('confidence clamps to [1, 10]', () async {
      final llm = EchoLlm();
      await llm.load();
      final crushed = await llm.generate(_request(
        direction: 'bullish',
        score: 4.0,
        flags: ['chopZone', 'sameBarSweep', 'fastFill', 'counterTrend'],
      ));
      expect(crushed.confidence, greaterThanOrEqualTo(1));
      final boosted = await llm.generate(
        _request(direction: 'bullish', score: 9.5));
      expect(boosted.confidence, lessThanOrEqualTo(10));
    });

    test('bearish entry zone matches input zone', () async {
      final llm = EchoLlm();
      await llm.load();
      final v = await llm.generate(_request(
        direction: 'bearish',
        score: 4.0,
        zoneLower: 259.40,
        zoneUpper: 259.56,
      ));
      expect(v.entry.zoneLower, 259.40);
      expect(v.entry.zoneUpper, 259.56);
      expect(v.entry.price, closeTo(259.48, 0.001));
    });

    test('bearish invalidation is above the zone', () async {
      final llm = EchoLlm();
      await llm.load();
      final v = await llm.generate(_request(
        direction: 'bearish',
        score: 4.0,
        zoneLower: 100,
        zoneUpper: 102,
        atr: 0.5,
      ));
      expect(v.invalidation, greaterThan(102));
    });

    test('modelId surfaces correctly', () async {
      final llm = EchoLlm();
      await llm.load();
      final v = await llm.generate(_request(direction: 'bullish', score: 4.0));
      expect(v.modelId, 'echo-stub');
      expect(llm.modelId, 'echo-stub');
    });
  });
}
