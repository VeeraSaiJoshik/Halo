import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/Buttons/plushyButton.dart';
import 'package:frontend/widgets/OnboardingWidgets/OnboardingProtocols.dart';
// ─── Data ──────────────────────────────────────────────────────────────────

class _LogoButton extends StatelessWidget {
  final Platform platform;
  final bool selected;
  final VoidCallback onTap;
  final bool reverse;

  const _LogoButton({
    required this.platform,
    required this.selected,
    required this.onTap,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: platform.brandColor.withOpacity(0.5),
                  blurRadius: 28,
                  spreadRadius: 5,
                ),
              ]
            : [],
      ),
      child: PlushyButton(
        glowColor: platform.brandColor,
        padding: const EdgeInsets.all(22),
        reverse: reverse,
        onPressed: onTap,
        child: Image.asset(
          platform.logoUrl,
          width: 90,
          height: 90,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─── Page 1: Buying portal ─────────────────────────────────────────────────

class BuyingPortalPage extends StatefulWidget {
  const BuyingPortalPage({super.key});

  @override
  State<BuyingPortalPage> createState() => _BuyingPortalPageState();
}

class _BuyingPortalPageState extends State<BuyingPortalPage> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(haloThemeProvider);
            return Text(
              'Where do you trade?',
              style: theme.headlineMedium,
            );
          },
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(haloThemeProvider);
            return Text(
              'Select your buying platform',
              style: theme.bodyMedium,
            );
          },
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            ...buyingPlatforms.asMap().entries.map((e) {
              final p = e.value;
              final flip = e.key < buyingPlatforms.length ~/ 2;
              final btn = _LogoButton(
                platform: p,
                selected: _selected == p.id,
                reverse: flip,
                onTap: () => setState(() => _selected = p.id),
              );
              return btn;
            }),
          ],
        ),
      ],
    );
  }
}

// ─── Page 2: Charting platform ─────────────────────────────────────────────

class ChartingPlatformPage extends StatefulWidget {
  const ChartingPlatformPage({super.key});

  @override
  State<ChartingPlatformPage> createState() => _ChartingPlatformPageState();
}

class _ChartingPlatformPageState extends State<ChartingPlatformPage> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(haloThemeProvider);
            return Text(
              'Where do you chart?',
              style: theme.headlineMedium,
            );
          },
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(haloThemeProvider);
            return Text(
              'Select your charting platform',
              style: theme.bodyMedium,
            );
          },
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            ...chartingPlatforms.asMap().entries.map((e) {
              final p = e.value;
              final flip = e.key < chartingPlatforms.length ~/ 2;
              final btn = _LogoButton(
                platform: p,
                selected: _selected == p.id,
                reverse: flip,
                onTap: () => setState(() => _selected = p.id),
              );
              return btn;
            }),
          ],
        ),
      ],
    );
  }
}
