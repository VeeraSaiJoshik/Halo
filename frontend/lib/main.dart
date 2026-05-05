import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/settings.dart';
import 'package:frontend/pages/MainApp.dart';
import 'package:frontend/ai/ai_providers.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/OnboardingPage.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/browser/navigation_key.dart';
import 'package:frontend/widgets/DevMenu.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  SettingsHandler globalSettings = SettingsHandler();
  await globalSettings.initialize();

  final container = ProviderContainer();
  await container.read(insightRepositoryProvider).init();

  runApp(UncontrolledProviderScope(
    container: container,
    child: ProviderScope(
      overrides: [settingsProvider.overrideWithValue(globalSettings)],
      child: MyApp()
    ),
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