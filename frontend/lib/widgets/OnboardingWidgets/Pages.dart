import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controllers/WebViewController.dart';
import 'package:frontend/pages/OnboardingPage.dart';
import 'package:frontend/services/cookie_manager.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/Buttons/plushyButton.dart';
import 'package:frontend/widgets/OnboardingWidgets/OnboardingProtocols.dart';

class PlatformAuthPage extends ConsumerStatefulWidget {
  final Platform authPlatform;
  Function launchAuthWebView;
  void Function() getReady;
  FormController controller;
  Function exit;
  PlatformAuthPage({
    super.key,
    required this.controller,
    required this.authPlatform,
    required this.launchAuthWebView,
    required this.getReady,
    required this.exit
  });

  @override
  ConsumerState<PlatformAuthPage> createState() => _PlatformAuthPageState();
}

enum RedirectStatus {
  idle, 
  acquiring_link, 
  redirecting, 
  post_processing
}

class _PlatformAuthPageState extends ConsumerState<PlatformAuthPage> {
  RedirectStatus redirectingToGoogle = RedirectStatus.idle;
  
  void _handleAuthTap(AuthMethods method) async {
    List<String> links = [];

    if (widget.controller.currentIndex == 2) {
      links = widget.controller.selectedBuyingPlatform!.links;
    } else if (widget.controller.currentIndex == 4) {
      links = widget.controller.selectedChartingPlatform!.links;
    }

    if (links.isNotEmpty) {
      final uniqueDomains = links
          .map((l) => Uri.parse(l).host)
          .map((h) {
            final parts = h.split('.');
            return parts.length > 2
                ? '${parts[parts.length - 2]}.${parts[parts.length - 1]}'
                : h;
          })
          .toSet();

      for (final domain in uniqueDomains) {
        await NativeCookieManager.deleteCookiesForDomain(domain);
      }
    }

    if(method.runtimeType == GoogleAuth) {
      setState(() {
        redirectingToGoogle = RedirectStatus.acquiring_link;
      });
      (method as GoogleAuth).launchGoogleAuthWebView(
        () => setState(() {redirectingToGoogle = RedirectStatus.redirecting;}),
        () => setState(() {redirectingToGoogle = RedirectStatus.post_processing;}),
        () => setState(() {redirectingToGoogle = RedirectStatus.idle;})
      );
    } else {
      method.launchSignupMethod((controller) {
        if (!mounted) return;
        widget.launchAuthWebView(controller);
      }, widget.getReady, () {
        widget.exit.call();

        widget.controller.setAuthState(AuthState.authenticated);
        widget.controller.onChanged?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    final authenticated = widget.authPlatform.authenticated;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo — gains a green ring when connected
        SizedBox(
          width: redirectingToGoogle != RedirectStatus.idle ? null : 100,
          height: redirectingToGoogle != RedirectStatus.idle ? 150 : 100,
          child: Image.asset(
            redirectingToGoogle != RedirectStatus.idle ? "assets/images/google_auth.png" : widget.authPlatform.logoUrl,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Sign in to ${widget.authPlatform.id}',
          style: theme.headlineMedium,
        ),
        const SizedBox(height: 8),
        // Swaps between subtitle and connected indicator
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child:  authenticated == AuthState.authenticated
              ? _ConnectedPill(key: const ValueKey('pill'), theme: theme, success: true,) : 
              authenticated == AuthState.failedAuthentication
              ? _ConnectedPill(key: const ValueKey('pill'), theme: theme, success: false,) : 
              authenticated == AuthState.checking ? Row(
                spacing: 5,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    key: const ValueKey('hint'),
                    'Verifying authentication',
                    style: theme.bodyMedium.copyWith(
                      color: theme.whiteColor.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                    width: 10,
                    child: CircularProgressIndicator(
                      color: theme.whiteColor.withValues(alpha: 0.6),
                      strokeWidth: 2,
                    ),    
                  ),
                ],
              ) : 
              redirectingToGoogle != RedirectStatus.idle ? Text(
                key: const ValueKey('redirect_hint'),
                redirectingToGoogle == RedirectStatus.acquiring_link ? 
                'Redirecting you to secure google auth' : 
                redirectingToGoogle == RedirectStatus.redirecting ? 
                "Continue google auth in native browser" : 
                "Injecting cookies",
                style: theme.bodyMedium.copyWith(
                  color: theme.whiteColor.withValues(alpha: 0.6),
                ),
              ) : 
              Text(
                key: const ValueKey('hint'),
                'Choose how you\'d like to authenticate',
                style: theme.bodyMedium.copyWith(
                  color: theme.whiteColor.withValues(alpha: 0.6),
                ),
              ),
        ),
        const SizedBox(height: 48),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 500), 
          child: redirectingToGoogle == RedirectStatus.idle ?
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
            ) : 
            Container()
        )
      ],
    );
  }
}

class _GoogleRedirectPlaceholder extends StatelessWidget {
  const _GoogleRedirectPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

const _kConnectedGreen = Color(0xFF22C55E);

class _ConnectedPill extends StatelessWidget {
  final HaloThemeData theme;
  final bool success;
  const _ConnectedPill({super.key, required this.theme, required this.success});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(
          success ? 'succesfully connected' : 'authentication failed, try again',
          style: theme.labelLarge.copyWith(color: success ? _kConnectedGreen : Colors.red),
        ),
      ],
    );
  }
}

class _AuthMethodButton extends ConsumerStatefulWidget {
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
  ConsumerState<_AuthMethodButton> createState() => _AuthMethodButtonState();
}

class _AuthMethodButtonState extends ConsumerState<_AuthMethodButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedRotation(
          turns: _hovered ? 0.004 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedScale(
            scale: _pressed
                ? 1.06
                : _hovered
                ? 1.03
                : 1.0,
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
                    color: widget.brandColor.withOpacity(
                      widget.selected
                          ? 0.45
                          : _hovered
                          ? 0.25
                          : 0.12,
                    ),
                    blurRadius: widget.selected
                        ? 28
                        : _hovered
                        ? 20
                        : 10,
                    spreadRadius: widget.selected ? 1 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.selected
                            ? widget.brandColor.withOpacity(0.85)
                            : theme.whiteColor.withOpacity(
                                _hovered ? 0.40 : 0.24,
                              ),
                        width: 1.5,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: theme.backgroundGradient,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 12,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: FittedBox(child: widget.method.authLogo),
                        ),
                        Text(
                          widget.method.authName,
                          style: theme.titleMedium.copyWith(
                            color: theme.whiteColor,
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
            return Text('Where do you trade?', style: theme.headlineMedium);
          },
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(haloThemeProvider);
            return Text(
              'Select your buying platform',
              style: theme.bodyMedium.copyWith(
                color: theme.whiteColor.withOpacity(0.8),
              ),
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
                  widget.formController.next();
                }),
                selected:
                    widget.formController.selectedBuyingPlatform != null &&
                    widget.formController.selectedBuyingPlatform!.id == p.id,
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
            return Text('Where do you chart?', style: theme.headlineMedium);
          },
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(haloThemeProvider);
            return Text(
              'Select your charting platform',
              style: theme.bodyMedium.copyWith(
                color: theme.whiteColor.withOpacity(0.8),
              ),
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
                  widget.formController.next();
                }),
                selected:
                    widget.formController.selectedChartingPlatform != null &&
                    widget.formController.selectedChartingPlatform!.id == p.id,
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

class ChooseThemePage extends ConsumerStatefulWidget {
  const ChooseThemePage({super.key});

  @override
  ConsumerState<ChooseThemePage> createState() => _ChooseThemePageState();
}

class _ChooseThemePageState extends ConsumerState<ChooseThemePage> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);
    double width = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Choose your vibe', style: theme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Select your charting platform',
          style: theme.bodyMedium.copyWith(
            color: theme.whiteColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          height: 90 + 44 + 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 150px card + 10px gap per item, minus one trailing gap
              final contentWidth = themes.length * 160.0 - 10.0;
              final needsScroll = contentWidth > constraints.maxWidth;

              final cards = Row(
                mainAxisSize: MainAxisSize.min,
                children: themes.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _ThemePreviewCard(
                      theme: t,
                      selected: t.type == ref.watch(haloThemeTypeProvider),
                      onTap: () =>
                          ref.read(haloThemeTypeProvider.notifier).state =
                              t.type,
                    ),
                  );
                }).toList(),
              );

              final padded = Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: cards,
              );

              return needsScroll
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: padded,
                    )
                  : Center(child: padded);
            },
          ),
        ),
      ],
    );
  }
}

class _ThemePreviewCard extends StatefulWidget {
  final HaloThemeData theme;
  final bool selected;
  final VoidCallback onTap;
  const _ThemePreviewCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });
  @override
  State<_ThemePreviewCard> createState() => _ThemePreviewCardState();
}

class _ThemePreviewCardState extends State<_ThemePreviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final blobs = t.blobColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedRotation(
          turns: _hovered ? -0.03 / (2 * 3.1415) : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedScale(
            scale: _hovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 90 + 44,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.selected
                      ? t.whiteColor.withValues(alpha: 0.85)
                      : t.whiteColor.withValues(alpha: _hovered ? 0.30 : 0.10),
                  width: widget.selected ? 1.5 : 1.0,
                ),
                boxShadow: widget.selected && blobs.isNotEmpty
                    ? [
                        BoxShadow(
                          color: blobs[0].withValues(alpha: 0.40),
                          blurRadius: 24,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Dark theme base
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: t.backgroundGradient,
                        ),
                      ),
                    ),
                    // 2a. Top-left blob
                    if (blobs.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1.2,
                            colors: [
                              blobs[0].withValues(alpha: 0.65),
                              blobs[0].withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    // 2b. Top-right blob
                    if (blobs.length > 1)
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topRight,
                            radius: 1.2,
                            colors: [
                              blobs[1].withValues(alpha: 0.55),
                              blobs[1].withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    if (widget.selected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: t.whiteColor.withValues(alpha: 0.90),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 11,
                            color: Colors.black,
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
    );
  }
}
