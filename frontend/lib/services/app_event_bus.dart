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

  newNotifcation, graphView, portalView, toggleNotificaitonView,
}

/// Broadcast stream bus.  One instance lives for the lifetime of the app,
/// provided via [appEventBusProvider].  Emit with [emit]; listen via [stream].
class AppEventBus {
  final _controller = StreamController<AppEvent>.broadcast();
  final _tabSwitch  = StreamController<int>.broadcast();

  Stream<AppEvent> get stream         => _controller.stream;
  /// Emits a 0-based tab index when the user presses ⌘+1…9.
  Stream<int>      get tabSwitchStream => _tabSwitch.stream;

  void emit(AppEvent event)    => _controller.add(event);
  void emitTabSwitch(int index) => _tabSwitch.add(index);

  void dispose() {
    _controller.close();
    _tabSwitch.close();
  }
}
