import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/services/app_event_bus.dart';
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

    if (key == LogicalKeyboardKey.enter) {
      bus.emit(AppEvent.select);
      return true;
    }

    if (meta && key == LogicalKeyboardKey.keyW) {
      bus.emit(AppEvent.closeTab);
      return true;
    }
    if (meta && key == LogicalKeyboardKey.keyT) {
      bus.emit(AppEvent.openSearch);
      return true;
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
          body: HomePage(),
        ),
      ),
    );
  }
}