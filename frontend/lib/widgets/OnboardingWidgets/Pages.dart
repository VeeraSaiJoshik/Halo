import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/pages/OnboardingPage.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/Buttons/plushyButton.dart';
import 'package:frontend/widgets/OnboardingWidgets/OnboardingProtocols.dart';
import 'package:webview_flutter/webview_flutter.dart';


class PlatformAuthPage extends StatefulWidget {
  final Platform authPlatform;
  Function launchAuthWebView;
  PlatformAuthPage({super.key, required this.authPlatform, required this.launchAuthWebView});

  @override
  State<PlatformAuthPage> createState() => _PlatformAuthPageState();
}

class _PlatformAuthPageState extends State<PlatformAuthPage> {
  void _handleAuthTap(AuthMethods method) {
    if (method is GoogleAuth) {
      method.launchSignupMethod(null);
      return;
    }

    method.launchSignupMethod((controller) {
      if (!mounted) return;
      widget.launchAuthWebView(controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 100,
          width: 100,
          child: Image.asset(
           widget.authPlatform.logoUrl,
           fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 15,),
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
              brandColor: Colors.transparent,
              selected: false,
              onTap: () => _handleAuthTap(method),
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
  final bool selected;
  final VoidCallback onTap;

  const _AuthMethodButton({
    required this.method,
    required this.brandColor,
    required this.selected,
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
        child: AnimatedRotation(
          turns: _hovered ? 0.004 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedScale(
          scale: _pressed ? 1.06 : _hovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 280,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: widget.brandColor.withOpacity(widget.selected ? 0.45 : _hovered ? 0.25 : 0.12),
                  blurRadius: widget.selected ? 28 : _hovered ? 20 : 10,
                  spreadRadius: widget.selected ? 1 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.selected
                          ? widget.brandColor.withOpacity(0.85)
                          : Colors.white.withOpacity(_hovered ? 0.40 : 0.24),
                      width: widget.selected ? 1.5 : 1.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.selected
                          ? [
                              widget.brandColor.withOpacity(0.32),
                              widget.brandColor.withOpacity(0.10),
                              Colors.white.withOpacity(0.04),
                            ]
                          : [
                              Colors.white.withOpacity(_hovered ? 0.22 : 0.14),
                              Colors.white.withOpacity(0.04),
                            ],
                    ),
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
             
              return PlushyButton(
                glowColor: p.brandColor,
                padding: const EdgeInsets.all(22),
                reverse: flip,
                onPressed: () => setState(() {
                  widget.formController.setSelectedBuyingPlatform(p);
                }),
                selected: widget.formController.selectedBuyingPlatform != null && widget.formController.selectedBuyingPlatform!.id == p.id,
                child: Image.asset(
                  p.logoUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              );
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
             
              return PlushyButton(
                glowColor: p.brandColor,
                padding: const EdgeInsets.all(22),
                reverse: flip,
                onPressed: () => setState(() {
                  widget.formController.setSelectedChartingPlatform(p);
                }),
                selected: widget.formController.selectedChartingPlatform != null && widget.formController.selectedChartingPlatform!.id == p.id,
                child: Image.asset(
                  p.logoUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}