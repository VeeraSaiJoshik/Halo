import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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