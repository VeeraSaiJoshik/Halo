import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'halo_theme.dart';

class TerminalTheme implements HaloThemeData {
  // ── Semantic text colors ──────────────────────────────────────────────────

  @override
  Color get textPrimary => const Color(0xFFE2E8F0);

  @override
  Color get textSecondary => const Color(0xFF64748B);

  @override
  Color get textMuted => const Color(0xFF334155);

  @override
  Color get textAccent => const Color(0xFF00D97A);

  // ── Theme identity ────────────────────────────────────────────────────────

  @override
  HaloThemeType get type => HaloThemeType.terminal;

  // ── Display — hero text, welcome screen titles ────────────────────────────

  @override
  TextStyle get displayLarge => GoogleFonts.jetBrainsMono(
        fontSize: 48,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.15,
        color: textPrimary,
      );

  @override
  TextStyle get displayMedium => GoogleFonts.jetBrainsMono(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.15,
        color: textPrimary,
      );

  // ── Headline — section titles, page headings ──────────────────────────────

  @override
  TextStyle get headlineLarge => GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.2,
        color: textPrimary,
      );

  @override
  TextStyle get headlineMedium => GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.2,
        color: textPrimary,
      );

  // ── Title — prominent labels, button text ────────────────────────────────

  @override
  TextStyle get titleLarge => GoogleFonts.ibmPlexSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.4,
        color: textPrimary,
      );

  @override
  TextStyle get titleMedium => GoogleFonts.ibmPlexSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: textPrimary,
      );

  // ── Body — main and secondary content ────────────────────────────────────

  @override
  TextStyle get bodyLarge => GoogleFonts.ibmPlexSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.4,
        color: textSecondary,
      );

  @override
  TextStyle get bodyMedium => GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.4,
        color: textSecondary,
      );

  // ── Label — uppercase tags, captions, URL bar, nav items ─────────────────

  @override
  TextStyle get labelLarge => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
        height: 1.2,
        color: textMuted,
      );

  @override
  TextStyle get labelSmall => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
        height: 1.2,
        color: textMuted,
      );

  // ── Ticker — prices, numbers, financial data (always monospace) ───────────

  @override
  TextStyle get ticker => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.3,
        color: textPrimary,
      );

  @override
  TextStyle get tickerLarge => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.3,
        color: textAccent,
      );

  // ─── Background color system (UI/UX Pro Max: financial dashboard dark + green) ─

  @override
  List<Color> get backgroundGradient => const [
        Color(0xFF0A2818), // rich dark emerald — clearly not black
        Color(0xFF071A10), // deep green anchor with strong hue
      ];

  @override
  List<Color> get blobColors => const [
        Color(0xFF059669), // emerald-600 — primary terminal green glow
        Color(0xFF065F46), // emerald-800 — deep green
        Color(0xFF134E4A), // teal-900 — cool teal variation
        Color(0xFF022C22), // near-black emerald anchor
      ];

  @override
  Color get glassOverlay => const Color(0xFF020617).withValues(alpha: 0.45);

  @override
  double get blobOpacity => 0.25;
}
