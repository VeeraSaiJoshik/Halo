import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/engine/mouse_detection/MouseRegionEngine.dart';
import 'package:frontend/engine/mouse_detection/customMouseRegion.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/pages/BodyPage.dart';
import 'package:frontend/pages/TitleBar.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/widgets/DevMenu.dart';
import 'package:frontend/widgets/OverlayWidgets/AddSubSection.dart';
import 'package:frontend/widgets/background_gradient_animation.dart';
import 'package:frontend/widgets/searchBar.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _showDevMenu = false;
  GlobalKey<CustomSearchBarState> searchBarKey = GlobalKey();
  late StreamSubscription<AppEvent> _sub;

  bool _searchActive = false;

  /// Returns true to consume the event (prevents further propagation).
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final meta = HardwareKeyboard.instance.isMetaPressed;
    final key  = event.logicalKey;
    final bus  = ref.read(appEventBusProvider);

    print("Key pressed: ${event.logicalKey.debugName}, meta: $meta");

    if (key == LogicalKeyboardKey.escape && _showDevMenu) {
      setState(() => _showDevMenu = false);
      return true;
    }

    if (meta && key == LogicalKeyboardKey.keyD) {
      setState(() => _showDevMenu = !_showDevMenu);
      return true;
    }

    if (key == LogicalKeyboardKey.enter) {
      bus.emit(AppEvent.select);
      return true;
    }

    if (meta && key == LogicalKeyboardKey.keyG) {
      bus.emit(AppEvent.graphView);
      print("Graph View event emitted");
      return true;
    }
    if (meta && key == LogicalKeyboardKey.keyB) {
      bus.emit(AppEvent.portalView);
      return true;
    }
    if (meta && key == LogicalKeyboardKey.keyN) {
      bus.emit(AppEvent.toggleNotificaitonView);
      return true;
    }
    if (meta && key == LogicalKeyboardKey.keyT) {
      bus.emit(AppEvent.openSearch);
      return true;
    }

    const tabKeys = [
      LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5, LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7, LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    if (meta) {
      final tabIndex = tabKeys.indexOf(key);
      if (tabIndex != -1) {
        bus.emitTabSwitch(tabIndex);
        return true;
      }
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      bus.emit(AppEvent.moveDown);
      return true;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      bus.emit(AppEvent.moveUp);
      return true;
    }

    return false;
  }



  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);

    _sub = ref.read(appEventBusProvider).stream.listen((event) {
      if (event == AppEvent.searchClosed) {
        print("the search has been closed");
        setState(() => _searchActive = false);
      } else if (event == AppEvent.searchOpened) {
        setState(() => _searchActive = true);
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appControllerProvider);
    final windowContext = ref.watch(windowProvider);
    
    return Scaffold(
      body: ClipRRect(
        borderRadius: BorderRadius.circular(windowContext.isFullScreen ? 0 : 15),
        child: Container(
          decoration: const BoxDecoration(
            color: CustomColors.primary,
          ),
          width: double.infinity,
          child: BackgroundGradientAnimation(
            child: Stack(
              children: [
                Column(
                  children: [
                    TitleBar(),
                    Expanded(
                      child: BodyPageDart()
                    )
                  ],
                ),
                if (_searchActive)
                  Positioned.fill(
                    child: InkWell(
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () => ref.read(appEventBusProvider).emit(AppEvent.openSearch),
                      child: Container(width: double.infinity, height: double.infinity, color: Colors.black.withOpacity(0.5)),
                    ),
                  ),
                Positioned(
                  left: 0, right: 0, top: MediaQuery.of(context).size.height * 0.45,
                  child: Center(
                    child: CustomSearchBar(
                      key: searchBarKey,
                    ),
                  ),
                ),
                if (_showDevMenu)
                  DevMenu(
                    onClose: () => setState(() => _showDevMenu = false),
                  ),
                MouseRegionEngine(regions: regions, debug: false,),
              ],
            )
          ),
        ),
      ),
    );
  }
}
