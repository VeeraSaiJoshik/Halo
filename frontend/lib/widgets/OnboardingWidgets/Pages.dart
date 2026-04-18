import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/OnboardingPage.dart';
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

class PlatformAuthPage extends StatefulWidget {
  final Platform authPlatform;
  const PlatformAuthPage({super.key, required this.authPlatform});

  @override
  State<PlatformAuthPage> createState() => _PlatformAuthPageState();
}

class _PlatformAuthPageState extends State<PlatformAuthPage> {
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
              'Sign in to ${widget.authPlatform.id}',
              style: theme.headlineMedium,
            );
          },
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(haloThemeProvider);
            return Text(
              'Choose how you\'d like to authenticate',
              style: theme.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8)),
            );
          },
        ),
        const SizedBox(height: 48),
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: widget.authPlatform.authMethods.map((method) {
            return _AuthMethodButton(
              method: method,
              brandColor: widget.authPlatform.brandColor,
              onTap: () => setState(() {
                _selected = method.authName;
                method.launchSignupMethod();
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AuthMethodButton extends StatefulWidget {
  final AuthMethods method;
  final Color brandColor;
  final VoidCallback onTap;

  const _AuthMethodButton({
    required this.method,
    required this.brandColor,
    required this.onTap,
  });

  @override
  State<_AuthMethodButton> createState() => _AuthMethodButtonState();
}

class _AuthMethodButtonState extends State<_AuthMethodButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 280,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _hovered
                    ? Colors.white.withOpacity(0.16)
                    : Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.06),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              SizedBox(width: 18, height: 18, child: FittedBox(child: widget.method.authLogo)),
              Consumer(
                builder: (context, ref, _) {
                  final theme = ref.watch(haloThemeProvider);
                  return Text(
                    widget.method.authName,
                    style: theme.titleMedium.copyWith(color: Colors.white),
                  );
                },
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ─── Page 1: Buying portal ─────────────────────────────────────────────────

class BuyingPortalPage extends StatefulWidget {
  FormController formController;
  BuyingPortalPage({super.key, required this.formController});

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
              style: theme.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8)),
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
                onTap: () => setState(() {
                  widget.formController.setSelectedBuyingPlatform(p);
                  _selected = p.id;
                }),
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
  FormController formController;
  ChartingPlatformPage({super.key, required this.formController});

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
              style: theme.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8)),
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
                onTap: () => setState(() {
                  widget.formController.setSelectedChartingPlatform(p);
                  _selected = p.id;
                }),
              );
              return btn;
            }),
          ],
        ),
      ],
    );
  }
}
