import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/OnboardingPage.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/widgets/DevMenu.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  runApp(ProviderScope(
    child: MyApp(),
  ));

  WindowOptions windowOptions = const WindowOptions(
    backgroundColor: Colors.transparent,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden, 
      windowButtonVisibility: false
    );
    await windowManager.show();
    await windowManager.focus();
  });

}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener {
  bool _showDevMenu = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    windowManager.removeListener(this);
    super.dispose();
  }

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
  void onWindowEnterFullScreen() => setState(() => 
    ref.read(windowProvider.notifier).updateFullScreenStatus(true)
  );

  @override
  void onWindowLeaveFullScreen() => setState(() => 
    ref.read(windowProvider.notifier).updateFullScreenStatus(false)
  );

  @override
  Widget build(BuildContext context) {
    final windowContext = ref.watch(windowProvider);

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CustomColors.purple,
        ),
      ),
      home: ClipRRect(
        borderRadius: BorderRadius.circular(windowContext.isFullScreen ? 0 : 15),
        child: Scaffold(
          body: Stack(
            children: [
              HomePage(),
              if (_showDevMenu)
                DevMenu(
                  onClose: () => setState(() => _showDevMenu = false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}