import 'package:flutter/material.dart';
import 'package:frontend/widgets/Buttons/plushyButton.dart';
import 'package:frontend/widgets/OnboardingWidgets/OnboardingProtocols.dart';
// ─── Data ──────────────────────────────────────────────────────────────────

class _LogoButton extends StatelessWidget {
  final Platform platform;
  final bool selected;
  final VoidCallback onTap;

  const _LogoButton({
    required this.platform,
    required this.selected,
    required this.onTap,
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
        onPressed: onTap,
        child: Image.asset(
          platform.logoUrl,
          width: 110,
          height: 110,
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
        Text(
          'Where do you trade?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your buying platform',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
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
                onTap: () => setState(() => _selected = p.id),
              );
              return flip ? Transform.scale(scaleX: -1, child: btn) : btn;
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
        Text(
          'Where do you chart?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your charting platform',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
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
                onTap: () => setState(() => _selected = p.id),
              );
              return flip ? Transform.scale(scaleX: -1, child: btn) : btn;
            }),
          ],
        ),
      ],
    );
  }
}
