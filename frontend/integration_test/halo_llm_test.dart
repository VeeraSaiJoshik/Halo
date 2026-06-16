import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:frontend/ai/local_llm/halo_llm.dart';
import 'package:frontend/ai/local_llm/llm_request.dart';
import 'package:frontend/ai/local_llm/local_llm.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late HaloLlm llm;

  setUpAll(() async {
    llm = HaloLlm();
    try {
      await llm.load();
      print('\n  Model loaded: ${llm.modelId}  isReady=${llm.isReady}');
    } on LlmLoadException catch (e) {
      fail('Model failed to load: $e\n'
          'Make sure the GGUF is at:\n'
          '  ~/Library/Application Support/com.example.frontend/models/halo-qwen1.5b-q4_k_m.gguf');
    }
  });

  tearDownAll(() => llm.dispose());

  LlmRequest _req({
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
  }) {
    final isBull = direction == 'bullish';
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
      events: [
        EventSummary(
          type: isBull ? 'bullishFvg' : 'bearishFvg',
          direction: direction,
          priceLevel: (zoneLower + zoneUpper) / 2,
          ageCandles: 1,
        ),
        EventSummary(
          type: isBull ? 'liquiditySweepBullish' : 'liquiditySweepBearish',
          direction: direction,
          priceLevel: isBull ? zoneLower - atr * 1.5 : zoneUpper + atr * 1.5,
          ageCandles: 14,
        ),
        EventSummary(
          type: isBull ? 'bullishBos' : 'bearishBos',
          direction: direction,
          priceLevel: isBull ? zoneLower : zoneUpper,
          ageCandles: 2,
        ),
      ],
      recentCandles: List.generate(
        20,
        (i) => CandleSnapshot(
          timestamp: DateTime.now().subtract(Duration(minutes: (20 - i) * 5)),
          open: currentPrice - 0.05,
          high: currentPrice + 0.12,
          low: currentPrice - 0.12,
          close: currentPrice,
          volume: 9000,
        ),
      ),
      fingerprint: 'integ-${symbol.toLowerCase()}-${direction[0]}',
    );
  }

  testWidgets('bearish AAPL — real model verdict', (tester) async {
    final req = _req(
      symbol: 'AAPL',
      direction: 'bearish',
      score: 4.8,
      zoneLower: 184.90,
      zoneUpper: 185.14,
      currentPrice: 184.72,
      atr: 0.31,
    );

    final v = await llm.generate(req);

    print('\n  ══ AAPL bearish (score 4.8) ══');
    print('  confidence : ${v.confidence}/10');
    print('  entry      : \$${v.entry.price.toStringAsFixed(2)}');
    print('  stop       : \$${v.invalidation.toStringAsFixed(2)}');
    print('  target     : \$${v.target.toStringAsFixed(2)}');
    print('  thesis     : ${v.thesis}');
    print('  risks      : ${v.keyRisks}');

    expect(v.direction, 'bearish');
    expect(v.confidence, inInclusiveRange(1, 10));
    expect(v.entry.price, inInclusiveRange(184.90, 185.14));
    expect(v.invalidation, greaterThan(185.14));
    expect(v.target, lessThan(184.72));
    expect(v.thesis.length, greaterThan(20));
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('bearish SPY — chopZone confidence penalty', (tester) async {
    final req = _req(
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

    print('\n  ══ SPY bearish (score 4.0, chopZone) ══');
    print('  confidence : ${v.confidence}/10');
    print('  thesis     : ${v.thesis}');

    expect(v.direction, 'bearish');
    expect(v.confidence, lessThanOrEqualTo(4));
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('bullish BTC — full confluence', (tester) async {
    final req = _req(
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

    print('\n  ══ BTC bullish 15m (score 5.2) ══');
    print('  confidence : ${v.confidence}/10');
    print('  entry      : \$${v.entry.price.toStringAsFixed(0)}');
    print('  stop       : \$${v.invalidation.toStringAsFixed(0)}');
    print('  target     : \$${v.target.toStringAsFixed(0)}');
    print('  thesis     : ${v.thesis}');
    print('  risks      : ${v.keyRisks}');

    expect(v.direction, 'bullish');
    expect(v.invalidation, lessThan(67800));
    expect(v.target, greaterThan(68240));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
