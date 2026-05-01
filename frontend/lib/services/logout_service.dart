import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:frontend/models/settings.dart';
import 'package:frontend/models/transitions.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/OnboardingPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> logoutAndReset(BuildContext context, SettingsHandler settings) async {
  final cookieManager = CookieManager.instance();
  await cookieManager.deleteAllCookies();

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  settings.buyingPlatform = null;
  settings.chartingPlatform = null;
  settings.theme = null;

  if (!context.mounted) return;
  Navigator.of(context).pop();
  Navigator.of(context).push(createCustomRoute(OnboardingPage()));
}
