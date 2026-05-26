import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/controllers/WebViewController.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/transitions.dart';
import 'package:frontend/models/providerModels.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/services/app_event_bus.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/OnboardingWidgets/AuthWebView.dart';
import 'package:frontend/widgets/OnboardingWidgets/FormWidget.dart';
import 'package:frontend/widgets/OnboardingWidgets/OnboardingProtocols.dart';
import 'package:frontend/widgets/OnboardingWidgets/WelcomeWidget.dart';
import 'package:frontend/widgets/background_gradient_animation.dart';
import 'package:frontend/widgets/commandButtons.dart';
import 'package:path/path.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FormController {
  int currentIndex = -1;
  int finalIndex = 5;
  late VoidCallback onChanged;
  late Function finishOnboarding;
  Platform? selectedBuyingPlatform;
  Platform? selectedChartingPlatform;
  bool debugging = false;

  void setSelectedBuyingPlatform(Platform platform) {
    selectedBuyingPlatform = platform;
  }

  void setAuthState(AuthState state) {
    if(currentIndex == 2) {
      selectedBuyingPlatform!.authenticated = state;
    } else {
      selectedChartingPlatform!.authenticated = state;
    }
  }


  void setSelectedChartingPlatform(Platform platform) {
    selectedChartingPlatform = platform;
  }
  
  void next(BuildContext context) async {
    if(debugging && currentIndex > 0){
      if(currentIndex == 2) selectedBuyingPlatform?.authenticated = AuthState.authenticated;
      if(currentIndex == 3) selectedChartingPlatform?.authenticated = AuthState.authenticated;
      currentIndex++;
    }
    currentIndex++;

    if(currentIndex == finalIndex) {
      await finishOnboarding.call(context);
    } else {
      onChanged.call();
    }
  }

  bool nextAvailable() {
    switch (currentIndex) {
      case 0: return true;
      case 1: return selectedBuyingPlatform != null;
      case 2: return selectedBuyingPlatform?.authenticated == AuthState.authenticated;
      case 3: return selectedChartingPlatform != null;
      case 4: return selectedChartingPlatform?.authenticated == AuthState.authenticated;
      default: return false;
    }
  }

  void back() {
    currentIndex--;
    onChanged.call();
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
  bool debugMode = true;
  WebBundle? controller;
  FormController formController = FormController();

  Future<bool> finishOnboarding(BuildContext context) async {
    bool passed = await ref.read(settingsProvider).saveFormControllerData(formController, ref.read(haloThemeTypeProvider));
    print("auth passed: ${passed}");
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
    Navigator.of(context).push(createCustomRoute(HomePage()));

    return true;
  }

  bool _onKeyPressed(KeyEvent event) {
    if (event is! KeyUpEvent) {
      return true;
    }

    final meta = HardwareKeyboard.instance.isMetaPressed;
    final key = event.logicalKey;

    if(meta && key == LogicalKeyboardKey.keyS){
      setState(() {
        if(formController.currentIndex == -1) formController.debugging = !formController.debugging;
      });
    }

    return true;
  }

  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyPressed);
    
    formController.onChanged = () {
      setState(() {});
    };
    formController.finishOnboarding = finishOnboarding;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyPressed);

    super.dispose();
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

  void exitFunction() {
    loadWebView = false;
    controller = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(haloThemeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: theme.backgroundColor),
        width: double.infinity,
        child: BackgroundGradientAnimation(
          child: Stack(
            children: [
              Positioned(
                top: 10, 
                right: 10,
                child: AnimatedOpacity(
                  opacity: formController.debugging ? 1 : 0, 
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 5,
                      children: [
                        FaIcon(FontAwesomeIcons.bug, size: theme.titleMedium.fontSize, color: theme.titleMedium.color,),
                        Text(
                          "Debug Mode", 
                          style: theme.bodyMedium.copyWith(color: theme.titleLarge.color, height: 0),
                        )
                      ],
                    ),
                  ),
                )
              ),
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
                        exit: exitFunction
                      )
                    )
                  ],
                ),
              ),
            ]
          )
        )
      ),
    );
  }
}