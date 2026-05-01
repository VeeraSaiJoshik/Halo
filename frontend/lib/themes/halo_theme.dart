import 'package:flutter/material.dart';

enum HaloThemeType { golden, terminal, meridian, blue, green, pink, red }

extension HaloThemeTypeExt on HaloThemeType {
  String get displayName {
    switch (this) {
      case HaloThemeType.golden:
        return 'Golden';
      case HaloThemeType.terminal:
        return 'Terminal';
      case HaloThemeType.meridian:
        return 'Meridian';
      case HaloThemeType.blue:
        return 'Blue';
      case HaloThemeType.green:
        return 'Green';
      case HaloThemeType.pink:
        return 'Pink';
      case HaloThemeType.red:
        return 'Red';
    }
  }

  String get tagline {
    switch (this) {
      case HaloThemeType.golden:
        return 'Liquid Gold';
      case HaloThemeType.terminal:
        return 'Technical Precision';
      case HaloThemeType.meridian:
        return 'Clean Swiss';
      case HaloThemeType.blue:
        return 'Deep Sapphire';
      case HaloThemeType.green:
        return 'Emerald Forest';
      case HaloThemeType.pink:
        return 'Rose Bloom';
      case HaloThemeType.red:
        return 'Crimson Fire';
    }
  }

  Color get previewAccent {
    switch (this) {
      case HaloThemeType.golden:
        return const Color(0xFFF59E0B);
      case HaloThemeType.terminal:
        return const Color(0xFF00D97A);
      case HaloThemeType.meridian:
        return const Color(0xFF3B82F6);
      case HaloThemeType.blue:
        return const Color(0xFF60A5FA);
      case HaloThemeType.green:
        return const Color(0xFF34D399);
      case HaloThemeType.pink:
        return const Color(0xFFF472B6);
      case HaloThemeType.red:
        return const Color(0xFFF87171);
    }
  }
}

HaloThemeType parseString(String theme) {
  switch(theme) {
    case 'Golden':
      return HaloThemeType.golden;
    case 'Terminal':
      return HaloThemeType.terminal;
    case 'Meridian':
      return HaloThemeType.meridian;
    case 'Blue':
      return HaloThemeType.blue;
    case 'Green':
      return HaloThemeType.green;
    case 'Pink':
      return HaloThemeType.pink;
    case 'Red':
      return HaloThemeType.red;
  }

  return HaloThemeType.golden;
}

abstract class HaloThemeData {
  HaloThemeType get type;
 
  TextStyle get displayLarge;
  TextStyle get displayMedium;
 
  TextStyle get headlineLarge;
  TextStyle get headlineMedium;

  TextStyle get titleLarge;
  TextStyle get titleMedium;

  TextStyle get bodyLarge;
  TextStyle get bodyMedium;

  TextStyle get labelLarge;
  TextStyle get labelSmall;

  TextStyle get ticker;
  TextStyle get tickerLarge;

  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get textAccent;

  List<Color> get backgroundGradient;
  List<Color> get blobColors;
  Color get glassOverlay;
  double get blobOpacity;
  Color get accentColor;
  Color get whiteColor;
  Color get backgroundColor;
  Color get primaryColor;
}
