import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/OnboardingWidgets/FormWidget.dart';
import 'package:frontend/widgets/OnboardingWidgets/OnboardingProtocols.dart';
import 'package:frontend/widgets/OnboardingWidgets/WelcomeWidget.dart';
import 'package:frontend/widgets/background_gradient_animation.dart';
import 'package:frontend/widgets/commandButtons.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FormController {
  int currentIndex = -1;
  VoidCallback? onChanged;
  Platform? selectedBuyingPlatform;
  Platform? selectedChartingPlatform;

  void setSelectedBuyingPlatform(Platform platform) {
    selectedBuyingPlatform = platform;
  }

  void setBuyingPlatformAuthState(bool state) {
    if(selectedBuyingPlatform == null) return;

    selectedBuyingPlatform!.authenticated = state;
    onChanged!.call();
  }

  void setChartingPlatformAuthState(bool state) {
    if(selectedChartingPlatform == null) return;

    selectedChartingPlatform!.authenticated = state;
    onChanged!.call();
  }

  void setSelectedChartingPlatform(Platform platform) {
    selectedChartingPlatform = platform;
  }
  
  void next() {
    currentIndex++;
    onChanged?.call();
  }

  bool nextAvailable() {
    List<bool> params = [
      selectedBuyingPlatform != null,
      selectedBuyingPlatform!.authenticated,
      selectedChartingPlatform != null,
      selectedChartingPlatform!.authenticated, 
    ];

    return params[currentIndex];
  }

  void back() {
    currentIndex--;
    onChanged?.call();
  }
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool showWelcome = true;
  bool loadWebView = false;
  FormController formController = FormController();
  WebViewController? controller;

  void initState() {
    super.initState();
    formController.onChanged = () {
      setState(() {});
    };
  }

  void launchAuthWebView (WebViewController authController) {
    setState(() {
      controller = authController;
    });
  }

  void getReady() {
    setState(() {
      loadWebView = true;
    });
  }

  void authSuccesfull() {
    loadWebView = false;
    controller = null;
    
    if(formController.currentIndex == 1) {
      formController.setBuyingPlatformAuthState(true);
    } else {
      formController.setChartingPlatformAuthState(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);

    return Container(
      decoration: BoxDecoration(color: theme.backgroundColor),
      width: double.infinity,
      child: BackgroundGradientAnimation(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  CommandButtons(), 
                  Expanded(
                    child: controller != null ? Container(
                      height: double.infinity, 
                      width: double.infinity,
                      color: theme.backgroundColor,
                      margin: EdgeInsets.only(top: 15),
                      child: Stack(
                        children: [
                          !loadWebView ? Center(
                            child: CircularProgressIndicator(color: theme.whiteColor,),
                          ) : Container(),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedOpacity(
                              opacity: loadWebView ? 1 : 0, 
                              duration: Duration(milliseconds: 250),
                              child: WebViewWidget(controller: controller!)
                            )
                          ), 
                          Positioned(
                            top: 15,
                            left: 15,
                            child: AnimatedOpacity(
                              opacity: loadWebView ? 1 : 0,
                              duration: const Duration(milliseconds: 250),
                              child: _WebViewCloseButton(
                                theme: theme,
                                onTap: () => setState(() {
                                  controller = null;
                                  loadWebView = false;
                                }),
                              ),
                            ),
                          )
                        ],
                      ),
                    ) : 
                      formController.currentIndex == -1 ? 
                        Welcomewidget(formController: formController) :
                        FormWidget(formController: formController, launchAuth: launchAuthWebView, launchLoad: getReady, exitAuth: authSuccesfull )
                  )
                ],
              ),
            ),
          ]
        )
      )
    );
  }
}

class _WebViewCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  final HaloThemeData theme;
  const _WebViewCloseButton({required this.onTap, required this.theme});

  @override
  State<_WebViewCloseButton> createState() => _WebViewCloseButtonState();
}

class _WebViewCloseButtonState extends State<_WebViewCloseButton> {
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
          scale: _pressed ? 0.92 : _hovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedRotation(
            turns: _hovered ? -0.02 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                children: [
                  // Glassmorphic base with accent fill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: CustomColors.darkPurple.withValues(alpha: _hovered ? 1.0 : 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.theme.whiteColor.withValues(alpha: 0.18),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CustomColors.darkPurple.withValues(alpha: _hovered ? 0.45 : 0.25),
                              blurRadius: _hovered ? 22 : 14,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: widget.theme.whiteColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Inner highlight (top-left frost sheen)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.55],
                        ),
                      ),
                    ),
                  ),
                  // X icon
                  Center(
                    child: FaIcon(
                      FontAwesomeIcons.x,
                      size: 13,
                      color: widget.theme.whiteColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}