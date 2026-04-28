import 'dart:async';

import '../detection/confluence.dart';
import '../models/candle.dart';
import 'local_llm/llm_request.dart';
import 'local_llm/local_llm.dart';
import 'setup_fingerprint.dart';
import 'verdict.dart';

/// Wraps a [LocalLlm] with the surrounding logic Halo needs:
///  - Fingerprint-based dedup so the same setup isn't re-reasoned every candle.
///  - In-flight coalescing so a burst of identical requests collapses to one.
///  - Lazy load — first request triggers [LocalLlm.load] if not yet ready.
///  - Error wrapping so the dispatcher gets a tagged result instead of an exception.
///
/// This used to be a remote proxy client. After moving to local-first, the
/// only thing that changed is what produces the [Verdict] — caching, dedup,
/// and result types are identical.
class LocalReasoningService {
  final LocalLlm _llm;
  final Duration dedupTtl;
  final Map<String, _CachedEntry> _cache = {};
  final Map<String, Future<VerdictResult>> _inFlight = {};

  LocalReasoningService({
    required LocalLlm llm,
    this.dedupTtl = const Duration(minutes: 30),
  }) : _llm = llm;

  /// Request a verdict for a scored setup. Returns a tagged [VerdictResult]
  /// so the dispatcher can branch on success / failure without try/catch.
  Future<VerdictResult> request({
    required ScoredSetup setup,
    required double atr,
    required double currentPrice,
    required String assetProfile,
    required List<Candle> recentCandles,
    List<String> flags = const [],
    bool forceRefresh = false,
  }) {
    final fingerprint = SetupFingerprint.of(setup, atr: atr);

    if (!forceRefresh) {
      final cached = _cache[fingerprint];
      if (cached != null && !cached.isExpired) {
        return Future.value(VerdictSuccess(cached.verdict, fromCache: true));
      }
    }

    final existing = _inFlight[fingerprint];
    if (existing != null) return existing;

    final future = _doRequest(
      setup: setup,
      atr: atr,
      currentPrice: currentPrice,
      assetProfile: assetProfile,
      recentCandles: recentCandles,
      fingerprint: fingerprint,
      flags: flags,
    ).whenComplete(() => _inFlight.remove(fingerprint));

    _inFlight[fingerprint] = future;
    return future;
  }

  Future<VerdictResult> _doRequest({
    required ScoredSetup setup,
    required double atr,
    required double currentPrice,
    required String assetProfile,
    required List<Candle> recentCandles,
    required String fingerprint,
    required List<String> flags,
  }) async {
    if (!_llm.isReady) {
      try {
        await _llm.load();
      } on LlmLoadException catch (e) {
        return VerdictFailed('model failed to load: ${e.message}');
      } catch (e) {
        return VerdictFailed('model failed to load: $e');
      }
    }

    final request = _buildRequest(
      setup: setup,
      atr: atr,
      currentPrice: currentPrice,
      assetProfile: assetProfile,
      recentCandles: recentCandles,
      fingerprint: fingerprint,
      flags: flags,
    );

    try {
      final verdict = await _llm.generate(request);
      _cache[fingerprint] = _CachedEntry(verdict, DateTime.now().add(dedupTtl));
      return VerdictSuccess(verdict, fromCache: false);
    } on LlmGenerationException catch (e) {
      return VerdictFailed('generation failed: ${e.message}');
    } catch (e) {
      return VerdictFailed('generation error: $e');
    }
  }

  LlmRequest _buildRequest({
    required ScoredSetup setup,
    required double atr,
    required double currentPrice,
    required String assetProfile,
    required List<Candle> recentCandles,
    required String fingerprint,
    required List<String> flags,
  }) {
    final direction =
        setup.dominantPattern.name.contains('ullish') ? 'bullish' : 'bearish';
    final bufferEnd =
        recentCandles.isNotEmpty ? recentCandles.last.timestamp : DateTime.now();
    final tfMinutes = _timeframeMinutes(setup.timeframe);

    final events = setup.events.map((e) {
      final ageMinutes = bufferEnd.difference(e.timestamp).inMinutes;
      final ageCandles = ageMinutes ~/ tfMinutes;
      return EventSummary(
        type: e.type.name,
        direction: e.type.name.contains('ullish') ? 'bullish' : 'bearish',
        priceLevel: e.priceLevel,
        ageCandles: ageCandles < 0 ? 0 : ageCandles,
      );
    }).toList();

    final candles = recentCandles.take(20).map((c) => CandleSnapshot(
          timestamp: c.timestamp,
          open: c.open,
          high: c.high,
          low: c.low,
          close: c.close,
          volume: c.volume,
        )).toList();

    return LlmRequest(
      symbol: setup.symbol,
      timeframe: setup.timeframe,
      assetProfile: assetProfile,
      currentPrice: currentPrice,
      atr: atr,
      setup: SetupSummary(
        direction: direction,
        score: setup.score,
        zoneLower: setup.zoneLower,
        zoneUpper: setup.zoneUpper,
        priceApproaching: setup.priceApproaching,
        flags: flags,
      ),
      events: events,
      recentCandles: candles,
      fingerprint: fingerprint,
    );
  }

  int _timeframeMinutes(String tf) {
    final match = RegExp(r'^(\d+)([mhd])$').firstMatch(tf);
    if (match == null) return 5;
    final n = int.parse(match.group(1)!);
    final u = match.group(2)!;
    return u == 'm' ? n : u == 'h' ? n * 60 : n * 1440;
  }

  Future<void> dispose() async {
    await _llm.dispose();
  }
}

class _CachedEntry {
  final Verdict verdict;
  final DateTime expiresAt;
  _CachedEntry(this.verdict, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ── Result types ────────────────────────────────────────────────────────────

sealed class VerdictResult {
  const VerdictResult();
}

class VerdictSuccess extends VerdictResult {
  final Verdict verdict;
  final bool fromCache;
  const VerdictSuccess(this.verdict, {required this.fromCache});
}

class VerdictFailed extends VerdictResult {
  final String reason;
  const VerdictFailed(this.reason);
}
