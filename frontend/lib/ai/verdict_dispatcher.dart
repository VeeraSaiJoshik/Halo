import 'dart:async';

import '../controllers/NotificationController.dart';
import '../detection/asset_profile.dart';
import '../detection/confluence.dart';
import '../models/candle.dart';
import 'insight_repository.dart';
import 'local_reasoning_service.dart';
import 'setup_fingerprint.dart';
import 'verdict.dart';

/// Represents the lifecycle of an insight in the UI:
///
///   reasoning  → the local LLM is generating; sidebar shows a spinner
///   ready      → verdict returned and stored; sidebar shows full card
///   failed     → model failed (load error / generation error); sidebar shows hint
class InsightEvent {
  final String fingerprint;
  final String symbol;
  final String timeframe;
  final ScoredSetup setup;
  final Verdict? verdict;
  final InsightStatus status;
  final String? message;
  final DateTime createdAt;

  const InsightEvent({
    required this.fingerprint,
    required this.symbol,
    required this.timeframe,
    required this.setup,
    required this.verdict,
    required this.status,
    required this.createdAt,
    this.message,
  });
}

enum InsightStatus { reasoning, ready, failed }

/// Coordinates the flow: scored setup → local LLM reasoning → notification + stream.
///
/// Sits between the detection engine and the UI. The engine knows nothing
/// about the LLM or notifications; the UI knows nothing about scoring. Only
/// this class sees both sides.
///
/// This is the second dedup gate. The reasoning service cache prevents
/// re-running the model for the same fingerprint; this dispatcher keeps us
/// from even queueing work for a fingerprint we just dispatched.
class VerdictDispatcher {
  final LocalReasoningService service;
  final NotificationController notifications;
  final InsightRepository repository;
  final double triggerScore;

  final StreamController<InsightEvent> _controller =
      StreamController<InsightEvent>.broadcast();
  final Map<String, DateTime> _recentlyDispatched = {};
  final Duration dispatchCooldown;

  Stream<InsightEvent> get stream => _controller.stream;

  VerdictDispatcher({
    required this.service,
    required this.notifications,
    required this.repository,
    this.triggerScore = 3.5,
    this.dispatchCooldown = const Duration(minutes: 2),
  });

  /// Called per candle with the current scored setups from DetectionEngine.
  Future<void> handleSetups({
    required List<ScoredSetup> setups,
    required double atr,
    required double currentPrice,
    required AssetProfile profile,
    required List<Candle> recentCandles,
  }) async {
    if (setups.isEmpty) return;

    // Only the best candidate that qualifies per scan — we don't flood the
    // user with every marginal setup in the same scan.
    final qualifying = setups
        .where((s) => s.score >= triggerScore && s.priceApproaching)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (qualifying.isEmpty) return;

    for (final setup in qualifying.take(1)) {
      final fingerprint = SetupFingerprint.of(setup, atr: atr);

      // Cooldown: if we dispatched this fingerprint recently, skip. This is
      // the cheapest dedup — no network, no cache lookup, just a map check.
      final lastDispatched = _recentlyDispatched[fingerprint];
      if (lastDispatched != null &&
          DateTime.now().difference(lastDispatched) < dispatchCooldown) {
        continue;
      }
      _recentlyDispatched[fingerprint] = DateTime.now();

      _emit(InsightEvent(
        fingerprint: fingerprint,
        symbol: setup.symbol,
        timeframe: setup.timeframe,
        setup: setup,
        verdict: null,
        status: InsightStatus.reasoning,
        createdAt: DateTime.now(),
      ));

      final result = await service.request(
        setup: setup,
        atr: atr,
        currentPrice: currentPrice,
        assetProfile: profile.name,
        recentCandles: recentCandles,
      );

      await _handleResult(
        result: result,
        fingerprint: fingerprint,
        setup: setup,
      );
    }
  }

  Future<void> _handleResult({
    required VerdictResult result,
    required String fingerprint,
    required ScoredSetup setup,
  }) async {
    switch (result) {
      case VerdictSuccess(:final verdict):
        await repository.upsert(
          fingerprint: fingerprint,
          symbol: setup.symbol,
          timeframe: setup.timeframe,
          verdict: verdict,
          expiresAt: DateTime.now().add(const Duration(hours: 6)),
        );
        _emit(InsightEvent(
          fingerprint: fingerprint,
          symbol: setup.symbol,
          timeframe: setup.timeframe,
          setup: setup,
          verdict: verdict,
          status: InsightStatus.ready,
          createdAt: DateTime.now(),
        ));
        await notifications.postInsight(
          symbol: setup.symbol,
          timeframe: setup.timeframe,
          verdict: verdict,
          priceApproaching: setup.priceApproaching,
        );
      case VerdictFailed(:final reason):
        _emit(InsightEvent(
          fingerprint: fingerprint,
          symbol: setup.symbol,
          timeframe: setup.timeframe,
          setup: setup,
          verdict: null,
          status: InsightStatus.failed,
          message: reason,
          createdAt: DateTime.now(),
        ));
    }
  }

  void _emit(InsightEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
