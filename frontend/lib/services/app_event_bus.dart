import 'dart:async';

/// All macro events that can be emitted application-wide.
/// Add new values here to introduce new shortcuts.
enum AppEvent {
  newTab,
  closeTab,
  openSearch,
  moveUp, 
  moveDown, 
  select, 
  searchClosed, 
  searchOpened,

  leftAdd, 
  rightAdd,
}

/// Broadcast stream bus.  One instance lives for the lifetime of the app,
/// provided via [appEventBusProvider].  Emit with [emit]; listen via [stream].
class AppEventBus {
  final _controller = StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void emit(AppEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}
