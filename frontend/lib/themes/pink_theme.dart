import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'halo_theme.dart';

class PinkTheme implements HaloThemeData {
  const PinkTheme();

  // ─── Semantic text colors ─────────────────────────────────────────────────

  @override
  Color get textPrimary => const Color(0xFFF8FAFC);

  @override
  Color get textSecondary => const Color(0xFF94A3B8);

  @override
  Color get textMuted => const Color(0xFF475569);

  @override
  Color get textAccent => const Color(0xFFF472B6); // pink-400

  // ─── Theme identity ───────────────────────────────────────────────────────

  @override
  HaloThemeType get type => HaloThemeType.pink;

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
        Color(0xFF2D0020), // deep magenta-rose
        Color(0xFF160010), // near-black with pink hue
      ];

  @override
  List<Color> get blobColors => const [
    Color(0xFFEC4899), // pink-500    — vivid rose
    Color(0xFFF43F5E), // rose-500    — electric red-pink
    Color(0xFFF472B6), // pink-400    — light shimmer
    Color(0xFFD946EF), // fuchsia-500 — electric fuchsia
    Color(0xFFFB7185), // rose-400    — soft coral
    Color(0xFFDB2777), // pink-600    — deep magenta
  ];

  @override
  Color get glassOverlay => const Color(0xFF0D0008).withValues(alpha: 0.48);

  @override
  double get blobOpacity => 0.50;

  @override
  Color get accentColor => const Color(0xFFF080C0);

  @override
  Color get whiteColor => const Color(0xFFFCE7F3);

  @override
  Color get backgroundColor => const Color(0xFF0D0009);
}
