import 'package:flutter/material.dart';

enum HaloThemeType { aurum, terminal, meridian }

extension HaloThemeTypeExt on HaloThemeType {
  String get displayName {
    switch (this) {
      case HaloThemeType.aurum:
        return 'Aurum';
      case HaloThemeType.terminal:
        return 'Terminal';
      case HaloThemeType.meridian:
        return 'Meridian';
    }
  }

  String get tagline {
    switch (this) {
      case HaloThemeType.aurum:
        return 'Editorial Luxury';
      case HaloThemeType.terminal:
        return 'Technical Precision';
      case HaloThemeType.meridian:
        return 'Clean Swiss';
    }
  }
}

abstract class HaloThemeData {
  HaloThemeType get type;

  // Display — hero text, welcome screen titles
  TextStyle get displayLarge;
  TextStyle get displayMedium;

  // Headline — section titles, page headings
  TextStyle get headlineLarge;
  TextStyle get headlineMedium;

  // Title — prominent labels, button text
  TextStyle get titleLarge;
  TextStyle get titleMedium;

  // Body — main and secondary content
  TextStyle get bodyLarge;
  TextStyle get bodyMedium;

  // Label — uppercase tags, captions, URL bar, nav items
  TextStyle get labelLarge;
  TextStyle get labelSmall;

  // Ticker — prices, numbers, financial data (always monospace)
  TextStyle get ticker;
  TextStyle get tickerLarge;

  // Semantic text colors
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get textAccent;

  // Background color system — drives BackgroundGradientAnimation
  List<Color> get backgroundGradient; // 2-stop LinearGradient [start, end]
  List<Color> get blobColors;         // 4-6 ambient blob colors
  Color get glassOverlay;             // BackdropFilter container color (pre-opacity)
  double get blobOpacity;             // Radial gradient center opacity (0.0–1.0)
}
