import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/widgets/OnboardingWidgets/FormWidget.dart';
import 'package:frontend/widgets/OnboardingWidgets/OnboardingProtocols.dart';
import 'package:frontend/widgets/OnboardingWidgets/WelcomeWidget.dart';
import 'package:frontend/widgets/OverlayWidgets/TopNavModal.dart';
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

  void setSelectedChartingPlatform(Platform platform) {
    selectedChartingPlatform = platform;
  }
  
  void next() {
    currentIndex++;
    onChanged?.call();
  }

  void back() {
    currentIndex--;
    onChanged?.call();
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool showWelcome = true;
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
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:const Color(0xFF0D0818)
      ),
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
                      margin: EdgeInsets.only(top: 15),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: WebViewWidget(controller: controller!)
                          ), 
                          Positioned(
                            top: 15,
                            left: 15,
                            child: NavButton(icon: FontAwesomeIcons.x, width: 45, height: 45, isAccented: true ,onTap: () => setState(() {
                              controller = null;
                            }))
                          )
                        ],
                      ),
                    ) : 
                      formController.currentIndex == -1 ? 
                        Welcomewidget(formController: formController) :
                        FormWidget(formController: formController, launchAuth: launchAuthWebView)
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