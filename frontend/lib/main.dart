import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/settings.dart';
import 'package:frontend/pages/MainApp.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  SettingsHandler globalSettings = SettingsHandler();
  await globalSettings.initialize();

  runApp(ProviderScope(
    overrides: [settingsProvider.overrideWithValue(globalSettings)],
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