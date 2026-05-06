import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/ai/ai_providers.dart';
import 'package:frontend/controllers/AppController.dart';
import 'package:frontend/controllers/DataIntakeController.dart';
import 'package:frontend/engine/clients/alpaca_client.dart';
import 'package:frontend/engine/clients/binance_client.dart';
import 'package:frontend/engine/clients/finnhub_client.dart';
import 'package:frontend/models/settings.dart';
import 'package:frontend/services/app_event_bus.dart';

class WindowParams {
  bool isFullScreen;

  WindowParams({this.isFullScreen = true});
}

class WindowNotifier extends StateNotifier<WindowParams>{
  WindowNotifier(): super(WindowParams());

  void updateFullScreenStatus(bool isFullScreen) {
    state.isFullScreen = isFullScreen;
  }
}

final windowProvider = StateNotifierProvider<WindowNotifier, WindowParams>(
  (ref) => WindowNotifier()
);

/// Single app-wide event bus.  Widgets read this to emit or subscribe.
final appEventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final appControllerProvider = ChangeNotifierProvider<AppController>(
  (ref) {
    return AppController();
  }
);

/// Holds the singleton [SettingsHandler]. The real instance is supplied at
/// app launch via `settingsProvider.overrideWithValue(...)` in `main.dart`,
/// after `SettingsHandler.initialize()` has loaded persisted state.
final settingsProvider = Provider<SettingsHandler>(
  (ref) => throw UnimplementedError(),
);

