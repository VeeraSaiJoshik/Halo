import 'package:flutter/material.dart';
import 'package:frontend/widgets/OnboardingWidgets/WelcomeWidget.dart';
import 'package:frontend/widgets/background_gradient_animation.dart';
import 'package:frontend/widgets/commandButtons.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:const Color(0xFF0D0818)
      ),
      width: double.infinity,
      child: BackgroundGradientAnimation(
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                CommandButtons(), 
                Expanded(child: Welcomewidget())
              ],
            ),
          ),
        )
      )
    );
  }
}