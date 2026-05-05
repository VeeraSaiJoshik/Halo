import 'package:test/test.dart';

import 'package:frontend/ai/setup_fingerprint.dart';
import 'package:frontend/detection/confluence.dart';

ScoredSetup _setup({
  required String symbol,
  required String tf,
  required PatternType pattern,
  required double zoneLower,
  required double zoneUpper,
  required double score,
  bool approaching = true,
}) {
  return ScoredSetup(
    events: const [],
    score: score,
    symbol: symbol,
    timeframe: tf,
    dominantPattern: pattern,
    zoneUpper: zoneUpper,
    zoneLower: zoneLower,
    priceApproaching: approaching,
  );
}

void main() {
  group('SetupFingerprint', () {
    test('same zone + same score bucket → same fingerprint', () {
      final a = _setup(
        symbol: 'AAPL', tf: '5m', pattern: PatternType.bearishFvg,
        zoneLower: 259.40, zoneUpper: 259.56, score: 4.5,
      );
      final b = _setup(
        symbol: 'AAPL', tf: '5m', pattern: PatternType.bearishFvg,
        zoneLower: 259.42, zoneUpper: 259.55, score: 4.7,
      );
      expect(SetupFingerprint.of(a, atr: 0.30),
          equals(SetupFingerprint.of(b, atr: 0.30)));
    });

    test('different score bucket → different fingerprint', () {
      final a = _setup(
        symbol: 'AAPL', tf: '5m', pattern: PatternType.bearishFvg,
        zoneLower: 259.40, zoneUpper: 259.56, score: 3.9,
      );
      final b = _setup(
        symbol: 'AAPL', tf: '5m', pattern: PatternType.bearishFvg,
        zoneLower: 259.40, zoneUpper: 259.56, score: 4.5,
      );
      expect(SetupFingerprint.of(a, atr: 0.30),
          isNot(equals(SetupFingerprint.of(b, atr: 0.30))));
    });

    test('different symbol → different fingerprint', () {
      final a = _setup(
        symbol: 'AAPL', tf: '5m', pattern: PatternType.bearishFvg,
        zoneLower: 259.40, zoneUpper: 259.56, score: 4.5,
      );
      final b = _setup(
        symbol: 'SPY', tf: '5m', pattern: PatternType.bearishFvg,
        zoneLower: 259.40, zoneUpper: 259.56, score: 4.5,
      );
      expect(SetupFingerprint.of(a, atr: 0.30),
          isNot(equals(SetupFingerprint.of(b, atr: 0.30))));
    });

    test('different direction → different fingerprint', () {
      final a = _setup(
        symbol: 'AAPL', tf: '5m', pattern: PatternType.bearishFvg,
        zoneLower: 259.40, zoneUpper: 259.56, score: 4.5,
      );
      final b = _setup(
        symbol: 'AAPL', tf: '5m', pattern: PatternType.bullishFvg,
        zoneLower: 259.40, zoneUpper: 259.56, score: 4.5,
      );
      expect(SetupFingerprint.of(a, atr: 0.30),
          isNot(equals(SetupFingerprint.of(b, atr: 0.30))));
    });

    test('zero atr does not crash', () {
      final s = _setup(
        symbol: 'AAPL', tf: '5m', pattern: PatternType.bearishFvg,
        zoneLower: 259.40, zoneUpper: 259.56, score: 4.5,
      );
      expect(() => SetupFingerprint.of(s, atr: 0), returnsNormally);
    });
  });
}
