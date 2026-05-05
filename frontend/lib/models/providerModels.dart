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

final intakeServiceProvider = Provider<IntakeService>((ref) {
  final eventBus = ref.read(appEventBusProvider);

  final alpacaClient = AlpacaClient(
    apiKey: const String.fromEnvironment("ALPACA_API_KEY"), 
    secretKey: const String.fromEnvironment("ALPACA_API_SECRET")
  );
  final binanceClient = BinanceClient();
  final finnhubClient = FinnhubClient(apiKey: String.fromEnvironment("FINNHUB_API_KEY"));

  final intakeService = IntakeService(
    eventBus: eventBus,
    alpacaClient: alpacaClient,
    binanceClient: binanceClient,
    finnhubClient: finnhubClient
  );
  intakeService.verdictDispatcher = ref.read(verdictDispatcherProvider);

  ref.onDispose(() => intakeService.dispose());

  return intakeService;
});

final appControllerProvider = ChangeNotifierProvider<AppController>(
  (ref) {
    final intakeService = ref.read(intakeServiceProvider);
    return AppController(intakeEngine: intakeService);
  }
);

/// Holds the singleton [SettingsHandler]. The real instance is supplied at
/// app launch via `settingsProvider.overrideWithValue(...)` in `main.dart`,
/// after `SettingsHandler.initialize()` has loaded persisted state.
final settingsProvider = Provider<SettingsHandler>(
  (ref) => throw UnimplementedError(),
);

