import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'halo_theme.dart';

/// Meridian — Clean Swiss typography theme.
///
/// Space Grotesk geometric headlines with tight negative tracking,
/// DM Sans for legible UI text, Fira Code for financial data.
/// Maximum clarity, Swiss grid precision, premium minimal.
class MeridianTheme implements HaloThemeData {
  const MeridianTheme();

  // ---------------------------------------------------------------------------
  // Semantic text colors
  // ---------------------------------------------------------------------------

  @override
  Color get textPrimary => const Color(0xFFF1F5F9);

  @override
  Color get textSecondary => const Color.fromARGB(255, 184, 176, 148);

  @override
  Color get textMuted => const Color(0xFF475569);

  @override
  Color get textAccent => const Color(0xFF3B82F6);

  // ---------------------------------------------------------------------------
  // Theme identity
  // ---------------------------------------------------------------------------

  @override
  HaloThemeType get type => HaloThemeType.meridian;

  // ---------------------------------------------------------------------------
  // Display — hero text, welcome screen titles
  // ---------------------------------------------------------------------------

  @override
  TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
        fontSize: 52,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.05,
        color: textPrimary,
      );

  @override
  TextStyle get displayMedium => GoogleFonts.archivoBlack(
        fontSize: 40,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.0,
        height: 1.1,
        color: textPrimary,
      );

  // ---------------------------------------------------------------------------
  // Headline — section titles, page headings
  // ---------------------------------------------------------------------------

  @override
  TextStyle get headlineLarge => GoogleFonts.spaceGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.15,
        color: textPrimary,
      );

  @override
  TextStyle get headlineMedium => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.2,
        color: textPrimary,
      );

  // ---------------------------------------------------------------------------
  // Title — prominent labels, button text
  // ---------------------------------------------------------------------------

  @override
  TextStyle get titleLarge => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: textPrimary,
      );

  @override
  TextStyle get titleMedium => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.4,
        color: textPrimary,
      );

  // ---------------------------------------------------------------------------
  // Body — main and secondary content
  // ---------------------------------------------------------------------------

  @override
  TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.55,
        color: textSecondary,
      );

  @override
  TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.55,
        color: textSecondary,
      );

  // ---------------------------------------------------------------------------
  // Label — uppercase tags, captions, URL bar, nav items
  // ---------------------------------------------------------------------------

  @override
  TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.3,
        color: textMuted,
      );

  @override
  TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
        color: textMuted,
      );

  // ---------------------------------------------------------------------------
  // Ticker — prices, numbers, financial data (always monospace)
  // ---------------------------------------------------------------------------

  @override
  TextStyle get ticker => GoogleFonts.firaCode(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.3,
        color: textPrimary,
      );

  @override
  TextStyle get tickerLarge => GoogleFonts.firaCode(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.3,
        color: textAccent,
      );

  // ─── Background color system (UI/UX Pro Max: banking/finance navy + blue precision) ─

  @override
  List<Color> get backgroundGradient => [
        Colors.amber.shade700,//Color(0xFF0D1F4A), // rich deep navy — clearly not black
        Colors.amber.shade900, // deep indigo anchor with strong hue
      ];

  @override
  List<Color> get blobColors => const [
        Color(0xFF2563EB), // blue-600 — Swiss precision blue glow
        Color(0xFF1E40AF), // blue-800 — deep blue
        Color(0xFF1E3A8A), // blue-900 — dark navy
        Color(0xFF0C1844), // near-black indigo anchor
      ];

  @override
  Color get glassOverlay => const Color(0xFF020617).withValues(alpha: 0.45);

  @override
  double get blobOpacity => 0.25;

  @override
  Color get accentColor => Color.fromARGB(255, 242, 163, 64);

  @override 
  Color get whiteColor => Color.fromARGB(255, 244, 233, 216);
}
