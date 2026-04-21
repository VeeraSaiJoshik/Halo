import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'halo_theme.dart';

/// Aurum — Editorial Luxury theme.
///
/// Playfair Display serifs for display/headline tokens,
/// Inter for all functional text (title/body/label),
/// JetBrains Mono exclusively for financial ticker data.
class AurumTheme implements HaloThemeData {
  const AurumTheme();

  // ─── Semantic text colors ─────────────────────────────────────────────────

  @override
  Color get textPrimary => const Color(0xFFF8FAFC);

  @override
  Color get textSecondary => const Color(0xFF94A3B8);

  @override
  Color get textMuted => const Color(0xFF475569);

  @override
  Color get textAccent => const Color(0xFFF59E0B); // Gold

  // ─── Theme identity ───────────────────────────────────────────────────────

  @override
  HaloThemeType get type => HaloThemeType.aurum;

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
  // UI/UX Pro Max sources:
  //   • Liquid Glass style — "vibrant iridescent, translucent base, opacity shifts"
  //   • Aurora UI style — blend-mode: screen, color-saturation: 1.2 for luminous glow
  //   • Color domain: amber-500 #F59E0B (luxury primary), amber-400 #FBBF24 (highlight)
  //   • Glassmorphism spec: translucent overlay 10–30% so vibrant background shows through

  @override
  List<Color> get backgroundGradient => const [
        Color(0xFF3D1500), // rich dark amber-brown — clearly not black
        Color(0xFF210A00), // deep warm anchor with strong hue
      ];

  @override
  List<Color> get blobColors => const [
    Color(0xFFF59E0B), // amber-500  — bright gold  (UI/UX Pro Max luxury primary)
    Color(0xFFF97316), // orange-500 — vivid orange (warm spectrum expansion)
    Color(0xFFEAB308), // yellow-500 — bright yellow highlight
    Color(0xFFD97706), // amber-600  — rich amber anchor
    Color(0xFFFBBF24), // amber-400  — light gold shimmer
    Color(0xFFEA580C), // orange-600 — deep orange depth
  ];

  // Overlay drops to 0.48 — Liquid Glass / Glassmorphism require a light translucent
  // layer so the vibrant blobs bleed through and become the visual centerpiece.
  @override
  Color get glassOverlay => const Color(0xFF0A0400).withValues(alpha: 0.48);

  // 0.50 blob opacity — Liquid Glass "vibrant iridescent" centerpiece mode.
  // Higher than the atmospheric 0.08–0.12 used for subtle hints; here color IS the design.
  @override
  double get blobOpacity => 0.50;

  @override
  Color get accentColor => Color.fromARGB(255, 242, 163, 64);

  @override 
  Color get whiteColor => Color.fromARGB(255, 244, 233, 216);
}
