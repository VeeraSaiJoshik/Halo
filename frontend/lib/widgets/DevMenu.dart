import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/ai/verdict.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/widgets/NotificationWidget.dart';
import '../main.dart';
import '../services/logout_service.dart';
import '../themes/halo_theme.dart';
import '../themes/theme_provider.dart';

Verdict _sampleVerdict() => Verdict(
      direction: 'bullish',
      confidence: 8,
      entry: const EntryPlan(
        type: 'limit',
        price: 184.20,
        zoneLower: 183.40,
        zoneUpper: 185.10,
      ),
      invalidation: 181.50,
      target: 192.80,
      thesis:
          'NVDA reclaimed the 50-day moving average on rising volume after a clean retest of the prior breakout shelf. Relative strength versus SPY is making new highs, options flow skewed call-side, and the 4H stochastic just crossed up from oversold. Bias remains long while price holds above 182.',
      keyRisks: const [
        'CPI print Thursday could spike rates and compress multiples',
        'Gap-fill back to 180.20 would invalidate the breakout structure',
        'Sector rotation out of semis if AI-spend narrative cools',
      ],
      generatedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      modelId: 'llama-3.2-3b-q4',
      cached: false,
    );

class DevMenu extends ConsumerWidget {
  final VoidCallback onClose;
  const DevMenu({required this.onClose, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentType = ref.watch(haloThemeTypeProvider);
    final theme = ref.watch(haloThemeProvider);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: theme.whiteColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.whiteColor.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'DESIGN LANGUAGE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                              color: theme.whiteColor.withOpacity(0.54),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.whiteColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: theme.whiteColor.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              '⌘ D',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.whiteColor.withOpacity(0.38),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const SizedBox(height: 8),
                      _PreviewVerdictButton(
                        onTap: () {
                          onClose();
                          NotificationWidget.show(
                            context,
                            verdict: _sampleVerdict(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _LogoutButton(
                        onTap: () async {
                          final settings = ref.read(settingsProvider);
                          onClose();
                          await logoutAndReset(context, settings);
                        },
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Press Esc or ⌘D to close',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.whiteColor.withOpacity(0.24),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends ConsumerStatefulWidget {
  final HaloThemeType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  ConsumerState<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends ConsumerState<_ThemeCard> {
  bool _hovering = false;

  Color get _accent {
    switch (widget.type) {
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

  String get _fontPreview {
    switch (widget.type) {
      case HaloThemeType.golden:
      case HaloThemeType.blue:
      case HaloThemeType.green:
      case HaloThemeType.pink:
      case HaloThemeType.red:
        return 'Instrument Serif · Playfair · Inter · JetBrains';
      case HaloThemeType.terminal:
        return 'JetBrains Mono · IBM Plex Sans';
      case HaloThemeType.meridian:
        return 'Space Grotesk · DM Sans · Fira Code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? _accent.withOpacity(0.1)
                  : _hovering
                      ? theme.whiteColor.withOpacity(0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isSelected
                    ? _accent.withOpacity(0.45)
                    : theme.whiteColor.withOpacity(widget.isSelected ? 0.15 : 0.07),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.isSelected ? _accent : theme.whiteColor.withOpacity(0.24),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.type.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected
                              ? theme.whiteColor
                              : theme.whiteColor.withOpacity(0.70),
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.type.tagline,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: widget.isSelected
                              ? _accent.withOpacity(0.8)
                              : theme.whiteColor.withOpacity(0.38),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fontPreview,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: theme.whiteColor.withOpacity(0.24),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isSelected)
                  Icon(Icons.check_rounded, color: _accent, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewVerdictButton extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  const _PreviewVerdictButton({required this.onTap});

  @override
  ConsumerState<_PreviewVerdictButton> createState() =>
      _PreviewVerdictButtonState();
}

class _PreviewVerdictButtonState extends ConsumerState<_PreviewVerdictButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    final accent = theme.accentColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: _hovering
                ? accent.withOpacity(0.12)
                : accent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withOpacity(_hovering ? 0.45 : 0.22),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: accent, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview verdict notification',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.whiteColor.withOpacity(0.85),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Opens the modal with sample dummy data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: accent.withOpacity(0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  ConsumerState<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends ConsumerState<_LogoutButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    const accent = Color(0xFFF87171);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: _hovering ? accent.withOpacity(0.12) : accent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withOpacity(_hovering ? 0.45 : 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: accent, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.whiteColor.withOpacity(0.85),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Clears cookies and local settings',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: accent.withOpacity(0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
