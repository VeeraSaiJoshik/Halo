import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/createWebViewController.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/OnboardingWidgets/AuthWebView.dart';
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
    switch (currentIndex) {
      case 0: return true;
      case 1: return selectedBuyingPlatform != null;
      case 2: return selectedBuyingPlatform?.authenticated ?? false;
      case 3: return selectedChartingPlatform != null;
      case 4: return selectedChartingPlatform?.authenticated ?? false;
      default: return false;
    }
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
  WebBundle? controller;

  void initState() {
    super.initState();
    formController.onChanged = () {
      setState(() {});
    };
  }

  void launchAuthWebView (WebBundle authController) {
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

    print("Auth was succesfull ${formController.currentIndex}");

    if(formController.currentIndex == 2) {
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
                    child: controller != null ? AuthWebView(
                      closeFunction: () => setState(() {
                        controller = null;
                        loadWebView = false;
                      }),
                      controller: controller, 
                      loadWebView: loadWebView, 
                      theme: theme, 
                    ) : formController.currentIndex == -1 ? 
                    Welcomewidget(formController: formController) :
                    FormWidget(
                      formController: formController, 
                      launchAuth: launchAuthWebView, 
                      launchLoad: getReady, 
                      exitAuth: authSuccesfull
                    )
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