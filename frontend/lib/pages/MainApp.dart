import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/browser/navigation_key.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/models/settings.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/OnboardingPage.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/DevMenu.dart';
import 'package:window_manager/window_manager.dart';

final settingsProvider = Provider<SettingsHandler>((ref) => throw UnimplementedError());

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener {
  Widget? startingWidget;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    
    print(ref.read(settingsProvider).theme);
    if(ref.read(settingsProvider).theme != null) {
      ref.read(haloThemeTypeProvider.notifier).state = ref.read(settingsProvider).theme!;
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
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
    final globalSettings = ref.read(settingsProvider);
    Widget content = globalSettings.onboardingFlag() ? OnboardingPage() : HomePage();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CustomColors.purple,
        ),
      ),
      routes: {
        "/homePage": (ctx) => HomePage()
      },
      home: content
    );
  }
}