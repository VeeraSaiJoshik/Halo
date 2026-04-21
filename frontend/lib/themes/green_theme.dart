import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'halo_theme.dart';

class GreenTheme implements HaloThemeData {
  const GreenTheme();

  // ─── Semantic text colors ─────────────────────────────────────────────────

  @override
  Color get textPrimary => const Color(0xFFF8FAFC);

  @override
  Color get textSecondary => const Color(0xFF94A3B8);

  @override
  Color get textMuted => const Color(0xFF475569);

  @override
  Color get textAccent => const Color(0xFF34D399); // emerald-400

  // ─── Theme identity ───────────────────────────────────────────────────────

  @override
  HaloThemeType get type => HaloThemeType.green;

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
        Color(0xFF002B16), // deep forest green
        Color(0xFF000E07), // near-black with green hue
      ];

  @override
  List<Color> get blobColors => const [
    Color(0xFF10B981), // emerald-500 — vivid emerald
    Color(0xFF059669), // emerald-600 — deep forest
    Color(0xFF22C55E), // green-500   — bright green
    Color(0xFF34D399), // emerald-400 — light shimmer
    Color(0xFF14B8A6), // teal-500    — teal accent
    Color(0xFF4ADE80), // green-400   — neon highlight
  ];

  @override
  Color get glassOverlay => const Color(0xFF000805).withValues(alpha: 0.48);

  @override
  double get blobOpacity => 0.50;

  @override
  Color get accentColor => const Color(0xFF10B981);

  @override
  Color get whiteColor => const Color(0xFFD1FAE5);
}
