import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'halo_theme.dart';

class BlueTheme implements HaloThemeData {
  const BlueTheme();

  // ─── Semantic text colors ─────────────────────────────────────────────────

  @override
  Color get textPrimary => const Color(0xFFF8FAFC);

  @override
  Color get textSecondary => const Color(0xFF94A3B8);

  @override
  Color get textMuted => const Color(0xFF475569);

  @override
  Color get textAccent => const Color(0xFF60A5FA); // blue-400

  // ─── Theme identity ───────────────────────────────────────────────────────

  @override
  HaloThemeType get type => HaloThemeType.blue;

  // ─── Display ─────────────────────────────────────────────────────────────

  @override
  TextStyle get displayLarge => GoogleFonts.instrumentSerif(
        fontSize: 66,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
        color: textPrimary,
      );

  @override
  TextStyle get displayMedium => GoogleFonts.instrumentSerif(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.1,
        color: textPrimary,
      );

  // ─── Headline ─────────────────────────────────────────────────────────────

  @override
  TextStyle get headlineLarge => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.2,
        color: textPrimary,
      );

  @override
  TextStyle get headlineMedium => GoogleFonts.playfairDisplay(
        fontSize: 25,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.3,
        color: textPrimary,
      );

  // ─── Title ────────────────────────────────────────────────────────────────

  @override
  TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: textPrimary,
      );

  @override
  TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.4,
        color: textPrimary,
      );

  // ─── Body ─────────────────────────────────────────────────────────────────

  @override
  TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.6,
        color: textSecondary,
      );

  @override
  TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.6,
        color: textSecondary,
      );

  // ─── Label ────────────────────────────────────────────────────────────────

  @override
  TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        height: 1.2,
        color: textMuted,
      );

  @override
  TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        height: 1.2,
        color: textMuted,
      );

  // ─── Ticker ───────────────────────────────────────────────────────────────

  @override
  TextStyle get ticker => GoogleFonts.jetBrainsMono(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.3,
        color: textPrimary,
      );

  @override
  TextStyle get tickerLarge => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
        color: textAccent,
      );

  // ─── Background color system ─────────────────────────────────────────────

  @override
  List<Color> get backgroundGradient => const [
        Color(0xFF001535), // deep navy
        Color(0xFF000A1C), // near-black with blue hue
      ];

  @override
  List<Color> get blobColors => const [
    Color(0xFF3B82F6), // blue-500  — vivid sapphire
    Color(0xFF2563EB), // blue-600  — deep cobalt
    Color(0xFF6366F1), // indigo-500 — electric indigo
    Color(0xFF60A5FA), // blue-400  — sky shimmer
    Color(0xFF818CF8), // indigo-400 — soft violet-blue
    Color(0xFF0EA5E9), // sky-500   — cyan highlight
  ];

  @override
  Color get glassOverlay => const Color(0xFF000410).withValues(alpha: 0.48);

  @override
  double get blobOpacity => 0.50;

  @override
  Color get accentColor => const Color(0xFF4D94FF);

  @override
  Color get whiteColor => const Color(0xFFDCE9FF);
}
