import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../ai/verdict.dart';

/// Fires OS-level desktop notifications for high-confidence trade insights.
///
/// Trigger rule (see SPRINT_3_DESIGN.md):
///   - verdict.confidence >= [minConfidence]
///   - setup.priceApproaching == true
///   - the ticker is not muted
///
/// Everything else goes silently to the sidebar panel.
class NotificationController {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Set<String> _mutedTickers = {};
  int minConfidence;
  bool _initialized = false;
  bool _unsupported = false;

  NotificationController({this.minConfidence = 7});

  Future<void> init() async {
    if (_initialized) return;
    if (!_platformSupported) {
      _unsupported = true;
      _initialized = true;
      return;
    }
    try {
      const macSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open Halo');
      const init = InitializationSettings(
        macOS: macSettings,
        linux: linuxSettings,
      );
      await _plugin.initialize(init);
      _initialized = true;
    } catch (_) {
      // If platform init fails for any reason, degrade gracefully. The sidebar
      // still shows insights — only OS popups are lost.
      _unsupported = true;
      _initialized = true;
    }
  }

  bool get _platformSupported => Platform.isMacOS || Platform.isLinux;

  void muteTicker(String symbol) => _mutedTickers.add(symbol);
  void unmuteTicker(String symbol) => _mutedTickers.remove(symbol);
  bool isMuted(String symbol) => _mutedTickers.contains(symbol);

  /// Returns true if a notification was posted.
  Future<bool> postInsight({
    required String symbol,
    required String timeframe,
    required Verdict verdict,
    required bool priceApproaching,
  }) async {
    if (!_initialized) await init();
    if (_unsupported) return false;
    if (verdict.confidence < minConfidence) return false;
    if (!priceApproaching) return false;
    if (_mutedTickers.contains(symbol)) return false;

    final arrow = verdict.isBullish ? '▲' : '▼';
    final title = '$arrow $symbol $timeframe · ${verdict.confidence}/10';
    final body = '${verdict.thesis}\nEntry ${verdict.entry.price.toStringAsFixed(2)} · '
        'Stop ${verdict.invalidation.toStringAsFixed(2)} · '
        'Target ${verdict.target.toStringAsFixed(2)}';

    const details = NotificationDetails(
      macOS: DarwinNotificationDetails(presentSound: true),
      linux: LinuxNotificationDetails(),
    );

    final id = _idFrom(symbol, timeframe);
    try {
      await _plugin.show(id, title, body, details, payload: '$symbol|$timeframe');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stable-but-compact id from symbol+timeframe so repeat posts replace
  /// rather than stack up.
  int _idFrom(String symbol, String timeframe) {
    final s = '$symbol|$timeframe';
    int h = 0;
    for (int i = 0; i < s.length; i++) {
      h = (h * 31 + s.codeUnitAt(i)) & 0x7fffffff;
    }
    return h;
  }
}
